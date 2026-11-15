<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageSent;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Product;
use App\Models\User;
use App\Services\SupportBot;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ChatController extends Controller
{
    private const MAX_ATTACHMENT_BYTES = 5 * 1024 * 1024;

    public function index(Request $request): JsonResponse
    {
        $buyer = $request->user();

        $conversations = Conversation::query()
            ->where('buyer_id', $buyer->id)
            ->whereNotNull('seller_id')
            ->with(['seller.approvedSellerApplication', 'product', 'latestMessage.sender'])
            ->orderByDesc('last_message_at')
            ->orderByDesc('id')
            ->get();

        $unreadCounts = [];
        if ($conversations->isNotEmpty()) {
            $unreadCounts = Message::query()
                ->whereIn('conversation_id', $conversations->pluck('id'))
                ->whereNull('read_at')
                ->where(function ($q) use ($buyer) {
                    $q->where('sender_id', '!=', $buyer->id)
                        ->orWhereNull('sender_id');
                })
                ->selectRaw('conversation_id, COUNT(*) as unread_count')
                ->groupBy('conversation_id')
                ->pluck('unread_count', 'conversation_id')
                ->all();
        }

        $items = $conversations->map(function (Conversation $conversation) use ($buyer, $unreadCounts) {
            $unread = (int) ($unreadCounts[$conversation->id] ?? 0);

            return $this->transformConversation($conversation, $buyer, false, $unread);
        })->values();

        $supportUnread = 0;
        $supportSummary = null;
        $supportConversation = Conversation::query()
            ->where('user_id', $buyer->id)
            ->whereNull('buyer_id')
            ->whereNull('seller_id')
            ->with(['latestMessage.sender'])
            ->first();

        if ($supportConversation) {
            $supportUnread = (int) Message::query()
                ->where('conversation_id', $supportConversation->id)
                ->whereNull('read_at')
                ->where(function ($q) use ($buyer) {
                    $q->where('sender_id', '!=', $buyer->id)
                        ->orWhereNull('sender_id');
                })
                ->count();

            if ($supportConversation->latestMessage) {
                $supportSummary = $this->transformSupportConversation(
                    $supportConversation,
                    $buyer,
                    false,
                    $supportUnread
                );
            }
        }

        return response()->json([
            'conversations' => $items,
            'support_conversation' => $supportSummary,
            'total_unread' => array_sum($unreadCounts) + $supportUnread,
        ]);
    }

    public function start(Request $request): JsonResponse
    {
        $buyer = $request->user();

        $validated = $request->validate([
            'seller_id' => ['nullable', 'string', 'max:100'],
            'seller_name' => ['nullable', 'string', 'max:255'],
            'product_id' => ['nullable', 'integer', 'exists:products,id'],
            'message' => ['nullable', 'string', 'max:4000'],
            'body' => ['nullable', 'string', 'max:4000'],
            'attachment_data' => ['nullable', 'string'],
            'attachment_name' => ['nullable', 'string', 'max:255'],
        ]);

        $product = ! empty($validated['product_id'])
            ? Product::with('seller')->find((int) $validated['product_id'])
            : null;

        $seller = $this->resolveSeller(
            $validated['seller_id'] ?? null,
            $validated['seller_name'] ?? null,
            $product
        );

        if (! $seller) {
            return response()->json([
                'message' => 'Seller store could not be located.',
            ], 404);
        }

        if ((int) $seller->id === (int) $buyer->id) {
            return response()->json([
                'message' => 'You cannot message your own merchant store.',
            ], 422);
        }

        $query = Conversation::query()
            ->where('buyer_id', $buyer->id)
            ->where('seller_id', $seller->id);

        if ($product) {
            $conversation = (clone $query)->where('product_id', $product->id)->first()
                ?? (clone $query)->whereNull('product_id')->first();
        } else {
            $conversation = (clone $query)->orderByDesc('last_message_at')->orderByDesc('id')->first();
        }

        $created = false;
        if (! $conversation) {
            $conversation = Conversation::create([
                'user_id' => $buyer->id,
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'product_id' => $product?->id,
                'last_message_at' => now(),
            ]);
            $created = true;
        } elseif ($product && ! $conversation->product_id) {
            $conversation->update(['product_id' => $product->id]);
        }

        $initialText = trim((string) ($validated['message'] ?? $validated['body'] ?? ''));
        $attachment = $this->extractAttachment($request);
        if ($attachment === false) {
            return response()->json([
                'message' => 'Attachment must be a valid JPG, PNG, WEBP, or PDF file under 5 MB.',
            ], 422);
        }

        if ($initialText !== '' || $attachment !== null) {
            $this->createConversationMessage($conversation, $buyer, $initialText, $attachment);
        } else {
            $this->markIncomingRead($conversation, $buyer);
        }

        $conversation->load(['seller.approvedSellerApplication', 'product', 'messages.sender']);

        return response()->json([
            'conversation' => $this->transformConversation($conversation, $buyer, true, 0),
        ], $created ? 201 : 200);
    }

    public function show(Request $request, Conversation $conversation): JsonResponse
    {
        $buyer = $request->user();
        $this->authorizeBuyerConversation($conversation, $buyer);

        $this->markIncomingRead($conversation, $buyer);
        $conversation->load(['seller.approvedSellerApplication', 'product', 'messages.sender']);

        return response()->json([
            'conversation' => $this->transformConversation($conversation, $buyer, true, 0),
        ]);
    }

    public function store(Request $request, Conversation $conversation): JsonResponse
    {
        $buyer = $request->user();
        $this->authorizeBuyerConversation($conversation, $buyer);

        $validated = $request->validate([
            'message' => ['nullable', 'string', 'max:4000'],
            'body' => ['nullable', 'string', 'max:4000'],
            'attachment_data' => ['nullable', 'string'],
            'attachment_name' => ['nullable', 'string', 'max:255'],
        ]);

        $body = trim((string) ($validated['message'] ?? $validated['body'] ?? ''));
        $attachment = $this->extractAttachment($request);
        if ($attachment === false) {
            return response()->json([
                'message' => 'Attachment must be a valid JPG, PNG, WEBP, or PDF file under 5 MB.',
            ], 422);
        }

        if ($body === '' && $attachment === null) {
            return response()->json([
                'message' => 'Please enter a message or attach a file.',
            ], 422);
        }

        $message = $this->createConversationMessage($conversation, $buyer, $body, $attachment);
        $conversation->load(['seller.approvedSellerApplication', 'product']);

        return response()->json([
            'message_item' => $this->transformMessage($message, $conversation, $buyer),
            'conversation' => $this->transformConversation($conversation, $buyer, false, 0),
        ], 201);
    }

    public function markRead(Request $request, Conversation $conversation): JsonResponse
    {
        $buyer = $request->user();
        $this->authorizeBuyerConversation($conversation, $buyer);

        $this->markIncomingRead($conversation, $buyer);

        return response()->json([
            'status' => 'ok',
            'unread_count' => 0,
        ]);
    }

    public function supportShow(Request $request): JsonResponse
    {
        $buyer = $request->user();
        $conversation = $this->getOrCreateSupportConversation($buyer);

        $this->markIncomingRead($conversation, $buyer);
        $conversation->load(['messages.sender']);

        return response()->json([
            'conversation' => $this->transformSupportConversation($conversation, $buyer, true),
        ]);
    }

    public function supportSend(Request $request, SupportBot $bot): JsonResponse
    {
        $buyer = $request->user();
        $conversation = $this->getOrCreateSupportConversation($buyer);

        $validated = $request->validate([
            'message' => ['nullable', 'string', 'max:4000'],
            'body' => ['nullable', 'string', 'max:4000'],
            'attachment_data' => ['nullable', 'string'],
            'attachment_name' => ['nullable', 'string', 'max:255'],
        ]);

        $body = trim((string) ($validated['message'] ?? $validated['body'] ?? ''));
        $attachment = $this->extractAttachment($request);
        if ($attachment === false) {
            return response()->json([
                'message' => 'Attachment must be a valid JPG, PNG, WEBP, or PDF file under 5 MB.',
            ], 422);
        }

        if ($body === '' && $attachment === null) {
            return response()->json([
                'message' => 'Please enter a message or attach a file.',
            ], 422);
        }

        $userMessage = $this->createConversationMessage($conversation, $buyer, $body, $attachment);

        $botMessage = null;
        $isProductReport = str_starts_with($body, '[Product report]');
        $recentHumanAdmin = Message::query()
            ->where('conversation_id', $conversation->id)
            ->whereNotNull('sender_id')
            ->where('sender_id', '!=', $buyer->id)
            ->where('is_bot', false)
            ->where('created_at', '>=', now()->subMinutes(30))
            ->exists();

        if (! $isProductReport && ! $recentHumanAdmin && $bot->enabled()) {
            $botReplyText = trim($bot->reply($conversation));
            if ($botReplyText !== '') {
                $botMessage = Message::create([
                    'conversation_id' => $conversation->id,
                    'sender_id' => null,
                    'body' => $botReplyText,
                    'is_bot' => true,
                    'is_read' => true,
                    'read_at' => now(),
                ]);
                $conversation->update(['last_message_at' => now()]);
                $this->safeBroadcast($botMessage);
            }
        }

        $conversation->load(['messages.sender']);

        return response()->json([
            'message_item' => $this->transformMessage($userMessage, $conversation, $buyer),
            'bot_message' => $botMessage ? $this->transformMessage($botMessage, $conversation, $buyer) : null,
            'conversation' => $this->transformSupportConversation($conversation, $buyer, false),
        ], 201);
    }

    private function getOrCreateSupportConversation(User $buyer): Conversation
    {
        return Conversation::firstOrCreate(
            [
                'user_id' => $buyer->id,
                'buyer_id' => null,
                'seller_id' => null,
            ],
            [
                'last_message_at' => now(),
            ]
        );
    }

    private function authorizeBuyerConversation(Conversation $conversation, User $buyer): void
    {
        if ((int) $conversation->buyer_id !== (int) $buyer->id || ! $conversation->seller_id) {
            abort(403, 'You are not authorized to access this conversation.');
        }
    }

    private function resolveSeller(?string $sellerId, ?string $sellerName, ?Product $product): ?User
    {
        if ($product && $product->seller) {
            return $product->seller;
        }

        if ($sellerId !== null && $sellerId !== '' && ctype_digit($sellerId)) {
            $byId = User::find((int) $sellerId);
            if ($byId) {
                return $byId;
            }
        }

        $candidateName = trim((string) $sellerName);
        if ($candidateName === '' && $sellerId !== null && str_starts_with($sellerId, 'seller_')) {
            $candidateName = trim(str_replace('_', ' ', substr($sellerId, 7)));
        }

        if ($candidateName === '') {
            return null;
        }

        $lower = Str::lower($candidateName);

        return User::query()
            ->where(function ($q) use ($lower) {
                $q->whereRaw('LOWER(shop_name) = ?', [$lower])
                    ->orWhereRaw('LOWER(name) = ?', [$lower])
                    ->orWhereHas('approvedSellerApplication', function ($sq) use ($lower) {
                        $sq->whereRaw('LOWER(business_name) = ?', [$lower]);
                    });
            })
            ->orderByRaw("CASE WHEN role = 'seller' THEN 0 ELSE 1 END")
            ->orderBy('id')
            ->first();
    }

    /**
     * @return array{path:string,name:string,mime:string}|null|false
     */
    private function extractAttachment(Request $request): array|null|false
    {
        $rawBytes = null;
        $mimeType = 'image/jpeg';
        $extension = 'jpg';
        $originalName = trim((string) $request->input('attachment_name', ''));

        if ($file = $request->file('attachment')) {
            $size = (int) $file->getSize();
            if ($size <= 0 || $size > self::MAX_ATTACHMENT_BYTES) {
                return false;
            }
            $mimeType = strtolower((string) ($file->getMimeType() ?: 'image/jpeg'));
            $extension = match (strtolower((string) $file->getClientOriginalExtension())) {
                'png' => 'png',
                'webp' => 'webp',
                'pdf' => 'pdf',
                'jpg', 'jpeg' => 'jpg',
                default => '',
            };
            if ($extension === '') {
                return false;
            }
            $rawBytes = file_get_contents($file->getRealPath());
            if ($originalName === '') {
                $originalName = (string) $file->getClientOriginalName();
            }
        } elseif ($request->filled('attachment_data')) {
            $dataUri = trim((string) $request->input('attachment_data'));
            if (! preg_match('/^data:(image\/(?:jpeg|jpg|png|webp)|application\/pdf);base64,(.+)$/is', $dataUri, $matches)) {
                return false;
            }
            $mimeType = strtolower($matches[1]);
            $decoded = base64_decode($matches[2], true);
            if ($decoded === false || $decoded === '' || strlen($decoded) > self::MAX_ATTACHMENT_BYTES) {
                return false;
            }
            $rawBytes = $decoded;
            $extension = match ($mimeType) {
                'image/png' => 'png',
                'image/webp' => 'webp',
                'application/pdf' => 'pdf',
                default => 'jpg',
            };
            if ($originalName === '') {
                $originalName = 'attachment.'.$extension;
            }
        }

        if ($rawBytes === null) {
            return null;
        }

        $filename = Str::uuid()->toString().'.'.$extension;
        $relativePath = 'chat-attachments/'.$filename;

        Storage::disk('public')->put($relativePath, $rawBytes);

        try {
            if (! Schema::hasTable('uploaded_files')) {
                Schema::create('uploaded_files', function ($table) {
                    $table->id();
                    $table->string('path')->unique();
                    $table->string('mime_type', 100)->default('image/jpeg');
                    $table->longText('contents');
                    $table->timestamps();
                });
            }

            DB::table('uploaded_files')->updateOrInsert(
                ['path' => $relativePath],
                [
                    'mime_type' => $mimeType,
                    'contents' => base64_encode($rawBytes),
                    'updated_at' => now(),
                    'created_at' => now(),
                ]
            );
        } catch (\Throwable) {
            // Public disk write already succeeded
        }

        return [
            'path' => $relativePath,
            'name' => $originalName !== '' ? Str::limit($originalName, 180, '') : $filename,
            'mime' => $mimeType,
        ];
    }

    /**
     * @param  array{path:string,name:string,mime:string}|null  $attachment
     */
    private function createConversationMessage(Conversation $conversation, User $buyer, string $body, ?array $attachment): Message
    {
        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $buyer->id,
            'body' => $body !== '' ? $body : ($attachment ? 'Sent an attachment' : ''),
            'attachment_path' => $attachment['path'] ?? null,
            'attachment_name' => $attachment['name'] ?? null,
            'attachment_mime' => $attachment['mime'] ?? null,
            'is_bot' => false,
            'is_read' => false,
        ]);

        $conversation->update(['last_message_at' => now()]);
        $message->loadMissing('sender');
        $this->safeBroadcast($message);

        return $message;
    }

    private function markIncomingRead(Conversation $conversation, User $buyer): void
    {
        Message::query()
            ->where('conversation_id', $conversation->id)
            ->whereNull('read_at')
            ->where(function ($q) use ($buyer) {
                $q->where('sender_id', '!=', $buyer->id)
                    ->orWhereNull('sender_id');
            })
            ->update([
                'is_read' => true,
                'read_at' => now(),
            ]);
    }

    private function safeBroadcast(Message $message): void
    {
        try {
            broadcast(new MessageSent($message))->toOthers();
        } catch (\Throwable) {
            // Real-time websocket broadcasting is optional in CLI/polling environments
        }
    }

    private function sellerDisplayName(?User $seller): string
    {
        if (! $seller) {
            return 'Lumora Merchant';
        }

        return $seller->approvedSellerApplication?->business_name
            ?: ($seller->shop_name ?: ($seller->name ?: 'Lumora Merchant'));
    }

    private function transformConversation(
        Conversation $conversation,
        User $buyer,
        bool $includeMessages,
        int $unreadCount
    ): array {
        $seller = $conversation->seller;
        $sellerName = $this->sellerDisplayName($seller);
        $productContext = $conversation->product ? [
            'id' => (string) $conversation->product->id,
            'name' => $conversation->product->name,
            'price' => (string) $conversation->product->price,
            'image' => $this->resolvePublicAssetUrl($conversation->product->image_path),
        ] : null;

        $messagesCollection = $includeMessages
            ? $conversation->messages->sortBy('id')->values()
            : collect($conversation->latestMessage ? [$conversation->latestMessage] : []);
        $lastMessage = $conversation->relationLoaded('messages')
            ? $conversation->messages->sortBy('id')->last()
            : $conversation->latestMessage;

        return [
            'id' => (string) $conversation->id,
            'seller_id' => (string) ($conversation->seller_id ?? ''),
            'seller_name' => $sellerName,
            'seller_role' => ($seller?->role === 'seller' && ($seller?->approval_status === 'approved' || $seller?->approvedSellerApplication))
                ? 'Verified Luxury Merchant'
                : 'Lumora Merchant',
            'seller_avatar' => $this->resolvePublicAssetUrl($seller?->avatar),
            'product_id' => $conversation->product_id ? (string) $conversation->product_id : null,
            'product_context' => $productContext,
            'last_message_at' => ($conversation->last_message_at ?? $conversation->updated_at ?? now())->toIso8601String(),
            'unread_count' => $unreadCount,
            'messages' => $includeMessages
                ? $messagesCollection->map(fn (Message $m) => $this->transformMessage($m, $conversation, $buyer))->all()
                : [],
            'last_message' => $lastMessage
                ? $this->transformMessage($lastMessage, $conversation, $buyer)
                : null,
        ];
    }

    private function transformSupportConversation(
        Conversation $conversation,
        User $buyer,
        bool $includeMessages,
        int $unreadCount = 0
    ): array {
        $messages = $includeMessages
            ? $conversation->messages->sortBy('id')->values()->map(fn (Message $m) => $this->transformMessage($m, $conversation, $buyer))->all()
            : [];
        $lastMessage = $conversation->relationLoaded('messages')
            ? $conversation->messages->sortBy('id')->last()
            : $conversation->latestMessage;

        return [
            'id' => (string) $conversation->id,
            'seller_id' => 'support',
            'seller_name' => 'Lumora Support',
            'seller_role' => 'Concierge & Account Help',
            'seller_avatar' => null,
            'product_context' => null,
            'last_message_at' => ($conversation->last_message_at ?? $conversation->updated_at ?? now())->toIso8601String(),
            'unread_count' => $unreadCount,
            'messages' => $messages,
            'last_message' => $lastMessage
                ? $this->transformMessage($lastMessage, $conversation, $buyer)
                : null,
        ];
    }

    private function transformMessage(Message $message, Conversation $conversation, User $buyer): array
    {
        $isFromUser = ! $message->is_bot && $message->sender_id !== null && (int) $message->sender_id === (int) $buyer->id;

        if ($message->is_bot) {
            $senderName = 'Lumora Assistant';
            $senderRole = 'Support Bot';
        } elseif ($isFromUser) {
            $senderName = $buyer->name ?: 'You';
            $senderRole = 'Buyer';
        } elseif ($conversation->seller_id && (int) $message->sender_id === (int) $conversation->seller_id) {
            $senderName = $this->sellerDisplayName($conversation->seller);
            $senderRole = 'Seller';
        } else {
            $senderName = $message->sender?->name ?: 'Lumora Concierge';
            $senderRole = 'Support';
        }

        return [
            'id' => (string) $message->id,
            'sender_id' => $message->sender_id ? (string) $message->sender_id : null,
            'sender_name' => $senderName,
            'sender_role' => $senderRole,
            'body' => (string) $message->body,
            'message' => (string) $message->body,
            'timestamp' => ($message->created_at ?? now())->toIso8601String(),
            'created_at' => ($message->created_at ?? now())->toIso8601String(),
            'is_from_user' => $isFromUser,
            'is_bot' => (bool) $message->is_bot,
            'attachment_url' => $this->resolveAttachmentUrl($message->attachment_path),
            'attachment_name' => $message->attachment_name,
            'attachment_mime' => $message->attachment_mime,
        ];
    }

    private function resolveAttachmentUrl(?string $path): ?string
    {
        if (! $path) {
            return null;
        }
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }
        if (str_starts_with($path, 'chat-attachments/')) {
            return url('/chat-attachments/'.basename($path));
        }

        return Storage::disk('public')->url($path);
    }

    private function resolvePublicAssetUrl(?string $path): ?string
    {
        if (! $path) {
            return null;
        }
        $trimmed = trim($path);
        if ($trimmed === '') {
            return null;
        }
        if (str_starts_with($trimmed, 'http://') || str_starts_with($trimmed, 'https://') || str_starts_with($trimmed, 'data:')) {
            return $trimmed;
        }
        if (str_starts_with($trimmed, '/')) {
            return url($trimmed);
        }

        return url('/storage/'.ltrim($trimmed, '/'));
    }
}
