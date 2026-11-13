<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Contracts\Queue\ShouldQueue;

class ProductApprovalRejectedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public int $productId,
        public string $productName,
        public string $reason,
        public ?string $note = null,
        public string $status = 'rejected',
    ) {}

    public function via(object $notifiable): array
    {
        return ['database', 'mail'];
    }

    public function toDatabase(object $notifiable): array
    {
        return [
            'kind' => 'product_approval_'.$this->status,
            'product_id' => $this->productId,
            'product_name' => $this->productName,
            'reason' => $this->reason,
            'note' => $this->note,
            'message' => "Your product {$this->productName} review status is {$this->status}.".($this->note ? ' '.$this->note : ''),
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $mail = (new MailMessage)->subject('Product review update: '.$this->productName)
            ->line('Your product “'.$this->productName.'” is now '.str_replace('_', ' ', $this->status).'.');
        if ($this->note) $mail->line('Admin note: '.$this->note);
        return $mail->line('Sign in to Lumora to review your product.');
    }
}
