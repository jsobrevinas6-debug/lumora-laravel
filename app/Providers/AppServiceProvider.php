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
        });

        View::composer('profile.partials.account-sidebar', function ($view) {
            $view->with('buyerUnreadChatCount', $this->unreadChatCount('buyer_id'));
        });
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
