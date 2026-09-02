import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

window.Pusher = Pusher;

const echoEnabled = import.meta.env.VITE_ENABLE_ECHO === 'true';
const reverbHost = import.meta.env.VITE_REVERB_HOST;
const reverbKey = import.meta.env.VITE_REVERB_APP_KEY;

if (echoEnabled && reverbHost && reverbKey) {
    window.Echo = new Echo({
        broadcaster: 'reverb',
        key: reverbKey,
        wsHost: reverbHost,
        wsPort: Number(import.meta.env.VITE_REVERB_PORT ?? 8080),
        wssPort: Number(import.meta.env.VITE_REVERB_PORT ?? 8080),
        forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'http' ) === 'https',
        enabledTransports: ['ws', 'wss'],
    } );
} else {
    window.Echo = null;
}
