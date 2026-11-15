<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class AnnouncementPublishedNotification extends Notification
{
    use Queueable;

    public function __construct(
        public int $announcementId,
        public string $title,
        public string $body,
    ) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        return [
            'kind' => 'announcement_published',
            'announcement_id' => $this->announcementId,
            'title' => $this->title,
            'body' => $this->body,
            'message' => 'A new platform announcement is available.',
        ];
    }
}
