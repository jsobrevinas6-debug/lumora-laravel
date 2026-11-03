<div style="font-family:Arial,sans-serif;color:#2B1C22;line-height:1.6;max-width:600px;margin:auto;padding:24px;">
    <h1 style="color:#5B1A35;font-size:22px;">Seller application update</h1>
    <p>Hello {{ $sellerName }},</p>
    <p>We reviewed your application for <strong>{{ $businessName }}</strong>. We’re unable to approve it at this time.</p>
    <p><strong>Reason:</strong> {{ $reason }}</p>
    @if (filled($note))
        <p><strong>Note from our review team:</strong><br>{{ $note }}</p>
    @endif
    <p>You can update your information and submit a new application from your Lumora account.</p>
    <p>Thank you,<br>Lumora Marketplace</p>
</div>
