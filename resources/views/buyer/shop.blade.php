<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lumora | Shop</title>
    <meta name="csrf-token" content="{{ csrf_token() }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">

    <style>
        :root{
            --plum:#3D1B3D;
            --plum-light:#5A2E5A;
            --orange:#E2703A;
            --gold:#C9972B;
            --cream:#FFFDFB;
            --blush-1:#FBEFEA;
            --blush-2:#F3D8DE;
            --ink:#3A2E30;
            --muted:#8A7B7E;
            --line:#EBDDD8;
            --flow-bg:#B9827C;
            --flow-bg-deep:#A96E6B;
            --flow-text:#FFF8F4;
            --flow-line:rgba(255,248,244,.28);
            --flow-gold:#F2C98E;
        }
        *{ box-sizing:border-box; }
        body{
            margin:0;
            font-family:'Inter',sans-serif;
            color:var(--ink);
            background:linear-gradient(160deg,var(--blush-1) 0%,var(--blush-2) 55%,var(--blush-1) 100%);
            min-height:100vh;
        }
        h1,h2,h3,.wordmark{ font-family:'Playfair Display',serif; }
        a{ text-decoration:none; color:inherit; }
        button{ font-family:inherit; cursor:pointer; }

        .arch{ border-radius: 999px 999px 12px 12px; }

        /* ---------- top bar ---------- */
        .topbar{
            position:sticky; top:0; z-index:20;
            background:rgba(255,253,251,0.92);
            backdrop-filter:blur(6px);
            border-bottom:1px solid var(--line);
        }
        .topbar-inner{
            max-width:1180px; margin:0 auto;
            display:flex; align-items:center; gap:24px;
            padding:14px 24px;
        }
        .brand{ display:flex; align-items:center; gap:8px; flex-shrink:0; }
        .brand svg{ width:26px; height:26px; color:var(--orange); }
        .brand .wordmark{ font-size:22px; font-weight:700; color:var(--plum); letter-spacing:0.5px; }
        .brand .wordmark span{ color:var(--orange); }

        .search{
            flex:1; max-width:520px;
            display:flex; align-items:center; gap:8px;
            background:var(--cream); border:1px solid var(--line); border-radius:999px;
            padding:9px 16px;
        }
        .search svg{ width:16px; height:16px; color:var(--muted); flex-shrink:0; }
        .search input{
            border:none; outline:none; background:transparent; width:100%;
            font-size:14px; color:var(--ink);
        }
        .search input::placeholder{ color:var(--muted); }

        .nav-actions{ display:flex; align-items:center; gap:12px; margin-left:auto; }
        .icon-btn{
            width:38px; height:38px; border-radius:50%;
            display:flex; align-items:center; justify-content:center;
            background:var(--cream); border:1px solid var(--line); position:relative;
        }
        .icon-btn svg{ width:18px; height:18px; color:var(--plum); }
        .badge{
            position:absolute; top:-4px; right:-4px;
            background:var(--orange); color:#fff; font-size:10px; font-weight:600;
            width:16px; height:16px; border-radius:50%;
            display:flex; align-items:center; justify-content:center;
        }
        .btn{
            padding:9px 20px; border-radius:999px; font-size:14px; font-weight:600;
            border:1px solid var(--plum);
        }
        .btn-primary{ background:var(--plum); color:#fff; }
        .btn-ghost{ background:transparent; color:var(--plum); }
        .account{ display:flex; align-items:center; gap:10px; }
        .avatar{
            width:36px; height:36px; border-radius:50%; background:var(--plum);
            color:#fff; display:flex; align-items:center; justify-content:center;
            font-size:13px; font-weight:600;
        }
        .account-name{ font-size:13px; font-weight:600; color:var(--ink); }
        .logout-form button{
            background:none; border:none; color:var(--muted); font-size:12px;
            text-decoration:underline; padding:0;
        }

        /* ---------- guest banner ---------- */
        .guest-banner{ max-width:1180px; margin:16px auto 0; padding:0 24px; }
        .guest-banner-inner{
            display:flex; align-items:center; justify-content:space-between; gap:16px; flex-wrap:wrap;
            background:var(--cream); border:1px dashed var(--orange);
            border-radius:14px; padding:12px 20px;
        }
        .guest-banner-inner p{ margin:0; font-size:13px; color:var(--ink); }
        .guest-banner-inner p strong{ color:var(--plum); }
        .guest-banner-inner .links{ display:flex; gap:10px; }
        .guest-banner-inner .links a{ font-size:13px; font-weight:600; color:var(--orange); }

        /* ---------- category strip ---------- */
        .categories{
            max-width:1180px; margin:28px auto 0; padding:0 24px;
            display:flex; gap:14px; overflow-x:auto; padding-bottom:4px;
        }
        .cat-card{ flex:0 0 auto; width:104px; text-align:center; }
        .cat-icon{
            width:72px; height:72px; margin:0 auto 8px;
            background:var(--cream); border:1px solid var(--line);
            border-radius: 999px 999px 12px 12px;
            display:flex; align-items:center; justify-content:center;
        }
        .cat-icon svg{ width:28px; height:28px; color:var(--plum); }
        .cat-card span{ font-size:12px; font-weight:500; color:var(--ink); }

        /* ---------- hero ---------- */
        .hero{
            max-width:1180px; margin:32px auto 0; padding:0 24px;
            display:grid; grid-template-columns:1.1fr 1fr; gap:40px; align-items:center;
        }
        .hero-copy .eyebrow{
            font-size:12px; letter-spacing:2px; text-transform:uppercase;
            color:var(--orange); font-weight:600; margin:0 0 10px;
        }
        .hero-copy h1{ font-size:40px; color:var(--plum); margin:0 0 14px; line-height:1.2; }
        .hero-copy p{ font-size:15px; color:var(--muted); margin:0 0 24px; max-width:420px; }
        .hero-cta{
            display:inline-flex; align-items:center; gap:8px;
            background:var(--plum); color:#fff; padding:13px 26px;
            border-radius:999px; font-size:14px; font-weight:600; border:none;
        }
        .hero-visual{
            aspect-ratio:4/3;
            background:linear-gradient(150deg,var(--plum) 0%,var(--plum-light) 55%,var(--orange) 130%);
            border-radius: 999px 999px 24px 24px;
            display:flex; align-items:center; justify-content:center;
            position:relative; overflow:hidden;
        }
        .hero-visual svg{ width:64px; height:64px; color:rgba(255,255,255,0.85); }
        .hero-visual::after{
            content:"Step into something beautiful";
            position:absolute; bottom:22px; left:0; right:0; text-align:center;
            font-family:'Playfair Display',serif; font-style:italic; color:#fff; font-size:14px; opacity:0.9;
        }

        /* ---------- section heading ---------- */
        .section{ max-width:1180px; margin:48px auto 0; padding:0 24px; }
        .section-head{ margin-bottom:8px; }
        .section-head h2{ font-size:22px; color:var(--plum); margin:0; }

        /* ---------- category block within "Just for you" ---------- */
        .category-block{ margin-top:34px; }
        .category-block:first-of-type{ margin-top:22px; }
        .section-subhead{
            display:flex; align-items:baseline; justify-content:space-between; margin-bottom:16px;
        }
        .section-subhead h3{ font-size:16px; color:var(--plum); margin:0; font-weight:600; font-family:'Inter',sans-serif; }
        .section-subhead .see-all{ font-size:13px; font-weight:600; color:var(--orange); }

        /* ---------- flash deals ---------- */
        .deals-strip{ display:flex; gap:16px; overflow-x:auto; padding-bottom:8px; }
        .deal-card{
            flex:0 0 auto; width:180px; background:var(--cream);
            border:1px solid var(--line); border-radius:16px 16px 12px 12px; overflow:hidden;
        }
        .deal-thumb{ height:120px; display:flex; align-items:center; justify-content:center; position:relative; }
        .deal-thumb svg{ width:34px; height:34px; color:#fff; opacity:0.9; }
        .deal-discount{
            position:absolute; top:8px; left:8px; background:var(--orange); color:#fff;
            font-size:11px; font-weight:700; padding:3px 8px; border-radius:999px;
        }
        .deal-body{ padding:10px 12px 14px; }
        .deal-body .name{ font-size:13px; font-weight:500; margin:0 0 6px; }
        .deal-price{ display:flex; align-items:baseline; gap:6px; }
        .deal-price .now{ color:var(--orange); font-weight:700; font-size:14px; }
        .deal-price .was{ color:var(--muted); font-size:12px; text-decoration:line-through; }
        .deal-timer{ font-size:11px; color:var(--muted); margin-top:6px; }

        /* ---------- product grid ---------- */
        .grid{ display:grid; grid-template-columns:repeat(4,1fr); gap:18px; }
        .product-card{
            background:var(--cream); border:1px solid var(--line);
            border-radius:16px 16px 12px 12px; overflow:hidden; position:relative;
        }
        .wishlist-btn{
            position:absolute; top:10px; right:10px; z-index:2;
            width:30px; height:30px; border-radius:50%; background:rgba(255,255,255,0.85);
            display:flex; align-items:center; justify-content:center; border:none;
        }
        .wishlist-btn svg{ width:15px; height:15px; color:var(--plum); }
        .product-thumb{ height:150px; display:flex; align-items:center; justify-content:center; }
        .product-thumb svg{ width:32px; height:32px; color:#fff; opacity:0.9; }
        .product-body{ padding:12px 14px 16px; }
        .product-body .name{ font-size:13px; font-weight:500; margin:0 0 6px; line-height:1.4; }
        .product-price{ color:var(--plum); font-weight:700; font-size:15px; margin:0 0 6px; }
        .product-rating{ display:flex; align-items:center; gap:4px; font-size:12px; color:var(--muted); }
        .product-rating svg{ width:12px; height:12px; color:var(--gold); }

        /* ---------- footer ---------- */
        footer{ margin-top:64px; border-top:1px solid var(--line); padding:32px 24px; text-align:center; }
        footer p{ margin:4px 0; font-size:12px; color:var(--muted); }
        footer .wordmark{ font-size:18px; color:var(--plum); }

        @media (max-width:900px){
            .hero{ grid-template-columns:1fr; }
            .grid{ grid-template-columns:repeat(2,1fr); }
            .search{ display:none; }
        }

        /* ---------- account dropdown ---------- */
        .account-menu-wrap { position:relative; }
        .account-trigger { display:flex; align-items:center; gap:10px; border:0; background:transparent; padding:0; color:inherit; cursor:pointer; text-align:left; }
        .account-trigger:focus-visible { outline:2px solid var(--orange); outline-offset:4px; border-radius:8px; }
        .account-chevron { width:13px; height:13px; color:var(--muted); transition:transform .18s ease; }
        .account-menu-wrap.open .account-chevron { transform:rotate(180deg); }
        .account-dropdown { display:none; position:absolute; top:calc(100% + 12px); right:0; width:258px; padding:8px; background:var(--cream); border:1px solid var(--line); border-radius:16px; box-shadow:0 14px 34px rgba(61,27,61,.16); z-index:50; }
        .account-menu-wrap.open .account-dropdown { display:block; }
        .account-dropdown-head { display:flex; align-items:center; gap:10px; padding:10px; border-bottom:1px solid var(--line); margin-bottom:6px; }
        .account-dropdown-head .avatar { flex:0 0 auto; width:42px; height:42px; font-size:15px; }
        .account-dropdown-name { color:var(--ink); font-size:13px; font-weight:600; }
        .account-mode { display:flex; align-items:center; gap:5px; margin-top:3px; color:var(--muted); font-size:11px; }
        .buyer-badge { padding:2px 7px; border-radius:999px; background:#f3d8de; color:var(--plum); font-size:10px; font-weight:700; }
        .account-menu-link, .account-menu-button { width:100%; display:flex; align-items:center; gap:10px; padding:10px; border:0; border-radius:10px; background:transparent; color:var(--ink); font:inherit; font-size:13px; text-align:left; text-decoration:none; cursor:pointer; }
        .account-menu-link:hover, .account-menu-button:hover { background:var(--blush-1); color:var(--plum); }
        .account-menu-button.switch-seller { border:1px solid var(--plum); color:var(--plum); margin:4px 0; }
        .account-menu-button.switch-seller:hover { background:var(--plum); color:#fff; }
        .account-menu-icon { width:18px; text-align:center; font-size:16px; }
        .account-menu-divider { height:1px; margin:6px 2px; background:var(--line); }
        .account-menu-button.logout-menu { color:var(--muted); }
        @media (max-width:900px) { .account-dropdown { right:-4px; } }

        /* ---------- hidden vertical collection menu ---------- */
        .flow-menu-trigger { width:38px; height:38px; border:1px solid var(--line); border-radius:50%; background:var(--cream); color:var(--plum); display:flex; align-items:center; justify-content:center; padding:0; cursor:pointer; transition:all .18s ease; }
        .flow-menu-trigger:hover, .flow-menu-trigger[aria-expanded="true"] { background:var(--plum); color:#fff; }
        .flow-menu-trigger svg { width:18px; height:18px; }
        .flow-menu-trigger.left-menu-trigger { display:flex; flex:0 0 auto; }
        .flow-menu-trigger.right-menu-trigger { display:none; }
        .flow-menu-trigger.left-menu-trigger:hover, .flow-menu-trigger.left-menu-trigger[aria-expanded="true"] { background:var(--plum); color:#fff; }
        .flow-menu-item.has-image::before { background-color:#FFF8F4; background-image:linear-gradient(90deg, rgba(255,253,251,.88), rgba(255,253,251,.12)), var(--category-image); background-size:auto 100%, 220px 100%; background-position:left center, right center; background-repeat:no-repeat; }
        .flow-menu-item.has-image:hover::before { background-position:left center, right center; }
        .flow-menu-subitem.has-image { position:relative; overflow:hidden; isolation:isolate; }
        .flow-menu-subitem.has-image::before { content:""; position:absolute; inset:0; z-index:-1; background:linear-gradient(90deg,rgba(255,253,251,.92),rgba(255,253,251,.12)),var(--category-image); background-size:auto 100%,220px 100%; background-position:left center,right center; background-repeat:no-repeat; transform:translateY(105%); transition:transform .22s ease; }
        .flow-menu-subitem.has-image:hover::before { transform:translateY(0); }
        .flow-menu-item.is-makeup .flow-menu-item-icon { color:var(--orange); }
        .flow-menu-backdrop { display:block; position:fixed; inset:0; z-index:40; background:rgba(61,27,61,.34); opacity:0; visibility:hidden; pointer-events:none; transition:opacity .32s ease, visibility .32s ease; }
        .flow-menu-backdrop.open { opacity:1; visibility:visible; }
        .flow-menu-drawer { position:fixed; top:0; left:0; z-index:41; width:min(360px, 92vw); height:100vh; padding:28px 18px; background:linear-gradient(180deg,var(--flow-bg) 0%,var(--flow-bg-deep) 100%); color:var(--flow-text); overflow-y:auto; transform:translateX(-105%); transition:transform .42s cubic-bezier(.22,.61,.36,1); box-shadow:8px 0 26px rgba(61,27,61,.18); }
        .flow-menu-drawer.open { transform:translateX(0); }
        .flow-menu-head { display:flex; align-items:center; justify-content:space-between; padding:4px 6px 18px; border-bottom:1px solid var(--flow-line); }
        .flow-menu-brand { display:flex; align-items:center; gap:8px; margin:0 6px 16px; color:var(--flow-text); font-family:'Playfair Display',serif; font-size:20px; font-weight:700; letter-spacing:.4px; }
        .flow-menu-brand-mark { width:25px; height:25px; display:inline-flex; align-items:center; justify-content:center; border:1px solid rgba(255,248,244,.65); border-radius:7px; color:var(--flow-text); font-family:'Inter',sans-serif; font-size:12px; }
        .flow-menu-head h2 { margin:0; color:var(--flow-text); font-family:'Playfair Display',serif; font-size:24px; font-weight:600; }
        .flow-menu-close { width:34px; height:34px; border:1px solid rgba(255,255,255,.35); border-radius:50%; background:transparent; color:#fff; font-size:22px; line-height:1; cursor:pointer; }
        .flow-menu-close:hover { background:rgba(255,255,255,.12); }
        .flow-menu-list { display:flex; flex-direction:column; margin-top:8px; }
        .flow-menu-item { position:relative; isolation:isolate; display:flex; align-items:center; justify-content:space-between; gap:12px; min-height:53px; padding:8px 7px; border-bottom:1px solid var(--flow-line); color:var(--flow-text); text-decoration:none; overflow:hidden; transform:translateX(0); transition:color .28s ease, transform .28s ease, background-color .28s ease; }
        .flow-menu-item::before { content:""; position:absolute; inset:0; background:var(--cream); transform:translateY(105%); transition:transform .22s ease; z-index:-1; }
        .flow-menu-item:hover { color:var(--plum); transform:translateX(5px); }
        .flow-menu-item:hover::before { transform:translateY(0); }
        .flow-menu-item:hover .flow-menu-item-icon { transform:scale(1.08); }
        .flow-menu-item-left { display:flex; align-items:center; gap:13px; min-width:0; position:relative; z-index:1; }
        .flow-menu-item-icon { width:22px; height:22px; flex:0 0 22px; color:var(--orange); }
        .flow-menu-item-icon svg { display:block; width:100%; height:100%; }
        .flow-menu-item-icon { transition:transform .28s ease, color .28s ease; }
        .flow-menu-item-label { font-size:14px; font-weight:500; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
        .flow-menu-arrow { color:var(--flow-gold); font-size:20px; line-height:1; position:relative; z-index:1; transition:transform .22s ease; }
        .flow-menu-item:hover .flow-menu-arrow { transform:translateX(4px); }
        .flow-menu-badge { min-width:22px; padding:3px 6px; border:1px solid rgba(255,255,255,.26); border-radius:999px; color:rgba(255,248,244,.88); font-size:10px; line-height:1; text-align:center; position:relative; z-index:1; transition:background .22s ease, color .22s ease, border-color .22s ease; }
        .flow-menu-item:hover .flow-menu-badge { background:#F2D7C9; color:var(--plum); border-color:transparent; }
        .flow-menu-item-right { display:flex; align-items:center; gap:10px; position:relative; z-index:1; }
        .flow-menu-parent { width:100%; border:0; font:inherit; text-align:left; background:transparent; }
        .flow-menu-chevron { color:var(--flow-gold); font-size:18px; line-height:1; transition:transform .25s ease; }
        .flow-menu-group.open > .flow-menu-parent .flow-menu-chevron { transform:rotate(180deg); }
        .flow-menu-submenu { max-height:0; overflow:hidden; opacity:0; padding-left:18px; transition:max-height .35s ease, opacity .25s ease, padding .35s ease; }
        .flow-menu-group.open > .flow-menu-submenu { max-height:520px; opacity:1; padding-top:3px; padding-bottom:5px; }
        .flow-menu-subitem { min-height:40px; padding:8px 8px 8px 15px; display:flex; align-items:center; justify-content:space-between; gap:10px; border-bottom:1px solid rgba(255,248,244,.16); color:rgba(255,248,244,.88); font-size:13px; transition:color .2s ease, background .2s ease, padding-left .2s ease; }
        .flow-menu-subitem:hover { color:var(--plum); background:#FFF8F4; padding-left:20px; }
        .flow-menu-subitem-label { min-width:0; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
        .flow-menu-submenu-nested { padding-left:12px; }
        .flow-menu-nested-group.open > .flow-menu-submenu { max-height:260px; }
        .flow-menu-note { margin:18px 6px 0; color:rgba(255,248,244,.78); font-size:11px; text-align:center; }
        .flow-menu-item:nth-child(1) { --item-delay: .02s; }
        .flow-menu-item:nth-child(2) { --item-delay: .04s; }
        .flow-menu-item:nth-child(3) { --item-delay: .06s; }
        .flow-menu-item:nth-child(4) { --item-delay: .08s; }
        .flow-menu-item:nth-child(5) { --item-delay: .10s; }
        .flow-menu-item:nth-child(6) { --item-delay: .12s; }
        .flow-menu-item:nth-child(7) { --item-delay: .14s; }
        .flow-menu-item:nth-child(8) { --item-delay: .16s; }
        .flow-menu-item:nth-child(9) { --item-delay: .18s; }
        .flow-menu-item:nth-child(10) { --item-delay: .20s; }
        .flow-menu-item:nth-child(11) { --item-delay: .22s; }
        .flow-menu-item:nth-child(12) { --item-delay: .24s; }
        .flow-menu-item:nth-child(13) { --item-delay: .26s; }
        .flow-menu-drawer.open .flow-menu-item { animation:flowMenuItemIn .28s ease both; animation-delay:var(--item-delay); }
        @keyframes flowMenuItemIn { from { opacity:0; transform:translateX(18px); } to { opacity:1; transform:translateX(0); } }
        @media (prefers-reduced-motion: reduce) { .flow-menu-drawer, .flow-menu-backdrop, .flow-menu-item, .flow-menu-item::before, .flow-menu-arrow, .flow-menu-badge { transition:none; animation:none !important; } }
        .categories { display:none; }
        .topbar-inner, .guest-banner, .hero, .section, footer { margin-left:auto; margin-right:auto; max-width:1180px; }
        @media (max-width:900px) {
            .flow-menu-trigger.left-menu-trigger { display:flex; }
            .flow-menu-backdrop { display:block; }
            .flow-menu-drawer { width:min(360px, 92vw); transform:translateX(-105%); box-shadow:12px 0 30px rgba(61,27,61,.22); }
            .flow-menu-drawer.open { transform:translateX(0); }
            .flow-menu-backdrop.open { opacity:1; visibility:visible; }
            .topbar-inner, .guest-banner, .hero, .section, footer { margin-left:auto; margin-right:auto; max-width:1180px; }
        }

        /* ---------- React Bits-style FlowingMenu marquee ---------- */
        .flowing-menu-leaf { position:relative; overflow:hidden; isolation:isolate; }
        .flowing-menu-leaf > .flow-menu-subitem { position:relative; z-index:1; }
        .flowing-marquee { position:absolute; inset:0; z-index:2; overflow:hidden; pointer-events:none; background:var(--cream); color:var(--plum); transform:translate3d(0,101%,0); }
        .flowing-marquee-inner { display:flex; align-items:center; width:max-content; height:100%; will-change:transform; }
        .flowing-marquee-part { display:flex; align-items:center; flex-shrink:0; white-space:nowrap; text-transform:uppercase; font-size:14px; font-weight:700; letter-spacing:.04em; }
        .flowing-marquee-part > span:first-child { padding:0 12px; }
        .flowing-marquee-image { display:inline-block; width:120px; height:34px; margin:0 12px; border-radius:999px; background-position:center; background-size:cover; flex:0 0 auto; }
        .flowing-marquee-dot { display:inline-block; width:16px; height:16px; margin:0 26px 0 12px; border-radius:50%; background:var(--orange); box-shadow:0 0 0 5px rgba(226,112,58,.14); }
        .flowing-menu-leaf:hover .flow-menu-subitem-leaf { color:var(--plum); background:transparent; }
        .flowing-menu-leaf:hover .flow-menu-badge, .flowing-menu-leaf:hover .flow-menu-arrow { opacity:0; }
        @media (max-width:640px) { .flowing-marquee-part { font-size:12px; } .flowing-marquee-image { width:86px; height:28px; } }
        @media (prefers-reduced-motion:reduce) { .flowing-marquee { transform:none; opacity:0; } }
    </style>
</head>
<body>

    @php
        $flowMenuCategories = [
            ['label' => 'Men', 'slug' => 'men', 'image' => '', 'children' => [
                ['label' => 'Clothing', 'slug' => 'mens-clothing'],
                ['label' => 'Shoes', 'slug' => 'mens-shoes'],
                ['label' => 'Accessories', 'slug' => 'mens-accessories'],
                ['label' => 'Grooming', 'slug' => 'mens-grooming', 'children' => [
                    ['label' => 'Shavers & Trimmers', 'slug' => 'shavers-trimmers'],
                    ['label' => 'Hair Care', 'slug' => 'mens-hair-care'],
                    ['label' => 'Skincare', 'slug' => 'mens-skincare'],
                ]],
            ]],
            ['label' => 'Women', 'slug' => 'women', 'image' => '', 'children' => [
                ['label' => 'Clothing', 'slug' => 'womens-clothing'],
                ['label' => 'Shoes', 'slug' => 'womens-shoes'],
                ['label' => 'Bags', 'slug' => 'bags'],
                ['label' => 'Accessories', 'slug' => 'womens-accessories'],
                ['label' => 'Beauty', 'slug' => 'womens-beauty'],
            ]],
            ['label' => 'Electronics', 'slug' => 'electronics', 'image' => '', 'children' => [
                ['label' => 'Phones & Tablets', 'slug' => 'phones-tablets', 'children' => [
                    ['label' => 'Smartphones', 'slug' => 'smartphones', 'children' => [
                        ['label' => 'Apple', 'slug' => 'apple'],
                        ['label' => 'Samsung', 'slug' => 'samsung'],
                        ['label' => 'Xiaomi', 'slug' => 'xiaomi'],
                        ['label' => 'OPPO', 'slug' => 'oppo'],
                    ]],
                    ['label' => 'Tablets', 'slug' => 'tablets'],
                    ['label' => 'Accessories', 'slug' => 'electronics-accessories'],
                ]],
                ['label' => 'Computers', 'slug' => 'computers'],
                ['label' => 'Appliances', 'slug' => 'electronics-appliances'],
                ['label' => 'Audio', 'slug' => 'audio'],
                ['label' => 'Cameras', 'slug' => 'cameras'],
            ]],
            ['label' => 'Home & Living', 'slug' => 'home-living', 'image' => '', 'children' => [
                ['label' => 'Furniture', 'slug' => 'furniture'],
                ['label' => 'Kitchen', 'slug' => 'kitchen'],
                ['label' => 'Home', 'slug' => 'home', 'children' => [
                    ['label' => 'Appliances', 'slug' => 'home-appliances'],
                    ['label' => 'Home Decor', 'slug' => 'home-decor'],
                ]],
            ]],
            ['label' => 'Sports & Outdoors', 'slug' => 'sports-outdoors', 'image' => '', 'children' => [
                ['label' => 'Running', 'slug' => 'running'],
                ['label' => 'Basketball', 'slug' => 'basketball'],
                ['label' => 'Football', 'slug' => 'football'],
                ['label' => 'Hiking', 'slug' => 'hiking'],
                ['label' => 'Fitness', 'slug' => 'fitness'],
            ]],
            ['label' => 'Beauty & Personal Care', 'slug' => 'beauty-personal-care', 'image' => '', 'children' => [
                ['label' => 'Skincare', 'slug' => 'skincare'],
                ['label' => 'Makeup', 'slug' => 'makeup'],
                ['label' => 'Hair Care', 'slug' => 'hair-care'],
                ['label' => 'Personal Care', 'slug' => 'personal-care'],
            ]],
        ];
    @endphp

    <div class="flow-menu-backdrop" id="flowMenuBackdrop"></div>
    <aside class="flow-menu-drawer" id="flowMenuDrawer" aria-hidden="true">
        <div class="flow-menu-brand"><span class="flow-menu-brand-mark">L</span><span>LUMORA</span></div>
        <div class="flow-menu-head">
            <h2>Shop by collection</h2>
            <button type="button" class="flow-menu-close" id="flowMenuClose" aria-label="Close collections menu">&times;</button>
        </div>
        <nav class="flow-menu-list" aria-label="Shop by collection">
            @php
                $categoryCounts = $categoryCounts ?? [];
                $shopProducts = collect($products ?? []);
            @endphp

            @foreach ($flowMenuCategories as $category)
                <x-flow-menu-node
                    :node="$category"
                    :category-counts="$categoryCounts"
                    :shop-products="$shopProducts"
                />
            @endforeach
        </nav>
        <p class="flow-menu-note">Select a collection to browse matching products.</p>
    </aside>

    <!-- ===================== TOP BAR ===================== -->
    <header class="topbar">
        <div class="topbar-inner">
            <button type="button" class="flow-menu-trigger left-menu-trigger" id="flowMenuTriggerLeft" aria-label="Open shop by collection" aria-expanded="false" aria-controls="flowMenuDrawer">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 7h16M4 12h16M4 17h16"/></svg>
            </button>
            <a href="{{ route('shop.index') }}" class="brand">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M5 21V9a7 7 0 0 1 14 0v12"/><path d="M9 21v-6a3 3 0 0 1 6 0v6"/></svg>
                <span class="wordmark">LUM<span>O</span>RA</span>
            </a>

            <form action="{{ route('shop.index') }}" method="GET" class="search">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>
                <input type="text" name="q" placeholder="Search skincare, makeup, fragrance..." value="{{ request('q') }}">
            </form>

            <div class="nav-actions">
                <a href="#" class="icon-btn" aria-label="Wishlist">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
                </a>
                <a href="#" class="icon-btn" aria-label="Cart">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="9" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.5 3h2l2.7 12.4a2 2 0 0 0 2 1.6h8.6a2 2 0 0 0 2-1.6L21.5 7H6"/></svg>
                    <span class="badge">2</span>
                </a>

                @auth
                    <div class="account-menu-wrap" id="accountMenuWrap">
                        <button type="button" class="account-trigger" id="accountTrigger" aria-expanded="false" aria-controls="accountDropdown">
                            <div class="avatar">{{ strtoupper(substr(Auth::user()->name,0,1)) }}</div>
                            <div>
                                <div class="account-name">{{ Auth::user()->name }}</div>
                                <div class="account-mode">Shopping as Buyer <span class="buyer-badge">Buyer</span></div>
                            </div>
                            <svg class="account-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m6 9 6 6 6-6"/></svg>
                        </button>

                        <div class="account-dropdown" id="accountDropdown" role="menu">
                            <div class="account-dropdown-head">
                                <div class="avatar">{{ strtoupper(substr(Auth::user()->name,0,1)) }}</div>
                                <div>
                                    <div class="account-dropdown-name">{{ Auth::user()->name }}</div>
                                    <div class="account-mode">Currently shopping as <span class="buyer-badge">Buyer</span></div>
                                </div>
                            </div>

                            <a href="{{ route('profile.edit') }}" class="account-menu-link" role="menuitem">
                                <span class="account-menu-icon">♙</span>
                                <span>Profile / Settings</span>
                            </a>

                            @if (Auth::user()->role === 'seller')
                                <form method="POST" action="{{ route('switchToSeller') }}">
                                    @csrf
                                    <button type="submit" class="account-menu-button switch-seller" role="menuitem">
                                        <span class="account-menu-icon">▣</span>
                                        <span>Switch to Seller Dashboard</span>
                                    </button>
                                </form>
                            @endif

                            <div class="account-menu-divider"></div>
                            <form method="POST" action="{{ route('logout') }}">
                                @csrf
                                <button type="submit" class="account-menu-button logout-menu" role="menuitem">
                                    <span class="account-menu-icon">↪</span>
                                    <span>Log out</span>
                                </button>
                            </form>
                        </div>
                    </div>
                @else
                    <a href="{{ route('login') }}" class="btn btn-ghost">Login</a>
                    <a href="{{ route('register') }}" class="btn btn-primary">Sign Up</a>
                @endauth
            </div>
        </div>
    </header>

    <!-- ===================== GUEST BANNER ===================== -->
    @guest
    <div class="guest-banner">
        <div class="guest-banner-inner">
            <p>You're browsing as a guest &mdash; <strong>sign in</strong> to save items, track orders and check out faster.</p>
            <div class="links">
                <a href="{{ route('login') }}">Log in</a>
                <a href="{{ route('register') }}">Create account</a>
            </div>
        </div>
    </div>
    @endguest

    <!-- ===================== CATEGORY STRIP ===================== -->
    <div class="categories">
        <a href="{{ route('shop.index') }}?category=skincare-products" class="cat-card">
            <div class="cat-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M12 2C8 6 5 10 5 14a7 7 0 0 0 14 0c0-4-3-8-7-12Z"/></svg>
            </div>
            <span>Skincare</span>
        </a>
        <a href="{{ route('shop.index') }}?category=hair-solutions" class="cat-card">
            <div class="cat-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M12 3C9 3 6 5 6 8c0 2 1 3.5 2 5 .5.8 1 2 1 3h6c0-1 .5-2.2 1-3 1-1.5 2-3 2-5 0-3-3-5-6-5Z"/><path d="M9 16h6M10 19h4"/></svg>
            </div>
            <span>Hair</span>
        </a>
        <a href="{{ route('shop.index') }}?category=makeup-cosmetics" class="cat-card">
            <div class="cat-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M12 2c-1 0-2 .5-2 1.5V6h4V3.5C14 2.5 13 2 12 2Z"/><rect x="9" y="6" width="6" height="12" rx="2"/><path d="M10 18v2a2 2 0 0 0 4 0v-2"/></svg>
            </div>
            <span>Makeup</span>
        </a>
        <a href="{{ route('shop.index') }}?category=personal-care-appliances" class="cat-card">
            <div class="cat-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="7" y="2" width="10" height="16" rx="3"/><path d="M12 18v4M9 22h6"/><path d="M10 6h4M10 9h4M10 12h4"/></svg>
            </div>
            <span>Appliances</span>
        </a>
        <a href="{{ route('shop.index') }}?category=mens-grooming" class="cat-card">
            <div class="cat-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M7 3h10v2l-2 2H9L7 5V3Z"/><path d="M9 7v10a3 3 0 0 0 6 0V7"/><path d="M12 17v2"/></svg>
            </div>
            <span>Men's Grooming</span>
        </a>
        <a href="{{ route('shop.index') }}?category=health-supplements" class="cat-card">
            <div class="cat-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="8" y="2" width="8" height="14" rx="4"/><path d="M8 9h8"/><path d="M10 16v6M14 16v6"/></svg>
            </div>
            <span>Supplements</span>
        </a>
    </div>

    <!-- ===================== HERO ===================== -->
    <section class="hero">
        <div class="hero-copy">
            <p class="eyebrow">New season edit</p>
            <h1>Step into<br>something beautiful</h1>
            <p>Curated skincare, makeup and fragrance from independent sellers you'll love. No account needed to browse &mdash; just to check out.</p>
            <button class="hero-cta">Explore the collection
                <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
            </button>
        </div>
        <div class="hero-visual">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M5 21V9a7 7 0 0 1 14 0v12"/></svg>
        </div>
    </section>

    <!-- ===================== FLASH DEALS ===================== -->
    <section class="section">
        <div class="section-head">
            <h2>Flash deals</h2>
        </div>
        <div class="deals-strip">
            @foreach ([
                ['name'=>'Rose Clay Mask','now'=>'₱349','was'=>'₱499','disc'=>'30% off','color'=>'linear-gradient(135deg,#D46A6A,#8A3D3D)'],
                ['name'=>'Silk Lip Tint','now'=>'₱199','was'=>'₱280','disc'=>'29% off','color'=>'linear-gradient(135deg,#E2703A,#B4502A)'],
                ['name'=>'Amber Eau de Parfum','now'=>'₱899','was'=>'₱1,299','disc'=>'31% off','color'=>'linear-gradient(135deg,#7A5A9E,#3D1B3D)'],
                ['name'=>'Gold Hoop Earrings','now'=>'₱450','was'=>'₱620','disc'=>'27% off','color'=>'linear-gradient(135deg,#C9972B,#8A6314)'],
                ['name'=>'Linen Candle Set','now'=>'₱520','was'=>'₱690','disc'=>'25% off','color'=>'linear-gradient(135deg,#5A8A6E,#2E4F3C)'],
            ] as $d)
                <div class="deal-card">
                    <div class="deal-thumb" style="background:{{ $d['color'] }}">
                        <span class="deal-discount">{{ $d['disc'] }}</span>
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
                    </div>
                    <div class="deal-body">
                        <p class="name">{{ $d['name'] }}</p>
                        <div class="deal-price">
                            <span class="now">{{ $d['now'] }}</span>
                            <span class="was">{{ $d['was'] }}</span>
                        </div>
                        <p class="deal-timer">Ends in 04:12:45</p>
                    </div>
                </div>
            @endforeach
        </div>
    </section>

    <!-- ===================== JUST FOR YOU (grouped by category) ===================== -->
    <section class="section">
        <div class="section-head">
            <h2>Just for you</h2>
        </div>

        @php
            // TEMPORARY sample data, grouped by category slug.
            // Once your products table has a `category` column, swap this
            // for real grouped data from the controller (see note below).
            $categoryGroups = [
                'skincare-products' => [
                    'label' => 'Skincare Products',
                    'items' => [
                        ['name' => 'Hydrating Vitamin C Serum', 'price' => '620.00'],
                        ['name' => 'Chamomile Body Butter', 'price' => '395.00'],
                        ['name' => 'Rose Quartz Roller', 'price' => '450.00'],
                        ['name' => 'Niacinamide Toner', 'price' => '299.00'],
                    ],
                ],
                'hair-solutions' => [
                    'label' => 'Haircare Solutions',
                    'items' => [
                        ['name' => 'Silk Hair Wrap', 'price' => '260.00'],
                        ['name' => 'Argan Oil Hair Serum', 'price' => '410.00'],
                        ['name' => 'Scalp Massage Brush', 'price' => '180.00'],
                        ['name' => 'Keratin Repair Mask', 'price' => '355.00'],
                    ],
                ],
                'makeup-cosmetics' => [
                    'label' => 'Makeup & Cosmetics',
                    'items' => [
                        ['name' => 'Matte Velvet Lipstick', 'price' => '280.00'],
                        ['name' => 'Soft Focus Setting Powder', 'price' => '510.00'],
                        ['name' => 'Cream Blush Duo', 'price' => '330.00'],
                        ['name' => 'Volumizing Mascara', 'price' => '295.00'],
                    ],
                ],
                'personal-care-appliances' => [
                    'label' => 'Personal Care Appliances',
                    'items' => [
                        ['name' => 'Facial Cleansing Brush', 'price' => '890.00'],
                        ['name' => 'Ionic Hair Dryer', 'price' => '1,450.00'],
                        ['name' => 'Rechargeable Epilator', 'price' => '1,120.00'],
                        ['name' => 'LED Facial Mask', 'price' => '2,300.00'],
                    ],
                ],
                'mens-grooming' => [
                    'label' => "Men's Grooming",
                    'items' => [
                        ['name' => 'Beard Oil', 'price' => '240.00'],
                        ['name' => 'Charcoal Face Wash', 'price' => '210.00'],
                        ['name' => 'Precision Trimmer', 'price' => '1,290.00'],
                        ['name' => 'Aftershave Balm', 'price' => '260.00'],
                    ],
                ],
                'health-supplements' => [
                    'label' => 'Health Supplements',
                    'items' => [
                        ['name' => 'Collagen Peptides', 'price' => '780.00'],
                        ['name' => 'Vitamin C Gummies', 'price' => '320.00'],
                        ['name' => 'Omega-3 Softgels', 'price' => '450.00'],
                        ['name' => 'Probiotic Capsules', 'price' => '590.00'],
                    ],
                ],
            ];

            // If the controller passed real grouped products (e.g. $productsByCategory
            // built with Product::all()->groupBy('category')), use those instead.
            if (!empty($productsByCategory)) {
                foreach ($categoryGroups as $slug => $group) {
                    if (!empty($productsByCategory[$slug])) {
                        $categoryGroups[$slug]['items'] = $productsByCategory[$slug];
                    }
                }
            }
        @endphp

        @foreach ($categoryGroups as $slug => $group)
            <div class="category-block">
                <div class="section-subhead">
                    <h3>{{ $group['label'] }}</h3>
                    <a href="{{ route('shop.index') }}?category={{ $slug }}" class="see-all">See all</a>
                </div>
                <div class="grid">
                    @foreach ($group['items'] as $item)
                        <div class="product-card">
                            <button class="wishlist-btn" aria-label="Add to wishlist">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
                            </button>
                            <div class="product-thumb" style="background:linear-gradient(135deg,#5A2E5A,#3D1B3D)">
                                @if(is_object($item) && !empty($item->image))
                                    <img src="{{ Storage::url($item->image) }}" style="width:100%;height:100%;object-fit:cover;" alt="{{ $item->name }}">
                                @else
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M12 2C8 6 5 10 5 14a7 7 0 0 0 14 0c0-4-3-8-7-12Z"/></svg>
                                @endif
                            </div>
                            <div class="product-body">
                                @if (is_object($item))
                                    <p class="name">{{ $item->name }}</p>
                                    <p class="product-price">₱{{ number_format($item->price, 2) }}</p>
                                @else
                                    <p class="name">{{ $item['name'] }}</p>
                                    <p class="product-price">₱{{ $item['price'] }}</p>
                                @endif
                                <div class="product-rating">
                                    <svg viewBox="0 0 24 24" fill="currentColor"><path d="m12 2 3.1 6.3 6.9 1-5 4.9 1.2 6.8L12 17.8l-6.2 3.2L7 14.2l-5-4.9 6.9-1L12 2Z"/></svg>
                                    4.8 · 120 sold
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>
        @endforeach
    </section>

    <!-- ===================== FOOTER ===================== -->
    <footer>
        <p class="wordmark">LUM<span style="color:var(--orange)">O</span>RA</p>
        <p>Step into something beautiful.</p>
        <p>&copy; {{ date('Y') }} Lumora. All rights reserved.</p>
    </footer>

    @auth
        @include('components.chat-widget')
    @endauth


    <script>
        const accountMenuWrap = document.getElementById('accountMenuWrap');
        const accountTrigger = document.getElementById('accountTrigger');

        if (accountMenuWrap && accountTrigger) {
            accountTrigger.addEventListener('click', function (event) {
                event.stopPropagation();
                const isOpen = accountMenuWrap.classList.toggle('open');
                accountTrigger.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
            });

            document.addEventListener('click', function (event) {
                if (!accountMenuWrap.contains(event.target)) {
                    accountMenuWrap.classList.remove('open');
                    accountTrigger.setAttribute('aria-expanded', 'false');
                }
            });

            document.addEventListener('keydown', function (event) {
                if (event.key === 'Escape') {
                    accountMenuWrap.classList.remove('open');
                    accountTrigger.setAttribute('aria-expanded', 'false');
                    accountTrigger.focus();
                }
            });
        }
        </script>

    {{-- Fallback drawer controls. The main implementation lives in resources/js/app.js. --}}
    <script>
        (function () {
            if (window.__lumoraFlowMenuBound) return;

            const drawer = document.getElementById('flowMenuDrawer');
            const backdrop = document.getElementById('flowMenuBackdrop');
            const closeButton = document.getElementById('flowMenuClose');
            const triggers = document.querySelectorAll('#flowMenuTrigger, #flowMenuTriggerLeft');

            if (!drawer || !backdrop || !triggers.length) return;
            window.__lumoraFlowMenuBound = true;

            function setOpen(open) {
                drawer.classList.toggle('open', open);
                backdrop.classList.toggle('open', open);
                drawer.setAttribute('aria-hidden', open ? 'false' : 'true');
                triggers.forEach(function (trigger) {
                    trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
                });
                document.body.style.overflow = open ? 'hidden' : '';
            }

            triggers.forEach(function (trigger) {
                trigger.addEventListener('click', function () {
                    setOpen(!drawer.classList.contains('open'));
                });
            });

            closeButton?.addEventListener('click', function () { setOpen(false); });
            backdrop.addEventListener('click', function () { setOpen(false); });
            document.addEventListener('keydown', function (event) {
                if (event.key === 'Escape') setOpen(false);
            });

            document.querySelectorAll('[data-submenu-toggle]').forEach(function (toggle) {
                toggle.addEventListener('click', function () {
                    const group = toggle.closest('[data-submenu-group]');
                    if (!group) return;
                    const expanded = group.classList.toggle('open');
                    toggle.setAttribute('aria-expanded', expanded ? 'true' : 'false');
                });
            });
        }());
    </script>
</body>
</html>