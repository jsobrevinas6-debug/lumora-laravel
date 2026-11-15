<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

abstract class UserAccountStatusNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        protected string $reason,
        protected string $note,
        protected ?\DateTimeInterface $until = null,
    ) {}

    abstract protected function subject(): string;

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $mail = (new MailMessage)->subject('Lumora account update: '.$this->subject())
            ->greeting('Hello '.$notifiable->name.',')
            ->line($this->intro())
            ->line('Reason: '.$this->reason)
            ->line($this->note);

        if ($this->until) $mail->line('This status is scheduled to end on '.$this->until->format('M j, Y g:i A').'.');
        if ($this->subject() === 'Suspended') {
            $mail->line($this->until
                ? 'You will be able to sign in again when the suspension ends.'
                : 'This suspension will remain in effect until an administrator reactivates your account.');
        }
        if ($this->subject() === 'Deactivated') $mail->line('Open orders are not cancelled automatically. Please contact Lumora support if you need help.');

        return $mail->salutation('Lumora Support');
    }

    private function intro(): string
    {
        return match ($this->subject()) {
            'Suspended' => 'Your Lumora account has been temporarily suspended.',
            'Deactivated' => 'Your Lumora account has been deactivated.',
            default => 'Your Lumora account has been reactivated.',
        };
    }
}
