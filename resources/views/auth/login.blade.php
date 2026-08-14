<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lumora | Login</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --maroon:#4A1942; --maroon-dark:#2E1330; --coral:#E2582E; --border:#EFDCD4; --text-dark:#2B1826; --text-muted:#A08D96; }
        * { box-sizing:border-box; margin:0; padding:0; }
        body { font-family:'Work Sans',sans-serif; color:var(--text-dark); min-height:100vh; display:flex; align-items:center; justify-content:center; position:relative; overflow:hidden; background: radial-gradient(circle at 15% 15%,rgba(232,196,196,.55),transparent 45%), radial-gradient(circle at 85% 20%,rgba(245,220,210,.6),transparent 50%), linear-gradient(135deg,#F7E6E2 0%,#F2D9D6 30%,#E9CBCE 55%,#D8B9C4 75%,#C7A8BB 100%); }
        .wave { position:absolute; left:-10%; width:120%; height:260px; border-radius:50%; filter:blur(2px); opacity:.55; }
        .wave1 { bottom:-140px; background:linear-gradient(120deg,#E7C9CE,#D9B7C6); transform:rotate(-4deg); }
        .wave2 { bottom:-180px; background:linear-gradient(120deg,#C9A8BC,#B497B0); opacity:.5; transform:rotate(-2deg); }
        .leaf-shadow { position:absolute; top:-40px; left:-40px; width:320px; height:320px; opacity:.18; background:radial-gradient(circle,#3a2a35 0%,transparent 70%); filter:blur(6px); }
        .card { position:relative; z-index:2; background:rgba(255,252,250,.92); backdrop-filter:blur(6px); padding:40px 40px 32px; border-radius:26px; box-shadow:0 20px 50px rgba(74,25,66,.18); width:380px; text-align:center; }
        .logo-icon { margin:0 auto 10px; width:56px; height:56px; position:relative; }
        .logo-icon svg { width:100%; height:100%; }
        .sparkle { position:absolute; color:#D8A25E; }
        .sparkle.s1 { top:-6px; left:-2px; font-size:10px; }
        .sparkle.s2 { top:-10px; right:-4px; font-size:8px; }
        .brand { font-family:'Fraunces',serif; font-size:1.9rem; font-weight:600; letter-spacing:3px; margin-bottom:4px; color:var(--maroon); }
        .brand .o-accent { color:var(--coral); }
        p.subtitle { color:var(--text-muted); font-size:.85rem; margin-bottom:26px; }
        .error-box { background:#fdece6; color:#b8451f; padding:10px 14px; border-radius:12px; margin-bottom:16px; font-size:.85rem; }
        .form-group { margin-bottom:16px; text-align:left; }
        label { display:block; margin-bottom:6px; font-size:.82rem; font-weight:500; color:var(--text-dark); }
        .input-wrap { position:relative; display:flex; align-items:center; }
        .input-wrap svg.icon-left { position:absolute; left:14px; width:17px; height:17px; color:#B9A2AC; pointer-events:none; }
        input[type=email], input[type=password] { width:100%; padding:12px 14px 12px 40px; border:1px solid var(--border); border-radius:14px; font-size:.92rem; font-family:inherit; background:#FBF3F0; color:var(--text-dark); }
        input:focus { outline:none; border-color:var(--maroon); }
        input:-webkit-autofill, input:-webkit-autofill:hover, input:-webkit-autofill:focus { -webkit-text-fill-color:var(--text-dark); -webkit-box-shadow:0 0 0px 1000px #FBF3F0 inset; transition:background-color 5000s ease-in-out 0s; }
        .toggle-pass { position:absolute; right:14px; background:none; border:none; cursor:pointer; color:#B9A2AC; display:flex; padding:0; }
        .toggle-pass svg { width:18px; height:18px; }
        .btn-row { display:flex; gap:10px; margin-top:24px; }
        button.submit-btn, a.btn-signup { padding:13px; border-radius:24px; border:none; font-weight:600; font-size:.92rem; font-family:inherit; cursor:pointer; }
        button.submit-btn { flex:1.4; background:var(--maroon-dark); color:#fff; }
        button.submit-btn:hover { background:#22102a; }
        a.btn-signup { flex:1; background:#fff; color:var(--maroon); border:1.5px solid var(--maroon); text-align:center; text-decoration:none; display:flex; align-items:center; justify-content:center; }
        a.btn-signup:hover { background:#FBF3F0; }
        .divider { display:flex; align-items:center; gap:10px; margin:26px 0 12px; color:#D8A25E; }
        .divider::before, .divider::after { content:''; flex:1; height:1px; background:var(--border); }
        .tagline { font-family:'Fraunces',serif; font-style:italic; font-size:.85rem; color:var(--text-muted); }
    </style>
</head>
<body>
<div class="leaf-shadow"></div>
<div class="wave wave1"></div>
<div class="wave wave2"></div>

<div class="card">
    <div class="logo-icon">
        <span class="sparkle s1">✦</span>
        <span class="sparkle s2">✦</span>
        <svg viewBox="0 0 64 64" fill="none">
            <path d="M14 50V26a18 18 0 0 1 36 0v24" stroke="#C98A52" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M32 42c-5.5 0-9-3.2-9-8.5 3.6 0 7 1.6 9 5 2-3.4 5.4-5 9-5 0 5.3-3.5 8.5-9 8.5z" fill="#F6E6D6" stroke="#C98A52" stroke-width="1.2" stroke-linejoin="round"/>
            <line x1="10" y1="50" x2="54" y2="50" stroke="#C98A52" stroke-width="1.3" stroke-linecap="round"/>
        </svg>
    </div>

    <div class="brand">LUM<span class="o-accent">O</span>RA</div>
    <p class="subtitle">Log in to your account</p>

    @if (session('status'))
        <div class="error-box" style="background:#eef3ec;color:#5C7355;">{{ session('status') }}</div>
    @endif

    @if ($errors->any())
        <div class="error-box">{{ $errors->first() }}</div>
    @endif

    <form method="POST" action="{{ route('login') }}">
        @csrf
        <div class="form-group">
            <label>Email</label>
            <div class="input-wrap">
                <svg class="icon-left" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4.5 5-6 8-6s6.5 1.5 8 6"/></svg>
                <input type="email" name="email" value="{{ old('email') }}" placeholder="you@example.com" required autofocus>
            </div>
        </div>
        <div class="form-group">
            <label>Password</label>
            <div class="input-wrap">
                <svg class="icon-left" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>
                <input type="password" name="password" id="password" required>
                <button type="button" class="toggle-pass" onclick="togglePassword()">
                    <svg id="eye-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3"/></svg>
                </button>
            </div>
        </div>
        <div class="btn-row">
            <button type="submit" class="submit-btn">Login</button>
            <a href="{{ route('register') }}" class="btn-signup">Sign Up</a>
        </div>
    </form>

    <div class="divider">✦</div>
    <div class="tagline">Step into something beautiful</div>
</div>

<script>
function togglePassword() {
    const input = document.getElementById('password');
    const eye = document.getElementById('eye-icon');
    if (input.type === 'password') {
        input.type = 'text';
        eye.innerHTML = '<path d="M17.94 17.94A10.94 10.94 0 0 1 12 19c-7 0-11-7-11-7a18.5 18.5 0 0 1 4.22-5.06M9.9 4.24A10.94 10.94 0 0 1 12 4c7 0 11 7 11 7a18.5 18.5 0 0 1-2.16 3.19M14.12 14.12a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/>';
    } else {
        input.type = 'password';
        eye.innerHTML = '<path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3"/>';
    }
}
</script>
</body>
</html>
