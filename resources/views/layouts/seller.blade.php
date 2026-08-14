<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lumora Seller | @yield('title')</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root { --bg:#FBF1EC; --card-bg:#FFFFFF; --sidebar-bg:#FFFFFF; --maroon:#5B1A35; --maroon-dark:#45132A; --coral:#E8674A; --terra-1:#D98A5E; --terra-2:#B85C3B; --sage-1:#7C9473; --sage-2:#5C7355; --text-dark:#2B1C22; --text-muted:#8B7A80; --border:#F0E2DA; --radius:18px; }
        * { box-sizing:border-box; margin:0; padding:0; }
        body { font-family:'Poppins',sans-serif; background:var(--bg); color:var(--text-dark); display:flex; min-height:100vh; }
        .sidebar { width:230px; background:var(--sidebar-bg); border-right:1px solid var(--border); padding:28px 18px; display:flex; flex-direction:column; gap:6px; position:fixed; top:0; left:0; height:100vh; }
        .brand { display:flex; align-items:center; gap:10px; font-size:22px; font-weight:800; letter-spacing:.5px; margin-bottom:36px; background:linear-gradient(90deg,var(--maroon),var(--coral)); -webkit-background-clip:text; -webkit-text-fill-color:transparent; }
        .brand-icon { width:30px; height:30px; border-radius:8px; background:linear-gradient(135deg,var(--maroon),var(--coral)); display:flex; align-items:center; justify-content:center; color:#fff; font-size:14px; -webkit-text-fill-color:#fff; }
        .nav-link { display:flex; align-items:center; gap:10px; padding:11px 14px; border-radius:12px; color:var(--text-muted); text-decoration:none; font-size:14.5px; font-weight:500; transition:all .18s ease; }
        .nav-link:hover { background:var(--bg); color:var(--maroon); }
        .nav-link.active { background:var(--maroon); color:#fff; font-weight:600; }
        .logout-form { margin-top:auto; }
        .logout-btn { width:100%; padding:11px 14px; border-radius:12px; border:1px solid var(--border); background:transparent; color:var(--text-muted); font-weight:500; font-size:14px; cursor:pointer; transition:all .18s ease; font-family:inherit; }
        .logout-btn:hover { border-color:var(--coral); color:var(--coral); }
        .main { flex:1; padding:34px 40px; margin-left:230px; }
        .topbar { display:flex; justify-content:space-between; align-items:center; margin-bottom:32px; }
        .topbar h1 { font-size:28px; font-weight:800; }
        .seller-pill { background:#fff; border:1px solid var(--border); padding:8px 16px; border-radius:999px; font-size:13.5px; font-weight:600; color:var(--maroon); }
        .stats-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:22px; margin-bottom:22px; }
        .stat-card { background:var(--card-bg); border-radius:var(--radius); padding:24px; display:flex; flex-direction:column; gap:14px; border:1px solid var(--border); box-shadow:0 4px 18px rgba(91,26,53,.04); }
        .stat-icon { width:44px; height:44px; border-radius:12px; display:flex; align-items:center; justify-content:center; color:#fff; font-size:18px; }
        .icon-sales { background:linear-gradient(135deg,var(--terra-1),var(--terra-2)); }
        .icon-orders { background:linear-gradient(135deg,var(--maroon),var(--maroon-dark)); }
        .icon-products { background:linear-gradient(135deg,var(--sage-1),var(--sage-2)); }
        .stat-label { font-size:13.5px; color:var(--text-muted); font-weight:500; }
        .stat-value { font-size:26px; font-weight:800; }
        .panel { background:var(--card-bg); border-radius:var(--radius); border:1px solid var(--border); padding:24px; box-shadow:0 4px 18px rgba(91,26,53,.04); }
        .panel h2 { font-size:18px; font-weight:800; margin-bottom:16px; }
        table { width:100%; border-collapse:collapse; }
        th, td { text-align:left; padding:10px 8px; border-bottom:1px solid var(--border); font-size:.9rem; }
        th { color:var(--text-muted); font-weight:600; }
        tr:hover td { background-color:var(--bg); }
        .stock-badge { display:inline-block; padding:3px 10px; border-radius:20px; font-size:.75rem; color:#fff; background:var(--terra-2); }

        /* Products page additions */
        .products-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:22px; }
        .product-tile { background:var(--card-bg); border-radius:var(--radius); border:1px solid var(--border); overflow:hidden; box-shadow:0 4px 18px rgba(91,26,53,.04); display:flex; flex-direction:column; }
        .add-product-tile { display:flex; flex-direction:column; align-items:center; justify-content:center; gap:12px; background:transparent; border:2px dashed var(--border); border-radius:var(--radius); height:230px; text-decoration:none; color:var(--text-muted); transition:all .18s ease; }
        .add-product-tile:hover { border-color:var(--maroon); color:var(--maroon); background:rgba(91,26,53,.03); }
        .add-icon { width:52px; height:52px; border-radius:50%; background:linear-gradient(135deg,var(--maroon),var(--coral)); color:#fff; font-size:26px; font-weight:700; display:flex; align-items:center; justify-content:center; }
        .add-label { font-size:14.5px; font-weight:600; }
        .product-image { height:130px; background:var(--bg); display:flex; align-items:center; justify-content:center; color:var(--text-muted); font-size:13px; overflow:hidden; }
        .product-image img { width:100%; height:100%; object-fit:cover; }
        .product-body { padding:16px; display:flex; flex-direction:column; gap:6px; flex:1; }
        .product-name { font-size:15px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
        .product-price { font-size:13.5px; color:var(--text-muted); font-weight:500; }
        .product-stock { font-size:13.5px; margin-top:2px; }
        .product-stock .count { font-weight:700; }
        .product-stock .low { color:var(--coral); }
        .stock-form { margin-top:auto; padding-top:10px; display:flex; gap:8px; }
        .stock-input { width:60px; border:1px solid var(--border); border-radius:8px; padding:6px 8px; font-size:13px; font-family:inherit; }
        .edit-stock-btn { flex:1; background:var(--maroon); color:#fff; border:none; border-radius:8px; font-size:13px; font-weight:600; padding:8px 10px; cursor:pointer; font-family:inherit; transition:background .18s ease; }
        .edit-stock-btn:hover { background:var(--maroon-dark); }
        .alert-success { background:#eaf3e8; color:var(--sage-2); border:1px solid var(--sage-1); padding:12px 16px; border-radius:12px; font-size:13.5px; margin-bottom:20px; }
        @media (max-width:1100px) { .products-grid { grid-template-columns:repeat(2,1fr); } }
        @media (max-width:900px) { .stats-grid { grid-template-columns:1fr; } }
        @media (max-width:600px) { .products-grid { grid-template-columns:1fr; } }
        /* Payouts page additions */
        .alert-error { background:#fbeaea; color:#a33; border:1px solid #e0a5a5; padding:12px 16px; border-radius:12px; font-size:13.5px; margin-bottom:20px; }
        .earnings-actions { display:flex; gap:12px; margin:22px 0; }
        .btn-outline { padding:11px 20px; border-radius:12px; border:1px solid var(--maroon); background:transparent; color:var(--maroon); font-weight:600; font-size:14px; cursor:pointer; font-family:inherit; transition:all .18s ease; }
        .btn-outline:hover { background:var(--maroon); color:#fff; }
        .btn-solid { padding:11px 20px; border-radius:12px; border:none; background:var(--maroon); color:#fff; font-weight:600; font-size:14px; cursor:pointer; font-family:inherit; transition:background .18s ease; }
        .btn-solid:hover { background:var(--maroon-dark); }
        .method-badge { display:inline-flex; align-items:center; gap:8px; padding:6px 14px; border-radius:999px; font-size:13px; font-weight:700; color:#fff; }
        .badge-gcash { background:#007DFE; }
        .badge-paymaya { background:#00B14F; }
        .badge-bank { background:#5B1A35; }
        .current-method-card { display:flex; align-items:center; justify-content:space-between; background:var(--card-bg); border:1px solid var(--border); border-radius:14px; padding:16px 20px; margin-bottom:22px; }
        .status-pill { display:inline-block; padding:4px 12px; border-radius:999px; font-size:12px; font-weight:700; }
        .status-pending { background:#fdf0dc; color:#a6701c; }
        .status-approved { background:#e2eef8; color:#2261a8; }
        .status-paid { background:#eaf3e8; color:#42713a; }
        .status-rejected { background:#fbeaea; color:#a33; }
        .modal-overlay { display:none; position:fixed; inset:0; background:rgba(43,28,34,.5); align-items:center; justify-content:center; z-index:50; }
        .modal-box { background:#fff; border-radius:18px; padding:28px; width:420px; max-width:90%; }
        .modal-box h2 { font-size:18px; font-weight:800; margin-bottom:18px; }
        .modal-form { display:flex; flex-direction:column; gap:12px; }
        .modal-form input, .modal-form select { border:1px solid var(--border); border-radius:8px; padding:10px 12px; font-size:14px; font-family:inherit; width:100%; }
        .modal-btn-row { display:flex; gap:10px; margin-top:8px; }
        .modal-btn-row button { flex:1; padding:10px; border-radius:8px; font-family:inherit; cursor:pointer; }
        .btn-cancel { border:1px solid var(--border); background:transparent; }
    </style>
    @stack('styles')
</head>
<body>
<aside class="sidebar">
    <div class="brand"><span class="brand-icon">L</span> Lumora</div>
    <a href="{{ route('seller.dashboard') }}" class="nav-link {{ request()->routeIs('seller.dashboard') ? 'active' : '' }}">Dashboard</a>
    <a href="{{ route('seller.products.index') }}" class="nav-link {{ request()->routeIs('seller.products.*') ? 'active' : '' }}">My Products</a>
    <a href="{{ route('seller.payouts.index') }}" class="nav-link {{ request()->routeIs('seller.payouts.*') ? 'active' : '' }}">Payouts / Earnings</a>
    <a href="{{ route('seller.profile.index') }}" class="nav-link {{ request()->routeIs('seller.profile.*') ? 'active' : '' }}">Profile / Settings</a>
    <form method="POST" action="{{ route('logout') }}" class="logout-form">
        @csrf
        <button type="submit" class="logout-btn">Logout</button>
    </form>
</aside>

<main class="main">
    <div class="topbar">
        <h1>@yield('title')</h1>
        <span class="seller-pill">Seller &mdash; {{ Auth::user()->name }}</span>
    </div>

    @yield('content')
</main>
</body>
</html>