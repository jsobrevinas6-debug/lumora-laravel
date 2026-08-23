<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lumora | Application Pending</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --maroon:#4A1942; --maroon-dark:#2E1330; --coral:#E2582E; --border:#EFDCD4; --text-dark:#2B1826; --text-muted:#A08D96; }
        * { box-sizing:border-box; margin:0; padding:0; }
        body { font-family:'Work Sans',sans-serif; color:var(--text-dark); min-height:100vh; display:flex; align-items:center; justify-content:center; padding:40px 16px; background: radial-gradient(circle at 15% 15%,rgba(232,196,196,.55),transparent 45%), radial-gradient(circle at 85% 20%,rgba(245,220,210,.6),transparent 50%), linear-gradient(135deg,#F7E6E2 0%,#F2D9D6 30%,#E9CBCE 55%,#D8B9C4 75%,#C7A8BB 100%); }
        .card { background:rgba(255,252,250,.95); padding:48px 40px; border-radius:26px; box-shadow:0 20px 50px rgba(74,25,66,.18); width:460px; max-width:100%; text-align:center; }
        .brand { font-family:'Fraunces',serif; font-size:1.7rem; font-weight:600; letter-spacing:3px; margin-bottom:20px; color:var(--maroon); }
        .brand .o-accent { color:var(--coral); }
        .icon { font-size:40px; margin-bottom:14px; }
        h1 { font-size:1.2rem; font-weight:700; margin-bottom:10px; }
        p { color:var(--text-muted); font-size:.88rem; line-height:1.6; margin-bottom:24px; }
        .btn { display:inline-block; padding:12px 26px; border-radius:24px; background:var(--maroon-dark); color:#fff; text-decoration:none; font-weight:600; font-size:.85rem; }
        .btn:hover { background:#22102a; }
    </style>
</head>
<body>
<div class="card">
    <div class="brand">LUM<span class="o-accent">O</span>RA</div>
    <div class="icon">⏳</div>
    <h1>Your seller application is under review</h1>
    <p>
        Thanks for signing up! Our team is reviewing your business details and documents.
        You'll receive an email once your application has been approved — then you can start listing products.
        In the meantime, feel free to browse and shop as a regular buyer.
    </p>
    <a href="{{ route('shop.index') }}" class="btn">Continue to Lumora</a>
</div>
</body>
</html>