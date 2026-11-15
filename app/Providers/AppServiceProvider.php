<?php

namespace App\Providers;

use App\Models\Message;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        View::composer('layouts.seller', function ($view) {
            $view->with('sellerUnreadChatCount', $this->unreadChatCount('seller_id'));
            $view->with('sellerPendingReturnsCount', $this->sellerPendingReturnsCount());
        });

        View::composer('profile.partials.account-sidebar', function ($view) {
            $view->with('buyerUnreadChatCount', $this->unreadChatCount('buyer_id'));
        });
    }

    private function sellerPendingReturnsCount(): int
    {
        if (! Auth::check() || ! Schema::hasTable('return_requests') || ! Schema::hasTable('order_items')) {
            return 0;
        }

        try {
            return \App\Models\ReturnRequest::query()
                ->where('status', 'pending')
                ->whereHas('order.items', fn ($query) => $query->where('seller_id', Auth::id()))
                ->count();
        } catch (\Throwable) {
            return 0;
        }
    }

    private function unreadChatCount(string $conversationColumn): int
    {
        if (! Auth::check()
            || ! Schema::hasTable('conversations')
            || ! Schema::hasTable('messages')
            || ! Schema::hasColumn('conversations', $conversationColumn)
            || ! Schema::hasColumn('messages', 'read_at')) {
            return 0;
        }

        return Message::query()
            ->whereNull('read_at')
            ->where('sender_id', '!=', Auth::id())
            ->whereHas('conversation', fn ($conversation) => $conversation->where($conversationColumn, Auth::id()))
            ->count();
    }
}
