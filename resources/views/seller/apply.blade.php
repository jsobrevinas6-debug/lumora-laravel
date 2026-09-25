<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lumora | Apply as Seller</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root{--primary:#3B1E34;--accent:#C98F72;--border:#EAE3DD;--card:#FFFDFC;--muted:#8B7B78;--text:#34282d;--bg:#FBF3F0}
        *{box-sizing:border-box}
        body{margin:0;min-height:100vh;background:linear-gradient(160deg,#fbefea 0%,#f3d8de 62%,#fff8f4 100%);color:var(--text);font-family:'Inter',sans-serif}
        .topbar{position:sticky;top:0;z-index:10;background:rgba(255,253,252,.92);border-bottom:1px solid var(--border);backdrop-filter:blur(8px)}
        .topbar-inner{max-width:1120px;margin:0 auto;padding:15px 24px;display:flex;align-items:center;justify-content:space-between;gap:18px}
        .brand{font-family:'Playfair Display',serif;font-size:28px;letter-spacing:.28em;text-transform:uppercase;color:var(--primary);text-decoration:none}
        .brand span{color:var(--accent)}
        .back-link{display:inline-flex;align-items:center;gap:7px;color:var(--primary);font-size:13px;font-weight:700;text-decoration:none}
        .page{max-width:860px;margin:0 auto;padding:58px 24px 80px}
        .panel{border:1px solid var(--border);border-radius:18px;background:var(--card);padding:32px;box-shadow:0 18px 42px rgba(59,30,52,.11)}
        .eyebrow{margin:0 0 10px;color:var(--accent);font-size:12px;font-weight:800;letter-spacing:.17em;text-transform:uppercase}
        h1{margin:0;color:var(--primary);font-family:'Playfair Display',serif;font-size:42px;line-height:1.05}
        .intro{max-width:620px;margin:14px 0 26px;color:var(--muted);font-size:15px;line-height:1.7}
        .field{margin-top:18px}
        label{display:block;margin-bottom:8px;color:var(--primary);font-size:13px;font-weight:700}
        input,textarea{width:100%;border:1px solid var(--border);border-radius:12px;background:#fff;padding:12px 14px;color:var(--text);font:inherit;outline:none;transition:border-color .15s ease,box-shadow .15s ease}
        textarea{min-height:132px;resize:vertical}
        input:focus,textarea:focus{border-color:var(--accent);box-shadow:0 0 0 3px rgba(201,143,114,.18)}
        .hint{margin:7px 0 0;color:var(--muted);font-size:12px;line-height:1.5}
        .error{display:block;margin-top:7px;color:#a84d39;font-size:13px}
        .actions{display:flex;align-items:center;gap:12px;margin-top:26px;flex-wrap:wrap}
        .btn{min-height:44px;display:inline-flex;align-items:center;justify-content:center;border-radius:999px;padding:0 22px;font-size:14px;font-weight:800;text-decoration:none;cursor:pointer}
        .btn-primary{border:1px solid var(--primary);background:var(--primary);color:#fff}
        .btn-secondary{border:1px solid var(--border);background:#fff;color:var(--primary)}
        @media(max-width:640px){.page{padding-top:36px}.panel{padding:24px 20px}h1{font-size:34px}.brand{font-size:23px}}
    </style>
</head>
<body>
    <header class="topbar">
        <div class="topbar-inner">
            <a href="{{ route('home') }}" class="brand">Lumo<span>ra</span></a>
            <a href="{{ route('shop.index') }}" class="back-link">Back to shop</a>
        </div>
    </header>

    <main class="page">
        <section class="panel">
            <p class="eyebrow">Seller Application</p>
            <h1>Apply as Seller</h1>
            <p class="intro">Tell the Lumora team about the shop you want to open. Your buyer account stays active while your application is reviewed.</p>

            <form method="POST" action="{{ route('seller.apply.store') }}">
                @csrf

                <div class="field">
                    <label for="business_name">Business Name</label>
                    <input id="business_name" name="business_name" value="{{ old('business_name') }}" maxlength="255" required>
                    @error('business_name')<span class="error">{{ $message }}</span>@enderror
                </div>

                <div class="field">
                    <label for="reason">Why do you want to sell on Lumora?</label>
                    <textarea id="reason" name="reason" maxlength="2000" placeholder="Share the products you plan to offer and anything the admin should know.">{{ old('reason') }}</textarea>
                    <p class="hint">Submitting this does not immediately make you a seller. Admin approval is still required.</p>
                    @error('reason')<span class="error">{{ $message }}</span>@enderror
                </div>

                <div class="actions">
                    <button type="submit" class="btn btn-primary">Submit Application</button>
                    <a href="{{ route('shop.index') }}" class="btn btn-secondary">Cancel</a>
                </div>
            </form>
        </section>
    </main>
</body>
</html>
