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
        :root{--primary:#3B1E34;--accent:#C98F72;--border:#EAE3DD;--card:#FFFDFC;--muted:#8B7B78;--text:#2F2528;--bg:#F7F1EC}
        *{box-sizing:border-box}
        body{margin:0;min-height:100vh;background:var(--bg);color:var(--text);font-family:'Inter',sans-serif}
        .topbar{position:sticky;top:0;z-index:10;background:rgba(255,253,252,.94);border-bottom:1px solid var(--border);backdrop-filter:blur(8px)}
        .topbar-inner{max-width:1120px;margin:0 auto;padding:15px 24px;display:flex;align-items:center;justify-content:space-between;gap:18px}
        .brand{font-family:'Playfair Display',serif;font-size:28px;letter-spacing:.28em;text-transform:uppercase;color:var(--primary);text-decoration:none}
        .brand span{color:var(--accent)}
        .back-link{display:inline-flex;align-items:center;gap:7px;color:var(--primary);font-size:13px;font-weight:700;text-decoration:none}
        .page{max-width:980px;margin:0 auto;padding:50px 24px 80px}
        .header{margin-bottom:24px}
        .eyebrow{margin:0 0 10px;color:var(--accent);font-size:12px;font-weight:800;letter-spacing:.17em;text-transform:uppercase}
        h1{margin:0;color:var(--primary);font-family:'Playfair Display',serif;font-size:46px;line-height:1.05}
        .intro{max-width:660px;margin:14px 0 0;color:var(--muted);font-size:15px;line-height:1.7}
        .application-form{display:grid;gap:18px}
        .section-card{border:1px solid var(--border);border-radius:18px;background:var(--card);padding:26px;box-shadow:0 14px 34px rgba(59,30,52,.08)}
        .section-title{margin:0 0 18px;color:var(--primary);font-size:13px;font-weight:800;letter-spacing:.14em;text-transform:uppercase}
        .grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}
        .form-group{min-width:0}
        .form-group.full{grid-column:1/-1}
        label{display:block;margin-bottom:8px;color:var(--primary);font-size:13px;font-weight:700}
        input,select,textarea{width:100%;min-height:46px;border:1px solid var(--border);border-radius:12px;background:#fff;padding:11px 13px;color:var(--text);font:inherit;outline:none;transition:border-color .15s ease,box-shadow .15s ease}
        textarea{min-height:128px;resize:vertical}
        input:focus,select:focus,textarea:focus{border-color:var(--accent);box-shadow:0 0 0 3px rgba(201,143,114,.18)}
        input[readonly]{background:#F3E9E6;color:var(--muted)}
        input[type="file"]{padding:10px;background:#fff}
        .hint{margin:10px 0 0;color:var(--muted);font-size:12px;line-height:1.5}
        .field-error{display:block;margin-top:7px;color:#a84d39;font-size:13px;line-height:1.4}
        .actions{display:flex;align-items:center;gap:12px;flex-wrap:wrap}
        .btn{min-height:44px;display:inline-flex;align-items:center;justify-content:center;border-radius:999px;padding:0 22px;font-size:14px;font-weight:800;text-decoration:none;cursor:pointer}
        .btn-primary{border:1px solid var(--primary);background:var(--primary);color:#fff}
        .btn-secondary{border:1px solid var(--border);background:#fff;color:var(--primary)}
        @media(max-width:720px){.page{padding:36px 18px 64px}.section-card{padding:22px 18px}.grid{grid-template-columns:1fr}h1{font-size:36px}.brand{font-size:23px}}
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
        <header class="header">
            <p class="eyebrow">Seller Application</p>
            <h1>Apply as Seller</h1>
            <p class="intro">Complete your shop information below. Your buyer account will remain active while your application is reviewed.</p>
        </header>

        <form method="POST" action="{{ route('seller.apply.store') }}" enctype="multipart/form-data" class="application-form">
            @csrf

            <section class="section-card">
                <h2 class="section-title">Personal Information</h2>
                <div class="grid">
                    <div class="form-group">
                        <label for="name">Full Name</label>
                        <input id="name" value="{{ old('name', $user->name) }}" readonly>
                    </div>
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input id="email" value="{{ old('email', $user->email) }}" readonly>
                    </div>
                    <div class="form-group">
                        <label for="contact_number">Contact Number</label>
                        <input id="contact_number" value="{{ old('contact_number', $user->contact_number ?: 'Not provided') }}" readonly>
                    </div>
                    <div class="form-group">
                        <label for="provider">Account Type</label>
                        <input id="provider" value="Google buyer account" readonly>
                    </div>
                </div>
            </section>

            <section class="section-card">
                <h2 class="section-title">Business Information</h2>
                <div class="grid">
                    @include('partials.seller-application-fields', ['includeReason' => false])
                </div>
                <p class="hint">These are the same seller details required by the Sign Up as Seller flow.</p>
            </section>

            <section class="section-card">
                <h2 class="section-title">Business Address</h2>
                <div class="grid">
                    <div class="form-group">
                        <label for="province">Province</label>
                        <input id="province" value="{{ old('province', $user->province ?: 'Not provided') }}" readonly>
                    </div>
                    <div class="form-group">
                        <label for="municipality">Municipality</label>
                        <input id="municipality" value="{{ old('municipality', $user->municipality ?: 'Not provided') }}" readonly>
                    </div>
                    <div class="form-group">
                        <label for="barangay">Barangay</label>
                        <input id="barangay" value="{{ old('barangay', $user->barangay ?: 'Not provided') }}" readonly>
                    </div>
                    <div class="form-group">
                        <label for="street">Street</label>
                        <input id="street" value="{{ old('street', $user->street ?: 'Not provided') }}" readonly>
                    </div>
                    <div class="form-group">
                        <label for="house_number">House / Unit No.</label>
                        <input id="house_number" value="{{ old('house_number', $user->house_number ?: 'Not provided') }}" readonly>
                    </div>
                </div>
                <p class="hint">Update your shipping address from Profile if these details need to change.</p>
            </section>

            <section class="section-card">
                <h2 class="section-title">Application Details</h2>
                <div class="form-group">
                    <label for="reason">Why do you want to sell on Lumora?</label>
                    <textarea name="reason" id="reason" maxlength="2000" placeholder="Share the products you plan to offer and anything the admin should know.">{{ old('reason') }}</textarea>
                    @error('reason')<span class="field-error">{{ $message }}</span>@enderror
                </div>
                <p class="hint">Submitting this does not immediately make you a seller. Admin approval is still required.</p>
            </section>

            <div class="actions">
                <button type="submit" class="btn btn-primary">Submit Application</button>
                <a href="{{ route('shop.index') }}" class="btn btn-secondary">Cancel</a>
            </div>
        </form>
    </main>
</body>
</html>
