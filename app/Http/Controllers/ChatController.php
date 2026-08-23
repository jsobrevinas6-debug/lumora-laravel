<?php

namespace App\Http\Controllers;

use App\Events\MessageSent;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ChatController extends Controller
{
    /**
     * Buyer/Seller: get (or create) their own conversation with admin.
     */
    public function myConversation()
    {
        $conversation = Conversation::firstOrCreate(
            ['user_id' => Auth::id()],
        );

        $messages = $conversation->messages()->with('sender')->orderBy('created_at')->get();

        return response()->json([
            'conversation_id' => $conversation->id,
            'messages' => $messages->map(fn ($m) => [
                'id'          => $m->id,
                'sender_id'   => $m->sender_id,
                'sender_name' => $m->sender->name,
                'body'        => $m->body,
                'created_at'  => $m->created_at->toIso8601String(),
            ]),
        ]);
    }

    /**
     * Send a message into a conversation (buyer, seller, or admin).
     */
    public function send(Request $request)
    {
        $request->validate([
            'conversation_id' => ['required', 'exists:conversations,id'],
            'body'            => ['required', 'string', 'max:2000'],
        ]);

        $conversation = Conversation::findOrFail($request->conversation_id);

        // Only the conversation owner or an admin may post into it
        abort_unless(
            Auth::id() === $conversation->user_id || Auth::user()->role === 'admin',
            403
        );

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id'       => Auth::id(),
            'body'            => $request->body,
        ]);

        $conversation->update(['last_message_at' => now()]);

        broadcast(new MessageSent($message))->toOthers();

        return response()->json(['status' => 'sent', 'message_id' => $message->id]);
    }

    /**
     * Admin: list every conversation, newest activity first.
     */
    public function adminInbox()
    {
        $conversations = Conversation::with('user')
            ->orderByDesc('last_message_at')
            ->get();

        return view('admin.chat', compact('conversations'));
    }

    /**
     * Admin: view a single conversation's full message history.
     */
    public function adminShow($id)
    {
        $conversation = Conversation::with('user')->findOrFail($id);
        $messages = $conversation->messages()->with('sender')->orderBy('created_at')->get();

        return response()->json([
            'conversation_id' => $conversation->id,
            'user_name'       => $conversation->user->name,
            'messages' => $messages->map(fn ($m) => [
                'id'          => $m->id,
                'sender_id'   => $m->sender_id,
                'sender_name' => $m->sender->name,
                'body'        => $m->body,
                'created_at'  => $m->created_at->toIso8601String(),
            ]),
        ]);
    }
}