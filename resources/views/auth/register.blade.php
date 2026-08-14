<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lumora | Sign Up</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --maroon:#4A1942; --maroon-dark:#2E1330; --coral:#E2582E; --border:#EFDCD4; --text-dark:#2B1826; --text-muted:#A08D96; }
        * { box-sizing:border-box; margin:0; padding:0; }
        body { font-family:'Work Sans',sans-serif; color:var(--text-dark); min-height:100vh; display:flex; align-items:center; justify-content:center; padding:40px 16px; background: radial-gradient(circle at 15% 15%,rgba(232,196,196,.55),transparent 45%), radial-gradient(circle at 85% 20%,rgba(245,220,210,.6),transparent 50%), linear-gradient(135deg,#F7E6E2 0%,#F2D9D6 30%,#E9CBCE 55%,#D8B9C4 75%,#C7A8BB 100%); }
        .card { background:rgba(255,252,250,.95); padding:40px; border-radius:26px; box-shadow:0 20px 50px rgba(74,25,66,.18); width:460px; max-width:100%; }
        .brand { font-family:'Fraunces',serif; font-size:1.7rem; font-weight:600; letter-spacing:3px; text-align:center; margin-bottom:4px; color:var(--maroon); }
        .brand .o-accent { color:var(--coral); }
        p.subtitle { text-align:center; color:var(--text-muted); font-size:.85rem; margin-bottom:26px; }
        .error-box { background:#fdece6; color:#b8451f; padding:10px 14px; border-radius:12px; margin-bottom:16px; font-size:.85rem; }
        .error-box ul { margin:4px 0 0 18px; padding:0; }
        .success-box { background:#eef3ec; color:#5C7355; padding:10px 14px; border-radius:12px; margin-bottom:16px; font-size:.85rem; }
        .row-2 { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
        .form-group { margin-bottom:15px; }
        label { display:block; margin-bottom:6px; font-size:.8rem; font-weight:500; color:var(--text-dark); }
        input[type=text], input[type=email], input[type=password], input[type=date], input[type=tel] { width:100%; padding:11px 13px; border:1px solid var(--border); border-radius:12px; font-size:.88rem; font-family:inherit; background:#FBF3F0; color:var(--text-dark); }
        input:focus { outline:none; border-color:var(--maroon); }
        input:-webkit-autofill { -webkit-text-fill-color:var(--text-dark); -webkit-box-shadow:0 0 0px 1000px #FBF3F0 inset; transition:background-color 5000s ease-in-out 0s; }
        .email-row { display:flex; gap:8px; }
        .email-row input { flex:1; }
        .verify-btn { padding:0 16px; border-radius:12px; border:1.5px solid var(--maroon); background:#fff; color:var(--maroon); font-size:.82rem; font-weight:600; cursor:pointer; white-space:nowrap; }
        .verify-btn:hover { background:#FBF3F0; }
        .verify-btn.verified { background:#6C8A63; border-color:#6C8A63; color:#fff; cursor:default; }
        .verify-note { font-size:.74rem; color:var(--text-muted); margin-top:5px; }
        .btn-row { display:flex; gap:10px; margin-top:22px; }
        button.submit-btn { flex:1; padding:13px; border-radius:24px; border:none; font-weight:600; font-size:.86rem; font-family:inherit; cursor:pointer; }
        button.buyer-btn { background:var(--maroon-dark); color:#fff; }
        button.buyer-btn:hover { background:#22102a; }
        button.seller-btn { background:#fff; color:var(--maroon); border:1.5px solid var(--maroon) !important; }
        button.seller-btn:hover { background:#FBF3F0; }
        .login-link { text-align:center; margin-top:20px; font-size:.85rem; color:var(--text-muted); }
        .login-link a { color:var(--maroon); font-weight:600; text-decoration:none; }
    </style>
</head>
<body>
<div class="card">
    <div class="brand">LUM<span class="o-accent">O</span>RA</div>
    <p class="subtitle">Create your account</p>

    @if (session('flash_success'))
        <div class="success-box">{{ session('flash_success') }}</div>
    @endif

    @if ($errors->any())
        <div class="error-box">
            <ul>@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul>
        </div>
    @endif

    <form method="POST" action="{{ route('register') }}" id="registerForm">
        @csrf
        <div class="row-2">
            <div class="form-group"><label>First Name</label><input type="text" name="first_name" value="{{ old('first_name') }}" required></div>
            <div class="form-group"><label>Last Name</label><input type="text" name="last_name" value="{{ old('last_name') }}" required></div>
        </div>
        <div class="form-group"><label>Contact Number</label><input type="tel" name="contact_number" value="{{ old('contact_number') }}" placeholder="09XX XXX XXXX" required></div>
        <div class="form-group"><label>Date of Birth</label><input type="date" name="date_of_birth" value="{{ old('date_of_birth') }}" required></div>
        <div class="form-group">
            <label>Email</label>
            <div class="email-row">
                <input type="email" name="email" id="email" value="{{ old('email') }}" required>
                <button type="button" class="verify-btn" id="verifyBtn" onclick="verifyEmail()">Verify</button>
            </div>
            <div class="verify-note" id="verifyNote"></div>
        </div>
        <div class="row-2">
            <div class="form-group"><label>Password</label><input type="password" name="password" required minlength="8"></div>
            <div class="form-group"><label>Confirm Password</label><input type="password" name="password_confirmation" required minlength="8"></div>
        </div>
        <div class="form-group">
            <label>Business / Shop Name <span style="color:#A08D96;font-weight:400;">(only needed if signing up as a seller)</span></label>
            <input type="text" name="business_name" id="business_name" value="{{ old('business_name') }}">
        </div>
        <div class="btn-row">
            <button type="submit" name="signup_type" value="buyer" class="submit-btn buyer-btn">Sign Up</button>
            <button type="submit" name="signup_type" value="seller" class="submit-btn seller-btn">Sign Up as Seller</button>
        </div>
    </form>
    <div class="login-link">Already have an account? <a href="{{ route('login') }}">Log in</a></div>
</div>
<script>
function verifyEmail() {
    const email = document.getElementById('email').value;
    const btn = document.getElementById('verifyBtn');
    const note = document.getElementById('verifyNote');
    if (!email || !email.includes('@')) { note.textContent = 'Enter a valid email first.'; note.style.color = '#b8451f'; return; }
    btn.textContent = 'Verified ✓';
    btn.classList.add('verified');
    note.textContent = 'Email marked as verified for this session.';
    note.style.color = '#4d6b44';
}
document.querySelectorAll('button[name="signup_type"]').forEach(function(btn) {
    btn.addEventListener('click', function() {
        document.getElementById('business_name').required = (this.value === 'seller');
    });
});
</script>
</body>
</html>
