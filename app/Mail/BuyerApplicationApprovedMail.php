<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class BuyerApplicationApprovedMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public string $buyerName) {}

    public function build(): self
    {
        return $this->subject('Your Lumora account is approved')
            ->view('emails.buyer-approved');
    }
}
