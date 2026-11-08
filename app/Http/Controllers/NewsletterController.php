<?php

namespace App\Http\Controllers;

use App\Models\NewsletterSubscriber;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class NewsletterController extends Controller
{
    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email:rfc', 'max:255'],
        ]);

        NewsletterSubscriber::updateOrCreate(
            ['email' => mb_strtolower(trim($validated['email']))],
            ['subscribed_at' => now()],
        );

        return back()->with('newsletter_success', 'You’re subscribed. Watch your inbox for Lumora updates.');
    }
}
