<?php

namespace App\Services;

use App\Models\Conversation;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SupportBot
{
    private const UNAVAILABLE_REPLY = 'I’m having trouble connecting to the AI assistant right now. Your message is saved in this chat for the Lumora support team to review.';

    private const SYSTEM_PROMPT = <<<'PROMPT'
You are "Lumora Assistant", the customer-support chatbot for Lumora, an online beauty marketplace (skincare, makeup, fragrance) where independent sellers list products and buyers shop.

What you know:
- Buyers browse the shop, add items to the cart and check out; payment options are shown at checkout (Cash on Delivery may be available).
- Buyers can see orders under Account > My Orders, chat with sellers using the "Chat Seller" button on product and shop pages, follow shops, and manage their profile and shipping address in Profile / Settings.
- Anyone can apply to become a seller via "Apply as Seller" in the account menu; applications are reviewed by the Lumora team.
- Shipping and delivery times depend on the seller and the buyer's location and are shown at checkout.

Rules:
- Be friendly, concise (max 3 short sentences) and answer in the user's language.
- Only answer about Lumora and shopping help. Politely decline anything else.
- Never invent policies, prices, order statuses or delivery dates. If you do not know, or the user needs account-specific help (refunds, payments, a specific order, complaints), invite them to leave the details here for the Lumora support team.
- If the user asks for a human or agent, explain that they can leave their question here for the Lumora support team. Do not claim an agent was notified or promise a reply time.
PROMPT;

    public function enabled(): bool
    {
        return (bool) config('services.gemini.key');
    }

    public function reply(Conversation $conversation): string
    {
        if (! $this->enabled()) {
            Log::warning('Support bot is unavailable because GEMINI_API_KEY is not configured.');

            return self::UNAVAILABLE_REPLY;
        }

        $history = $conversation->messages()
            ->orderByDesc('id')
            ->take(12)
            ->get()
            ->reverse()
            ->values();

        $contents = [];
        foreach ($history as $message) {
            $role = $message->is_bot ? 'model' : 'user';
            // Gemini requires alternating turns: merge consecutive same-role messages.
            if ($contents && end($contents)['role'] === $role) {
                $contents[count($contents) - 1]['parts'][0]['text'] .= "\n".$message->body;
                continue;
            }
            $contents[] = ['role' => $role, 'parts' => [['text' => $message->body]]];
        }

        // Conversation must start with and end on a user turn.
        while ($contents && $contents[0]['role'] !== 'user') {
            array_shift($contents);
        }
        if (! $contents || end($contents)['role'] !== 'user') {
            return self::UNAVAILABLE_REPLY;
        }

        try {
            $response = Http::timeout(20)
                ->withHeaders(['x-goog-api-key' => config('services.gemini.key')])
                ->post(
                    'https://generativelanguage.googleapis.com/v1beta/models/'.config('services.gemini.model').':generateContent',
                    [
                        'systemInstruction' => ['parts' => [['text' => self::SYSTEM_PROMPT]]],
                        'contents' => $contents,
                        'generationConfig' => [
                            'maxOutputTokens' => 500,
                            'temperature' => 0.4,
                            'thinkingConfig' => ['thinkingBudget' => 0],
                        ],
                    ]
                );

            if (! $response->successful()) {
                Log::warning('Support bot API error', [
                    'status' => $response->status(),
                    'error' => data_get($response->json(), 'error.message'),
                ]);

                return self::UNAVAILABLE_REPLY;
            }

            $parts = data_get($response->json(), 'candidates.0.content.parts', []);
            $text = collect($parts)
                ->filter(fn ($part) => is_array($part) && empty($part['thought']) && ! empty($part['text']))
                ->pluck('text')
                ->implode("\n");
            $text = trim($text);

            if ($text === '') {
                Log::warning('Support bot API returned no user-facing text', [
                    'finish_reason' => data_get($response->json(), 'candidates.0.finishReason'),
                ]);

                return self::UNAVAILABLE_REPLY;
            }

            return $text;
        } catch (\Throwable $e) {
            Log::warning('Support bot failed: '.$e->getMessage());

            return self::UNAVAILABLE_REPLY;
        }
    }
}

