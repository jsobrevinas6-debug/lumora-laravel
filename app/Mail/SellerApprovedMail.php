<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class SellerApprovedMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $sellerName;
    public string $businessName;

    public function __construct(string $sellerName, string $businessName)
    {
        $this->sellerName = $sellerName;
        $this->businessName = $businessName;
    }

    public function build()
    {
        return $this->subject('Your Lumora seller application has been approved!')
            ->view('emails.seller-approved');
    }
}