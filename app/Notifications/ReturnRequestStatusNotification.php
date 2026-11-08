<?php

namespace App\Notifications;

use App\Models\ReturnRequest;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class ReturnRequestStatusNotification extends Notification
{
    use Queueable;

    public function __construct(private ReturnRequest $returnRequest, private string $status, private ?string $note = null) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        $approved = $this->status === 'approved';

        return [
            'kind' => 'return_request_status',
            'return_request_id' => $this->returnRequest->id,
            'order_id' => $this->returnRequest->order_id,
            'status' => $this->status,
            'message' => $approved
                ? 'Your return request was approved. Lumora Logistics has been notified to arrange the return.'
                : 'Your return/refund request was denied. '.($this->note ?: 'Please contact support if you need more information.'),
        ];
    }
}
