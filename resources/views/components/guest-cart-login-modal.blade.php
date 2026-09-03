@guest
<div id="guestCartModal" class="guest-cart-modal" aria-hidden="true" role="dialog" aria-labelledby="guestCartTitle">
    <div class="guest-cart-backdrop" data-close-guest-cart></div>

    <div class="guest-cart-card" role="document">
        <button type="button" class="guest-cart-close" data-close-guest-cart aria-label="Close">&times;</button>

        <div class="guest-cart-brand">LUM<span>O</span>RA</div>
        <h2 id="guestCartTitle">Sign in to view your<br>cart</h2>
        <p class="guest-cart-subtitle">Save your items and check out faster with a<br> Lumora account.</p>

        <div class="guest-cart-divider"><span>or continue with email</span></div>

        <form method="POST" action="{{ route('login') }}">
            @csrf
            <input type="hidden" name="redirect_to" value="{{ route('buyer.cart') }}">

            <div class="guest-form-group">
                <label for="guestEmail">Email address</label>
                <input class="guest-field" id="guestEmail" type="email" name="email" value="{{ old('email') }}" placeholder="Enter your email" required>
            </div>

            <div class="guest-form-group">
                <label for="guestPassword">Password</label>
                <input class="guest-field" id="guestPassword" type="password" name="password" placeholder="Enter your password" required>
            </div>

            <button class="guest-signin-btn" type="submit">Sign in</button>
        </form>

        <a class="guest-forgot" href="{{ route('password.request') }}">Forgot password?</a>
        <p class="guest-register">New to Lumora? <a href="{{ route('register') }}">Create an account</a></p>

        @if (Route::has('google.redirect'))
            <div class="guest-cart-divider guest-google-divider"><span>or continue with Google</span></div>
            <a class="guest-google-btn" href="{{ route('google.redirect') }}">
                <span class="google-g">G</span>
                <span>Continue with Google</span>
            </a>
        @endif

        <button type="button" class="guest-continue" data-close-guest-cart>Continue shopping as guest</button>
    </div>
</div>

<style>
    .guest-cart-modal {
        display:none;
        position:fixed;
        inset:0;
        z-index:1000;
        align-items:center;
        justify-content:center;
        padding:20px;
    }

    .guest-cart-modal.is-open { display:flex; }

    .guest-cart-backdrop {
        position:absolute;
        inset:0;
        background:rgba(74,25,66,.48);
        backdrop-filter:blur(6px);
    }

    .guest-cart-card {
        position:relative;
        z-index:1;
        width:min(100%,440px);
        padding:38px 42px 30px;
        border-radius:22px;
        background:rgba(255,252,250,.96);
        box-shadow:0 20px 50px rgba(74,25,66,.22);
        text-align:center;
        color:#2B1826;
        font-family:'Work Sans',sans-serif;
    }

    .guest-cart-close {
        position:absolute;
        top:17px;
        right:20px;
        border:0;
        padding:0;
        background:transparent;
        color:#B96562;
        font-size:27px;
        line-height:1;
        cursor:pointer;
    }

    .guest-cart-brand {
        margin-top:3px;
        color:#4A1942;
        font:600 30px 'Fraunces',Georgia,serif;
        letter-spacing:3px;
    }

    .guest-cart-brand span { color:#B96562; }

    .guest-cart-card h2 {
        margin:20px 0 9px;
        color:#4A1942;
        font:600 29px/1.15 'Fraunces',Georgia,serif;
    }

    .guest-cart-subtitle {
        margin:0 auto 22px;
        color:#A08D96;
        font-size:13px;
        line-height:1.5;
    }

    .guest-google-btn,
    .guest-signin-btn {
        width:100%;
        min-height:45px;
        display:flex;
        align-items:center;
        justify-content:center;
        gap:8px;
        border:1px solid #B96562;
        border-radius:7px;
        background:#FFFDFB;
        color:#2B1826;
        font:500 13px 'Work Sans',sans-serif;
        text-decoration:none;
        cursor:pointer;
    }

    .guest-google-btn:hover,
    .guest-signin-btn:hover { background:#FBF3F0; }

    .google-g {
        color:#4285F4;
        font-size:18px;
        font-weight:700;
    }

    .guest-cart-divider {
        display:flex;
        align-items:center;
        gap:10px;
        margin:23px 0 20px;
        color:#A08D96;
        font-size:11px;
    }

    .guest-cart-divider::before,
    .guest-cart-divider::after {
        content:'';
        height:1px;
        flex:1;
        background:#EFDCD4;
    }

    .guest-form-group { margin-bottom:15px; text-align:left; }

    .guest-form-group label {
        display:block;
        margin-bottom:6px;
        color:#2B1826;
        font-size:12px;
        font-weight:500;
    }

    .guest-field {
        width:100%;
        height:44px;
        padding:0 13px;
        border:1px solid #DDE7F4;
        border-radius:8px;
        background:#EDF4FD;
        color:#2B1826;
        font:13px 'Work Sans',sans-serif;
    }

    .guest-field:focus {
        outline:none;
        border-color:#B96562;
        box-shadow:0 0 0 2px rgba(185,101,98,.12);
    }

    .guest-field::placeholder { color:#A08D96; }

    .guest-signin-btn {
        margin-top:19px;
        background:#FFFDFB;
        color:#4A1942;
        font-weight:600;
    }

    .guest-forgot,
    .guest-register,
    .guest-continue {
        display:block;
        margin-top:16px;
        color:#4A1942;
        font-size:12px;
    }

    .guest-forgot,
    .guest-register a,
    .guest-continue { text-decoration:underline; }

    .guest-register { color:#A08D96; }

    .guest-continue {
        margin:21px auto 0;
        border:0;
        padding:0;
        background:transparent;
        cursor:pointer;
        font-family:'Work Sans',sans-serif;
    }

    @media (max-width:520px) {
        .guest-cart-modal { align-items:flex-end; padding:0; }
        .guest-cart-card {
            width:100%;
            padding:32px 24px 27px;
            border-radius:22px 22px 0 0;
        }
        .guest-cart-card h2 { font-size:25px; }
    }
</style>

<script>
(() => {
    const modal = document.getElementById('guestCartModal');
    if (!modal) return;

    const openModal = () => {
        modal.classList.add('is-open');
        modal.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';
        modal.querySelector('input[type="email"]')?.focus();
    };

    const closeModal = () => {
        modal.classList.remove('is-open');
        modal.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
    };

    document.querySelectorAll('[data-open-guest-cart]').forEach(button => {
        button.addEventListener('click', openModal);
    });

    modal.querySelectorAll('[data-close-guest-cart]').forEach(button => {
        button.addEventListener('click', closeModal);
    });

    document.addEventListener('keydown', event => {
        if (event.key === 'Escape') closeModal();
    });
})();
</script>
@endguest
