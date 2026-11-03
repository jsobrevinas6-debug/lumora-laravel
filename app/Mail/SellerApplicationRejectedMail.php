<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class SellerApplicationRejectedMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $sellerName,
        public string $businessName,
        public string $reason,
        public ?string $note = null,
    ) {}

    public function build(): static
    {
        return $this->subject('Update on your Lumora seller application')
            ->view('emails.seller-application-rejected');
    }
}
