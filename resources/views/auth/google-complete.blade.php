<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ config('app.name', 'Lumora') }} | Complete your account</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --plum:#351128; --rose:#b96562; --cream:#fffaf6; --paper:#fffdfb; --beige:#f7eee8; --line:#e8d8d0; --muted:#857579; --gold:#c9972b; }
        * { box-sizing:border-box; }
        body { margin:0; min-height:100vh; color:var(--plum); font-family:Inter,sans-serif; background:radial-gradient(circle at 8% 10%,#f5ddd4 0,transparent 28%),radial-gradient(circle at 92% 90%,#f4e3da 0,transparent 32%),var(--cream); }
        .shell { width:min(980px,calc(100% - 32px)); margin:34px auto; background:var(--paper); border:1px solid var(--line); border-radius:20px; box-shadow:0 24px 65px rgba(53,17,40,.12); overflow:hidden; }
        .top { display:flex; justify-content:space-between; align-items:center; padding:24px 34px; border-bottom:1px solid var(--line); }
        .brand { font:600 25px 'Playfair Display',serif; letter-spacing:4px; }
        .brand span { color:var(--rose); }
        .google-status { display:flex; align-items:center; gap:10px; color:var(--muted); font-size:12px; }
        .google-status img { width:32px; height:32px; border-radius:50%; object-fit:cover; border:1px solid var(--line); }
        .content { padding:42px clamp(24px,6vw,76px) 54px; }
        h1 { margin:0; text-align:center; font:600 clamp(33px,5vw,52px)/1.08 'Playfair Display',serif; }
        .intro { max-width:590px; margin:14px auto 30px; color:var(--muted); text-align:center; font-size:14px; line-height:1.7; }
        .notice { display:flex; gap:12px; align-items:flex-start; max-width:700px; margin:0 auto 26px; padding:14px 16px; color:#65474a; background:var(--beige); border:1px solid var(--line); border-radius:12px; font-size:13px; line-height:1.55; }
        .notice strong { display:block; color:var(--plum); margin-bottom:2px; }
        .notice-icon { color:var(--gold); font-size:19px; line-height:1; }
        .error-box { max-width:700px; margin:0 auto 18px; padding:12px 14px; color:#9c3d38; background:#fff0ed; border:1px solid #f0cfc8; border-radius:10px; font-size:13px; }
        form { max-width:700px; margin:0 auto; }
        .section-title { margin:26px 0 14px; padding-top:22px; border-top:1px solid var(--line); font:600 20px 'Playfair Display',serif; }
        .grid { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:16px; }
        .field { margin-bottom:3px; }
        label { display:block; margin-bottom:7px; font-size:12px; font-weight:700; }
        input, select { width:100%; height:48px; padding:0 13px; color:var(--plum); background:#fffaf7; border:1px solid var(--line); border-radius:9px; outline:none; font:inherit; font-size:13px; }
        input:focus, select:focus { border-color:var(--rose); box-shadow:0 0 0 3px rgba(185,101,98,.12); }
        input[readonly] { color:#6f6264; background:#f8f0ec; }
        .radio-row { display:flex; align-items:center; gap:18px; height:48px; }
        .radio-row label { display:flex; align-items:center; gap:7px; margin:0; font-weight:500; }
        .radio-row input { width:auto; height:auto; accent-color:var(--rose); }
        .actions { display:flex; gap:12px; margin-top:30px; }
        .actions button, .actions a { display:inline-flex; justify-content:center; align-items:center; min-height:49px; border-radius:9px; padding:0 22px; text-decoration:none; font-weight:700; font-size:13px; }
        .actions button { flex:1; border:1px solid var(--rose); color:var(--plum); background:var(--cream); cursor:pointer; }
        .actions button:hover { color:var(--plum); background:#fff; }
        .actions a { border:1px solid var(--line); color:var(--muted); background:#fff; }
        .actions a:hover { color:var(--plum); border-color:var(--rose); }
        .footnote { margin:20px auto 0; max-width:700px; color:var(--muted); text-align:center; font-size:11px; line-height:1.6; }
        @media (max-width:650px) { .shell { width:calc(100% - 20px); margin:10px auto; } .top { padding:19px 20px; } .google-status span { display:none; } .content { padding:32px 20px 38px; } .grid { grid-template-columns:1fr; gap:13px; } .actions { flex-direction:column-reverse; } }
    </style>
</head>
<body>
    <main class="shell">
        <header class="top">
            <div class="brand">LUM<span>O</span>RA</div>
            <div class="google-status">
                @if (!empty($google['avatar']))
                    <img src="{{ $google['avatar'] }}" alt="">
                @endif
                <span>Signed in with Google</span>
            </div>
        </header>

        <section class="content">
            <h1>Complete your account</h1>
            <p class="intro">Welcome to Lumora. Your Google account is verified. Add the remaining details below so we can prepare your buyer profile and future delivery information.</p>

            <div class="notice">
                <div class="notice-icon">✦</div>
                <div><strong>Your Google email is verified</strong>{{ $google['email'] }}<br>You do not need to create or remember another password.</div>
            </div>

            @if ($errors->any())
                <div class="error-box" role="alert">
                    <strong>Please check the following:</strong>
                    <ul style="margin:6px 0 0 18px;padding:0;">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul>
                </div>
            @endif

            <form method="POST" action="{{ route('google.complete.submit') }}">
                @csrf
                <div class="section-title">Personal information</div>
                <div class="grid">
                    <div class="field"><label for="first_name">First name</label><input id="first_name" name="first_name" value="{{ old('first_name', $google['first_name'] ?? '') }}" required></div>
                    <div class="field"><label for="last_name">Last name</label><input id="last_name" name="last_name" value="{{ old('last_name', $google['last_name'] ?? '') }}" required></div>
                    <div class="field"><label for="middle_initial">Middle initial <span style="color:var(--muted);font-weight:400;">(optional)</span></label><input id="middle_initial" name="middle_initial" value="{{ old('middle_initial') }}" maxlength="4"></div>
                    <div class="field"><label>Sex</label><div class="radio-row"><label><input type="radio" name="sex" value="female" @checked(old('sex') === 'female') required> Female</label><label><input type="radio" name="sex" value="male" @checked(old('sex') === 'male')> Male</label></div></div>
                    <div class="field"><label for="contact_number">Contact number</label><input id="contact_number" type="tel" name="contact_number" value="{{ old('contact_number') }}" placeholder="09XX XXX XXXX" required></div>
                    <div class="field"><label for="date_of_birth">Date of birth</label><input id="date_of_birth" type="date" name="date_of_birth" value="{{ old('date_of_birth') }}" required></div>
                    <div class="field"><label>Email</label><input value="{{ $google['email'] }}" readonly aria-readonly="true"><small style="display:block;margin-top:6px;color:#5f7a58;font-size:11px;">Verified by Google</small></div>
                </div>

                <div class="section-title">Delivery address</div>
                <div class="grid">
                    <div class="field"><label for="province">Province</label><input id="province" name="province" value="{{ old('province') }}" required></div>
                    <div class="field"><label for="municipality">Municipality</label><input id="municipality" name="municipality" value="{{ old('municipality') }}" required></div>
                    <div class="field"><label for="barangay">Barangay</label><input id="barangay" name="barangay" value="{{ old('barangay') }}" required></div>
                    <div class="field"><label for="street">Street <span style="color:var(--muted);font-weight:400;">(optional)</span></label><input id="street" name="street" value="{{ old('street') }}"></div>
                    <div class="field"><label for="house_number">House / unit number <span style="color:var(--muted);font-weight:400;">(optional)</span></label><input id="house_number" name="house_number" value="{{ old('house_number') }}"></div>
                </div>

                <div class="actions">
                    <a href="{{ route('login') }}">Cancel</a>
                    <button type="submit">Create my Lumora account</button>
                </div>
            </form>
            <p class="footnote">Your account will be created as a buyer. You can update these details later in your Lumora profile settings.</p>
        </section>
    </main>
</body>
</html>
