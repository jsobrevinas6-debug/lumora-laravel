<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class PayoutRequestStatusNotification extends Notification
{
    use Queueable;

    public function __construct(
        public int $payoutRequestId,
        public string $status,
        public float $amount,
        public ?string $transferReference = null,
        public ?string $reason = null,
    ) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        $amount = 'PHP '.number_format($this->amount, 2);
        $message = match ($this->status) {
            'approved' => "Your payout request for {$amount} was approved. It will be sent shortly.",
            'paid' => "Your payout of {$amount} has been sent. Reference: ".($this->transferReference ?: 'Not provided').'.',
            'rejected' => "Your payout request for {$amount} was rejected. Reason: ".($this->reason ?: 'Please contact support.').'.',
            default => "Your payout request for {$amount} was updated.",
        };

        return [
            'kind' => 'payout_status',
            'payout_request_id' => $this->payoutRequestId,
            'status' => $this->status,
            'amount' => $this->amount,
            'message' => $message,
        ];
    }
}
