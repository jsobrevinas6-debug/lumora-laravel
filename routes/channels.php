<?php

use Illuminate\Support\Facades\Broadcast;
use App\Models\Conversation;

Broadcast::channel('conversation.{conversationId}', function ($user, $conversationId) {
    $conversation = Conversation::find($conversationId);

    if (! $conversation) {
        return false;
    }

    // Allow the conversation's owner (buyer/seller) OR any admin to listen
    return $user->id === $conversation->user_id || $user->role === 'admin';
});