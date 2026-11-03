<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class ProductApprovalRejectedNotification extends Notification
{
    use Queueable;

    public function __construct(
        public int $productId,
        public string $productName,
        public string $reason,
        public ?string $note = null,
    ) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        return [
            'kind' => 'product_approval_rejected',
            'product_id' => $this->productId,
            'product_name' => $this->productName,
            'reason' => $this->reason,
            'note' => $this->note,
            'message' => "Your product {$this->productName} was not approved. Reason: {$this->reason}.",
        ];
    }
}
