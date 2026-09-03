<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ config('app.name', 'Lumora') }} | Sign in</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --plum: #351128;
            --plum-soft: #5a294d;
            --rose: #b96562;
            --cream: #fffaf6;
            --paper: #fffdfb;
            --beige: #f7eee8;
            --line: #e8d8d0;
            --muted: #857579;
            --gold: #c9972b;
            --error-bg: #fff0ed;
            --error-text: #9c3d38;
        }

        * { box-sizing: border-box; }
        body {
            min-height: 100vh;
            margin: 0;
            color: var(--plum);
            background: var(--cream);
            font-family: 'Inter', sans-serif;
        }
        a { color: inherit; }
        button, input { font: inherit; }
        button { cursor: pointer; }

        .login-shell {
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 32px;
            background:
                radial-gradient(circle at 8% 12%, rgba(236, 205, 193, .35), transparent 28%),
                radial-gradient(circle at 92% 88%, rgba(236, 213, 205, .45), transparent 32%),
                var(--cream);
        }
        .login-frame {
            width: min(1120px, 100%);
            min-height: 690px;
            display: grid;
            grid-template-columns: .82fr 1.18fr;
            overflow: hidden;
            border: 1px solid var(--line);
            border-radius: 20px;
            background: var(--paper);
            box-shadow: 0 24px 70px rgba(53, 17, 40, .12);
        }
        .login-art {
            position: relative;
            min-height: 690px;
            display: flex;
            align-items: flex-start;
            padding: 54px 42px;
            overflow: hidden;
            background-image:
                linear-gradient(180deg, rgba(53, 17, 40, .04), rgba(53, 17, 40, .10)),
                url('{{ asset('images/hero.jpg') }}');
            background-size: cover;
            background-position: center;
        }
        .login-art::after {
            content: '';
            position: absolute;
            inset: 0;
            background: linear-gradient(180deg, rgba(255,250,246,.06), rgba(53,17,40,.26));
            pointer-events: none;
        }
        .art-brand {
            position: relative;
            z-index: 1;
            font-family: 'Playfair Display', serif;
            font-size: 30px;
            letter-spacing: 5px;
            color: var(--plum);
        }
        .art-caption {
            position: absolute;
            z-index: 1;
            left: 42px;
            right: 42px;
            bottom: 48px;
        }
        .art-caption strong {
            display: block;
            max-width: 330px;
            font-family: 'Playfair Display', serif;
            font-size: clamp(30px, 4vw, 52px);
            line-height: 1.02;
            color: var(--plum);
        }
        .art-caption span {
            display: block;
            margin-top: 16px;
            color: var(--plum-soft);
            font-size: 14px;
        }

        .login-panel {
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 48px clamp(28px, 6vw, 86px);
            background: var(--paper);
        }
        .login-card { width: min(430px, 100%); }
        .login-heading { text-align: center; }
        .login-heading h1 {
            margin: 0;
            font-family: 'Playfair Display', serif;
            font-size: clamp(36px, 4vw, 54px);
            font-weight: 600;
            line-height: 1.05;
            letter-spacing: -.02em;
        }
        .ornament {
            display: flex;
            align-items: center;
            gap: 12px;
            width: 100px;
            margin: 18px auto 14px;
            color: var(--gold);
        }
        .ornament::before, .ornament::after { content: ''; flex: 1; height: 1px; background: #dec8bc; }
        .ornament span { font-size: 14px; }
        .subtitle { margin: 0 0 34px; color: var(--muted); font-size: 14px; text-align: center; }

        .status, .error-box { padding: 12px 14px; border-radius: 10px; margin-bottom: 18px; font-size: 13px; }
        .status { color: #56704e; background: #eef5eb; border: 1px solid #d4e4cf; }
        .error-box { color: var(--error-text); background: var(--error-bg); border: 1px solid #f0cfc8; }

        .form-group { margin-bottom: 18px; }
        .form-group label { display: block; margin-bottom: 8px; color: var(--plum); font-size: 13px; font-weight: 600; }
        .input-wrap { position: relative; display: flex; align-items: center; }
        .input-wrap > svg { position: absolute; left: 15px; width: 18px; height: 18px; color: #aa9898; pointer-events: none; }
        .input-wrap input {
            width: 100%;
            height: 50px;
            padding: 0 44px 0 46px;
            border: 1px solid var(--line);
            border-radius: 9px;
            outline: none;
            color: var(--plum);
            background: #fffaf7;
            transition: border-color .2s ease, box-shadow .2s ease;
        }
        .input-wrap input:focus { border-color: var(--rose); box-shadow: 0 0 0 3px rgba(185,101,98,.13); }
        .input-wrap input::placeholder { color: #b2a4a1; }
        .toggle-pass {
            position: absolute;
            right: 13px;
            display: grid;
            place-items: center;
            padding: 4px;
            border: 0;
            color: var(--muted);
            background: transparent;
        }
        .toggle-pass svg { width: 18px; height: 18px; }
        .form-options { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin: 4px 0 24px; font-size: 12px; }
        .remember { display: inline-flex; align-items: center; gap: 7px; color: var(--muted); }
        .remember input { accent-color: var(--rose); }
        .forgot { color: var(--plum); font-weight: 600; text-decoration: underline; text-underline-offset: 3px; }

        .submit-btn, .google-btn {
            width: 100%;
            min-height: 50px;
            border-radius: 9px;
            font-weight: 700;
            transition: transform .2s ease, background-color .2s ease, border-color .2s ease;
        }
        .submit-btn {
            border: 1px solid var(--rose);
            color: var(--plum);
            background: var(--cream);
        }
        .submit-btn:hover {
            background: #ffffff;
            border-color: var(--rose);
            color: var(--plum);
            transform: translateY(-1px);
        }
        .divider { display: flex; align-items: center; gap: 12px; margin: 25px 0 16px; color: var(--muted); font-size: 12px; }
        .divider::before, .divider::after { content: ''; flex: 1; height: 1px; background: var(--line); }
        .google-btn {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 11px;
            border: 1px solid var(--line);
            color: var(--plum);
            background: #fff;
        }
        .google-btn:hover { border-color: var(--rose); background: var(--beige); transform: translateY(-1px); }
        .google-icon { width: 20px; height: 20px; }
        .register-note { margin: 25px 0 0; color: var(--muted); font-size: 13px; text-align: center; }
        .register-note a { color: var(--plum); font-weight: 700; text-decoration: underline; text-underline-offset: 3px; }
        .google-unavailable { cursor: not-allowed; opacity: .96; }
        .google-unavailable:hover { transform: none; background: #fff; border-color: var(--line); }
        .back-home { display:inline-flex; align-items:center; gap:7px; margin:0 auto 24px; color:var(--plum); font-size:12px; font-weight:600; text-decoration:none; }
        .back-home:hover { color:var(--rose); text-decoration:underline; text-underline-offset:3px; }

        @media (max-width: 780px) {
            .login-shell { padding: 16px; }
            .login-frame { display: block; min-height: 0; border-radius: 16px; }
            .login-art { min-height: 220px; padding: 28px; background-position: center 58%; }
            .art-brand { font-size: 24px; }
            .art-caption { left: 28px; right: 28px; bottom: 28px; }
            .art-caption strong { font-size: 30px; }
            .art-caption span { margin-top: 7px; font-size: 12px; }
            .login-panel { padding: 40px 24px 34px; }
        }
        @media (max-width: 420px) {
            .login-art { min-height: 180px; }
            .login-panel { padding: 34px 18px 28px; }
            .form-options { align-items: flex-start; flex-direction: column; }
        }
    </style>
</head>
<body>
    <main class="login-shell">
        <section class="login-frame" aria-labelledby="login-title">
            <aside class="login-art" aria-label="Lumora brand message">
                <div class="art-brand">LUMORA</div>
                <div class="art-caption">
                    <strong>Timeless<br>Elegance</strong>
                    <span>Designed to shine. Made to be yours.</span>
                </div>
            </aside>

            <section class="login-panel">
                <div class="login-card">
                    <a href="{{ route('home') }}" class="back-home" aria-label="Back to Lumora homepage">&larr; Back to homepage</a>
                    <header class="login-heading">
                        <h1 id="login-title">Welcome back</h1>
                        <div class="ornament" aria-hidden="true"><span>✦</span></div>
                        <p class="subtitle">Sign in to continue shopping with Lumora</p>
                    </header>

                    @if (session('status'))
                        <div class="status">{{ session('status') }}</div>
                    @endif

                    @if ($errors->any())
                        <div class="error-box" role="alert">{{ $errors->first() }}</div>
                    @endif

                    <form method="POST" action="{{ route('login') }}">
                        @csrf
                        <div class="form-group">
                            <label for="email">Email address</label>
                            <div class="input-wrap">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/></svg>
                                <input id="email" type="email" name="email" value="{{ old('email') }}" placeholder="Enter your email" autocomplete="email" required autofocus>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="password">Password</label>
                            <div class="input-wrap">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><rect x="5" y="10" width="14" height="10" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>
                                <input id="password" type="password" name="password" placeholder="Enter your password" autocomplete="current-password" required>
                                <button type="button" class="toggle-pass" onclick="togglePassword()" aria-label="Show password">
                                    <svg id="eye-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M2 12s3.8-7 10-7 10 7 10 7-3.8 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg>
                                </button>
                            </div>
                        </div>

                        <div class="form-options">
                            <label class="remember"><input type="checkbox" name="remember"> Remember me</label>
                            @if (Route::has('password.request'))
                                <a class="forgot" href="{{ route('password.request') }}">Forgot password?</a>
                            @endif
                        </div>

                        <button type="submit" class="submit-btn">Sign in</button>
                    </form>

                    <div class="divider"><span>or continue with</span></div>

                    @if (Route::has('google.redirect'))
                        <a class="google-btn" href="{{ route('google.redirect') }}">
                            <svg class="google-icon" viewBox="0 0 24 24" aria-hidden="true"><path fill="#4285F4" d="M21.6 12.23c0-.7-.06-1.38-.18-2.03H12v3.84h5.38a4.6 4.6 0 0 1-1.99 3.02v2.51h3.22c1.89-1.74 2.99-4.3 2.99-7.34Z"/><path fill="#34A853" d="M12 22c2.7 0 4.96-.89 6.61-2.43l-3.22-2.51c-.89.6-2.02.96-3.39.96-2.61 0-4.82-1.76-5.61-4.13H3.06v2.59A9.98 9.98 0 0 0 12 22Z"/><path fill="#FBBC05" d="M6.39 13.89A6 6 0 0 1 6.08 12c0-.66.11-1.3.31-1.89V7.52H3.06A10 10 0 0 0 2 12c0 1.61.39 3.13 1.06 4.48l3.33-2.59Z"/><path fill="#EA4335" d="M12 5.98c1.47 0 2.79.5 3.83 1.49l2.87-2.87C16.95 2.97 14.7 2 12 2a9.98 9.98 0 0 0-8.94 5.52l3.33 2.59C7.18 7.74 9.39 5.98 12 5.98Z"/></svg>
                            Continue with Google
                        </a>
                    @else
                        <button type="button" class="google-btn google-unavailable" title="Google sign-in is not configured yet" onclick="alert('Google sign-in is not configured yet. Please use email and password for now.')">
                            <svg class="google-icon" viewBox="0 0 24 24" aria-hidden="true"><path fill="#4285F4" d="M21.6 12.23c0-.7-.06-1.38-.18-2.03H12v3.84h5.38a4.6 4.6 0 0 1-1.99 3.02v2.51h3.22c1.89-1.74 2.99-4.3 2.99-7.34Z"/><path fill="#34A853" d="M12 22c2.7 0 4.96-.89 6.61-2.43l-3.22-2.51c-.89.6-2.02.96-3.39.96-2.61 0-4.82-1.76-5.61-4.13H3.06v2.59A9.98 9.98 0 0 0 12 22Z"/><path fill="#FBBC05" d="M6.39 13.89A6 6 0 0 1 6.08 12c0-.66.11-1.3.31-1.89V7.52H3.06A10 10 0 0 0 2 12c0 1.61.39 3.13 1.06 4.48l3.33-2.59Z"/><path fill="#EA4335" d="M12 5.98c1.47 0 2.79.5 3.83 1.49l2.87-2.87C16.95 2.97 14.7 2 12 2a9.98 9.98 0 0 0-8.94 5.52l3.33 2.59C7.18 7.74 9.39 5.98 12 5.98Z"/></svg>
                            Continue with Google
                        </button>
                    @endif

                    <p class="register-note">Don’t have an account? <a href="{{ route('register') }}">Create account</a></p>
                </div>
            </section>
        </section>
    </main>

    <script>
        function togglePassword() {
            const input = document.getElementById('password');
            const eye = document.getElementById('eye-icon');
            const button = document.querySelector('.toggle-pass');
            const isHidden = input.type === 'password';
            input.type = isHidden ? 'text' : 'password';
            button.setAttribute('aria-label', isHidden ? 'Hide password' : 'Show password');
            eye.innerHTML = isHidden
                ? '<path d="M3 3l18 18M10.6 10.6a2 2 0 0 0 2.8 2.8M9.9 4.2A10.6 10.6 0 0 1 12 4c6.2 0 10 8 10 8a18 18 0 0 1-3.1 4.2M6.4 6.4C3.6 8.4 2 12 2 12s3.8 8 10 8a9.8 9.8 0 0 0 3.1-.5"/>'
                : '<path d="M2 12s3.8-7 10-7 10 7 10 7-3.8 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>';
        }
    </script>
</body>
</html>

<!-- Place this file at resources/views/auth/login.blade.php -->
