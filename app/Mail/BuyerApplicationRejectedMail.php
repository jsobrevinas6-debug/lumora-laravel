<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class BuyerApplicationRejectedMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public string $buyerName, public string $reason) {}

    public function build(): self
    {
        return $this->subject('Update on your Lumora application')
            ->view('emails.buyer-rejected');
    }
}
