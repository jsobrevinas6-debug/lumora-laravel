@if (!empty($reviewMedia))
    <div class="review-media" aria-label="Review photos and videos">
        @foreach ($reviewMedia as $mediaPath)
            @php($mediaExtension = strtolower(pathinfo($mediaPath, PATHINFO_EXTENSION)))
            @php($mediaUrl = \Illuminate\Support\Facades\Storage::disk('public')->url($mediaPath))
            @if (in_array($mediaExtension, ['mp4', 'mov', 'webm'], true))
                <video controls preload="metadata" aria-label="Customer review video">
                    <source src="{{ $mediaUrl }}">
                    Your browser does not support video playback.
                </video>
            @else
                <a href="{{ $mediaUrl }}" target="_blank" rel="noopener noreferrer" aria-label="Open customer review photo">
                    <img src="{{ $mediaUrl }}" alt="Photo attached to a customer review" loading="lazy">
                </a>
            @endif
        @endforeach
    </div>
@endif
