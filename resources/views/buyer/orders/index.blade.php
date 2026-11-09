@php
    $user = request()->user();
    $cartCount = session('lumora_cart') ? collect(session('lumora_cart'))->sum('quantity') : 0;

    $statuses = $statuses ?? [
        'pending',
        'processing',
        'packed',
        'shipped',
        'out_for_delivery',
        'delivered',
        'cancelled',
        'returned',
    ];

    $activeStatus = $activeStatus ?? request('status', 'all');
    $search = $search ?? request('search', '');
    $sort = $sort ?? request('sort', 'latest');

    $statusLabels = [
        'all' => 'All Orders',
        'pending' => 'Pending',
        'processing' => 'Processing',
        'packed' => 'Packed',
        'shipped' => 'Shipped',
        'out_for_delivery' => 'Out for Delivery',
        'delivered' => 'Delivered',
        'cancelled' => 'Cancelled',
        'returned' => 'Returned',
    ];

    $statusBadgeClasses = [
        'pending' => 'status-pending',
        'processing' => 'status-processing',
        'packed' => 'status-packed',
        'shipped' => 'status-shipped',
        'out_for_delivery' => 'status-out-for-delivery',
        'delivered' => 'status-delivered',
        'cancelled' => 'status-cancelled',
        'returned' => 'status-returned',
    ];

    $sortLabels = [
        'latest' => 'Latest',
        'oldest' => 'Oldest',
        'highest' => 'Highest Amount',
        'lowest' => 'Lowest Amount',
    ];

    $visibleOrders = $orders->getCollection();

    $orderSummaryCards = [
        ['label' => 'Total Orders', 'value' => $orders->total()],
        ['label' => 'Pending', 'value' => $visibleOrders->where('status', 'pending')->count()],
        ['label' => 'Packed', 'value' => $visibleOrders->where('status', 'packed')->count()],
        ['label' => 'Delivered', 'value' => $visibleOrders->where('status', 'delivered')->count()],
    ];
@endphp

<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Lumora | My Orders</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,600;0,700;1,500&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root{--background:#F7F1EC;--card:#FFFDFC;--primary:#3B1E34;--accent:#C98F72;--border:#EAE3DD;--text:#2F2528;--muted:#8B7B78;--success:#6F8F78;--hover:#F8F4F1;--active:#F5ECE6;--shadow:0 10px 40px rgba(0,0,0,.04)}
        *{box-sizing:border-box}
        body{margin:0;background:var(--background);color:var(--text);font-family:Inter,ui-sans-serif,system-ui,sans-serif;font-size:16px;letter-spacing:0}
        h1,h2,h3{font-family:'Playfair Display',Georgia,serif;color:var(--primary);font-weight:600;letter-spacing:0}
        a{text-decoration:none;color:inherit}
        button,input,select{font:inherit}
        button{cursor:pointer}
        .profile-topbar{position:sticky;top:0;z-index:30;background:var(--card);border-bottom:1px solid var(--border)}
        .profile-topbar-inner{max-width:1480px;margin:0 auto;padding:15px 40px;display:flex;align-items:center;gap:24px}
        .topbar-search{flex:1;max-width:520px;min-height:40px;display:flex;align-items:center;gap:9px;border:1px solid var(--border);border-radius:999px;background:var(--card);padding:0 16px;color:var(--muted);font-size:13px}
        .topbar-search input{width:100%;border:0;background:transparent;outline:0;color:var(--text)}
        .topbar-search svg,.topbar-action svg{width:17px;height:17px}
        .topbar-actions{margin-left:auto;display:flex;align-items:center;gap:12px}
        .topbar-action{position:relative;width:38px;height:38px;display:grid;place-items:center;border:1px solid var(--border);border-radius:999px;background:var(--card);color:var(--primary);transition:background-color .2s ease,border-color .2s ease,color .2s ease}
        .topbar-action:hover{background:var(--hover);border-color:var(--accent)}
        .topbar-badge{position:absolute;top:-5px;right:-5px;min-width:17px;height:17px;display:grid;place-items:center;border-radius:999px;background:var(--accent);color:var(--card);font-size:10px;font-weight:600}
        .mobile-menu-button{display:none;width:40px;height:40px;border:1px solid var(--border);border-radius:999px;background:var(--card);color:var(--primary)}
        .profile-logo{display:inline-flex;flex-direction:column;align-items:flex-start;justify-content:center;flex-shrink:0;color:var(--primary);transition:opacity .2s ease}
        .profile-logo-brand{font-family:'Playfair Display',Georgia,serif;font-size:31px;font-weight:500;line-height:1;text-transform:uppercase;letter-spacing:.32em;color:var(--primary)}
        .profile-logo-brand span{color:var(--accent)}
        .profile-logo-tagline{margin-top:4px;font-size:8px;font-weight:500;line-height:1;text-transform:uppercase;letter-spacing:.4em;color:var(--muted)}
        .profile-page{max-width:1680px;margin:0 auto;padding:48px 48px 72px}
        .profile-layout{display:grid;grid-template-columns:280px minmax(0,1fr);gap:40px;align-items:start}
        .profile-sidebar{position:sticky;top:110px;height:fit-content}
        .profile-sidebar-card{border:1px solid var(--border);border-radius:24px;background:var(--card);box-shadow:var(--shadow);padding:14px}
        .profile-nav{display:grid;gap:10px}
        .profile-nav-section{display:grid;gap:10px}
        .profile-nav-section + .profile-nav-section{margin-top:16px;padding-top:16px;border-top:1px solid var(--border)}
        .profile-nav-section-title{padding:4px 16px;color:var(--muted);font-size:11px;font-weight:800;letter-spacing:.16em;text-transform:uppercase}
        .profile-nav-item,.logout-nav-button{width:100%;height:54px;display:flex;align-items:center;gap:13px;border:0;border-left:4px solid transparent;border-radius:16px;background:transparent;padding:0 16px;color:var(--muted);font-size:14px;font-weight:600;text-align:left;transition:background-color .2s ease,border-color .2s ease,color .2s ease,transform .2s ease}
        .profile-nav-item.active{border-left-color:var(--accent);background:var(--active);color:var(--primary);box-shadow:inset 0 0 0 1px rgba(201,143,114,.16)}
        .profile-nav-item:hover,.logout-nav-button:hover{background:var(--hover);color:var(--primary)}
        .profile-nav-icon{width:18px;height:18px;display:grid;place-items:center;flex:0 0 auto}
        .profile-nav-icon svg{width:17px;height:17px}
        .logout-nav-form{margin:8px 0 0;padding-top:10px;border-top:1px solid var(--border)}
        .orders-content{min-width:0;animation:fadeUp .2s ease both}
        .breadcrumb{display:flex;align-items:center;gap:9px;margin-bottom:18px;color:var(--muted);font-size:13px}
        .breadcrumb a{color:var(--primary);transition:color .2s ease}
        .breadcrumb a:hover{color:var(--accent)}
        .orders-header{display:grid;grid-template-columns:minmax(320px,.8fr) minmax(520px,1.2fr);gap:32px;align-items:end;margin-bottom:30px}
        .orders-label{margin:0 0 10px;color:var(--accent);font-size:11px;font-weight:700;letter-spacing:.18em;text-transform:uppercase}
        .orders-title{margin:0;font-size:58px;line-height:1}
        .orders-subtitle{max-width:520px;margin:14px 0 0;color:var(--muted);font-size:16px;line-height:1.7}
        .summary-cards{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px}
        .summary-card{min-height:104px;border:1px solid var(--border);border-radius:24px;background:var(--card);box-shadow:var(--shadow);padding:20px}
        .summary-card span{display:block;color:var(--muted);font-size:11px;font-weight:700;letter-spacing:.12em;text-transform:uppercase}
        .summary-card strong{display:block;margin-top:12px;color:var(--primary);font:600 34px/1 'Playfair Display',Georgia,serif}
        .orders-tools{display:grid;gap:18px;margin-bottom:30px}
        .orders-tabs{display:flex;align-items:center;gap:22px;overflow-x:auto;overflow-y:hidden;border-bottom:1px solid var(--border);padding-bottom:1px;scrollbar-width:none}
        .orders-tabs::-webkit-scrollbar{display:none}
        .orders-tab{position:relative;display:inline-flex;align-items:center;min-height:48px;flex:0 0 auto;color:var(--muted);font-size:13px;font-weight:700;transition:color .2s ease}
        .orders-tab::after{content:"";position:absolute;right:0;bottom:-1px;left:0;height:2px;background:var(--accent);transform:scaleX(0);transform-origin:center;transition:transform .2s ease}
        .orders-tab.active{color:var(--primary)}
        .orders-tab.active::after,.orders-tab:hover::after{transform:scaleX(1)}
        .orders-filter-form{display:flex;align-items:center;justify-content:flex-end;gap:12px}
        .search-field,.sort-field{height:44px;border:1px solid var(--border);border-radius:999px;background:var(--card);color:var(--text);outline:0;transition:border-color .2s ease,box-shadow .2s ease}
        .search-field{width:min(380px,100%);padding:0 16px}
        .sort-field{padding:0 34px 0 14px}
        .search-field:focus,.sort-field:focus{border-color:var(--accent);box-shadow:0 0 0 3px rgba(201,143,114,.14)}
        .orders-list{display:grid;gap:26px}
        .order-card{display:grid;grid-template-columns:minmax(230px,1.1fr) minmax(250px,.9fr) 130px minmax(180px,.75fr) 150px;gap:28px;align-items:center;border:1px solid var(--border);border-radius:24px;background:var(--card);box-shadow:var(--shadow);padding:32px;animation:fadeUp .2s ease both;transition:box-shadow .2s ease,transform .2s ease,border-color .2s ease}
        .order-card:hover{border-color:var(--accent);box-shadow:0 16px 45px rgba(59,30,52,.07);transform:translateY(-3px)}
        .order-number{margin:0;color:var(--primary);font:600 28px/1.1 'Playfair Display',Georgia,serif}
        .order-meta{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-top:12px;color:var(--muted);font-size:13px}
        .order-meta span + span::before{content:"";display:inline-block;width:4px;height:4px;margin:0 10px 2px 0;border-radius:999px;background:var(--accent)}
        .product-preview{display:flex;align-items:center;gap:12px}
        .product-thumb{width:80px;height:80px;display:grid;place-items:center;overflow:hidden;border:1px solid var(--border);border-radius:18px;background:var(--background);color:var(--primary);font-size:13px;font-weight:700}
        .product-thumb img{width:100%;height:100%;object-fit:cover}
        .product-more{background:var(--active)}
        .status-badge{display:inline-flex;align-items:center;justify-content:center;min-height:34px;border:1px solid var(--border);border-radius:999px;padding:0 14px;font-size:11px;font-weight:800;letter-spacing:.04em;text-transform:uppercase;animation:fadeIn .2s ease both}
        .status-pending {
         background: var(--active);
         color: var(--primary);
        }

        .status-processing {
         background: rgba(201,143,114,.14);
         color: var(--accent);
        }

        .status-packed {
         background: rgba(201,143,114,.18);
         color: var(--primary);
        }

        .status-shipped {
         background: rgba(59,30,52,.08);
         color: var(--primary);
        }

        .status-out-for-delivery {
         background: rgba(59,30,52,.12);
         color: var(--primary);
        }

        .status-delivered {
         background: rgba(111,143,120,.14);
         color: var(--success);
        }

        .status-cancelled,
        .status-returned {
         background: rgba(139,123,120,.13);
         color: var(--muted);
        }
        .return-button{min-height:42px;border:1px solid var(--accent);border-radius:999px;background:var(--card);color:var(--primary);padding:0 17px;font-size:12px;font-weight:700}
        .return-button:hover{background:var(--active)}
        .return-modal[hidden]{display:none}.return-modal{position:fixed;inset:0;z-index:80;display:grid;place-items:center;padding:20px;background:rgba(35,20,30,.54)}
        .return-dialog{width:min(560px,100%);max-height:90vh;overflow:auto;border:1px solid var(--border);border-radius:22px;background:var(--card);padding:28px;box-shadow:0 20px 70px #24121e40}
        .return-dialog h2{margin:0 0 6px;font-size:25px}.return-dialog p{margin:0 0 20px;color:var(--muted);font-size:13px;line-height:1.6}
        .return-dialog label{display:block;margin:14px 0 7px;color:var(--primary);font-size:12px;font-weight:700}
        .return-dialog select,.return-dialog textarea,.return-dialog input[type=file]{width:100%;border:1px solid var(--border);border-radius:10px;background:#fff;padding:12px;color:var(--text)}
        .return-dialog textarea{min-height:110px;resize:vertical}.return-modal-actions{display:flex;justify-content:flex-end;gap:10px;margin-top:20px}
        .return-cancel,.return-submit{min-height:42px;border-radius:999px;padding:0 18px;font-weight:700;font-size:12px}.return-cancel{border:1px solid var(--border);background:white;color:var(--primary)}.return-submit{border:1px solid var(--primary);background:var(--primary);color:white}
        .order-summary{display:grid;gap:12px}
        .summary-line span{display:block;margin-bottom:3px;color:var(--muted);font-size:12px}
        .summary-line strong{color:var(--primary);font-size:14px}
        .summary-line:first-child strong{font:600 22px/1.1 'Playfair Display',Georgia,serif}
        .details-button{min-height:46px;display:inline-flex;align-items:center;justify-content:center;gap:8px;border:1px solid var(--accent);border-radius:999px;background:var(--card);color:var(--primary);font-size:13px;font-weight:700;transition:background-color .2s ease,transform .2s ease,border-color .2s ease}
        .details-button svg{width:15px;height:15px}
        .details-button:hover{background:var(--hover);border-color:var(--accent);transform:scale(1.02)}
        .order-success-message{display:flex;align-items:center;justify-content:space-between;gap:16px;margin:0 0 22px;padding:15px 18px;border:1px solid rgba(111,143,120,.28);border-radius:12px;background:#edf4ed;color:#45694d;font-size:14px;font-weight:700;box-shadow:var(--shadow)}
        .order-success-message button{border:0;background:transparent;color:inherit;font-size:20px;line-height:1;cursor:pointer}
        .empty-orders{border:1px solid var(--border);border-radius:24px;background:var(--card);box-shadow:var(--shadow);padding:56px 32px;text-align:center}
        .empty-icon{width:86px;height:86px;display:grid;place-items:center;margin:0 auto 22px;border:1px solid var(--border);border-radius:999px;background:var(--background);color:var(--primary)}
        .empty-icon svg{width:40px;height:40px}
        .empty-orders h2{margin:0;font-size:38px;line-height:1.1}
        .empty-orders p{max-width:420px;margin:13px auto 24px;color:var(--muted);line-height:1.7}
        .btn-primary{min-height:46px;display:inline-flex;align-items:center;justify-content:center;border:1px solid var(--primary);border-radius:999px;background:var(--primary);padding:0 22px;color:var(--card);font-size:13px;font-weight:700;transition:background-color .2s ease,transform .2s ease}
        .btn-primary:hover{background:#4E2A47;transform:scale(1.02)}
        .pagination-row{display:flex;align-items:center;justify-content:center;flex-direction:column;gap:16px;margin-top:34px;color:var(--muted);font-size:13px;text-align:center}
        .pagination-links{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
        .pagination-links a,.pagination-links span{min-width:36px;height:36px;display:inline-flex;align-items:center;justify-content:center;border:1px solid var(--border);border-radius:999px;background:var(--card);color:var(--primary);font-size:13px;font-weight:700}
        .pagination-links .active{border-color:var(--accent);background:var(--active)}
        .pagination-links .disabled{color:var(--muted);opacity:.55}
        .drawer-backdrop{position:fixed;inset:0;z-index:40;display:none;background:rgba(47,37,40,.25)}
        .drawer-backdrop.open{display:block}
        .profile-page svg,.profile-topbar svg{stroke-width:1.75}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        @keyframes fadeUp{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
        @media(prefers-reduced-motion:reduce){*,*::before,*::after{animation:none!important;transition:none!important}}
        @media(max-width:1399px){.profile-topbar-inner,.profile-page{padding-right:32px;padding-left:32px}.profile-layout{grid-template-columns:250px minmax(0,1fr);gap:28px}.orders-header{grid-template-columns:1fr}.summary-cards{grid-template-columns:repeat(4,minmax(150px,1fr))}.order-card{grid-template-columns:minmax(220px,1fr) minmax(210px,.8fr) 120px minmax(170px,.7fr);gap:22px}.order-actions{grid-column:1 / -1}.details-button{width:100%}}
        @media(max-width:1023px) and (min-width:768px){.profile-layout{display:block}.profile-sidebar{position:static;width:100%;height:auto;margin-bottom:24px}.profile-sidebar-card{display:flex;align-items:center;overflow-x:auto;padding:10px;border-radius:20px}.profile-nav{display:flex;flex:0 0 auto;gap:10px;width:max-content}.profile-nav-section{display:flex;align-items:center;gap:10px}.profile-nav-section + .profile-nav-section{margin-top:0;margin-left:10px;padding-top:0;padding-left:14px;border-top:0;border-left:1px solid var(--border)}.profile-nav-section-title{display:none}.logout-nav-form{flex:0 0 auto;margin:0;padding:0;border:0}.profile-nav-item,.logout-nav-button{width:auto;min-width:max-content;height:50px;padding:0 16px;border-left:0}.profile-nav-item.active{box-shadow:inset 0 -3px 0 var(--accent)}.orders-title{font-size:48px}.drawer-backdrop{display:none!important}}
        @media(max-width:767px){body{font-size:15px}.mobile-menu-button{display:grid;place-items:center}.topbar-search{display:none}.profile-topbar-inner{padding:13px 20px;gap:16px}.profile-logo-brand{font-size:24px;letter-spacing:.28em}.profile-logo-tagline{font-size:7px;letter-spacing:.32em}.profile-page{padding:24px 20px 48px}.profile-layout{display:block}.profile-sidebar{position:fixed;top:0;left:0;bottom:0;z-index:50;width:280px;height:100%;padding:0;background:var(--card);border-right:1px solid var(--border);transform:translateX(-105%);transition:transform .25s ease-out}.profile-sidebar.open{transform:translateX(0)}.profile-sidebar-card{height:100%;overflow-y:auto;border:0;border-radius:0;background:var(--card);padding:20px 12px}.profile-nav-item,.logout-nav-button{justify-content:flex-start;padding:0 15px;border-left:4px solid transparent}.profile-nav-item.active{box-shadow:none}.orders-header{grid-template-columns:1fr;gap:20px}.orders-title{font-size:42px}.orders-subtitle{font-size:15px}.summary-cards{grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}.summary-card{min-height:92px;padding:16px}.summary-card strong{font-size:28px}.orders-filter-form{align-items:stretch;flex-direction:column}.search-field,.sort-field{width:100%}.orders-tabs{gap:18px}.order-card{grid-template-columns:1fr;padding:24px;gap:20px}.order-number{font-size:24px}.product-preview{flex-wrap:wrap}.product-thumb{width:72px;height:72px}.details-button{width:100%;min-height:48px}.pagination-row{margin-top:28px}.topbar-action:active,.profile-nav-item:active,.logout-nav-button:active{background:var(--active)}}
        /* My Orders refresh */
        :root{--background:#f5f1ec;--primary:#4a1233;--accent:#c98b6b;--muted:#66585b;--border:#e7ddd7;--active:#f7eee9}
        .orders-header{display:flex;justify-content:space-between;align-items:end;gap:24px;margin-bottom:25px}
        .orders-title{font-size:48px;color:#4a1233}.orders-subtitle{margin-top:8px;color:#66585b;font-size:14px;font-weight:500}
        .orders-filter-form{display:flex;align-items:center;gap:10px;max-width:650px;width:58%}
        .search-field{flex:1;width:auto;min-width:150px}.sort-field{flex:0 0 165px}.filter-submit{height:44px;border:0;border-radius:999px;background:#4a1233;padding:0 18px;color:#fff;font-size:13px;font-weight:700}
        .orders-tabs{gap:28px;margin-bottom:22px}.orders-tab{gap:8px;min-height:48px;color:#66585b}.orders-tab.active{color:#4a1233}
        .tab-count{display:inline-flex;align-items:center;justify-content:center;min-width:22px;height:22px;border-radius:999px;background:#f1e9e4;padding:0 6px;color:#5a4b50;font-size:11px;font-weight:700}.orders-tab.active .tab-count{background:#f0ddd2;color:#4a1233}
        .order-card{display:block;padding:0;border-radius:18px;cursor:pointer;transition:box-shadow .2s ease,transform .2s ease,border-color .2s ease}.order-card:hover{transform:translateY(-2px);box-shadow:0 14px 36px rgba(74,18,51,.09)}
        .order-card:focus-visible{outline:3px solid #c98b6b;outline-offset:3px}
        .order-card-header{display:flex;justify-content:space-between;align-items:center;gap:15px;border-bottom:1px solid #eee6e1;padding:18px 22px}
        .order-number{font:600 17px/1.3 Inter,ui-sans-serif,sans-serif;color:#4a1233;letter-spacing:.01em}.order-meta{margin-top:5px;font-size:12px;color:#66585b}
        .status-badge{min-height:29px;gap:7px;padding:0 11px;border:0;font-size:10px;letter-spacing:.035em}
        .status-badge i{width:7px;height:7px;border-radius:50%;background:currentColor}
        .status-pending{background:#fff2d7;color:#875c09}.status-packed{background:#e8f0ff;color:#315b9b}.status-shipped,.status-out_for_delivery{background:#e1f4f1;color:#176b60}.status-delivered{background:#e7f3e8;color:#356e3b}.status-cancelled,.status-returned{background:#fae8e7;color:#a23e3b}.status-processing{background:#eee9f8;color:#614990}
        .order-card-body{display:flex;justify-content:space-between;align-items:center;gap:24px;padding:20px 22px}
        .order-product{display:flex;align-items:center;gap:18px;min-width:0}.product-preview{gap:0;padding-left:8px;flex:0 0 auto}.product-thumb{width:62px;height:62px;margin-left:-8px;border:2px solid #fff;border-radius:14px;background:#f5f1ec}.product-thumb img{object-fit:cover}.product-more{background:#f0e4dd;color:#4a1233}
        .product-description{display:grid;gap:5px;min-width:0}.product-description strong{overflow:hidden;color:#35282e;font-size:14px;font-weight:650;text-overflow:ellipsis;white-space:nowrap}.product-description span{color:#66585b;font-size:12px}.product-description .delivery-estimate{margin-top:3px;color:#4a1233;font-weight:600}
        .order-summary{display:grid;justify-items:end;gap:5px;flex:0 0 auto}.summary-label{color:#66585b;font-size:12px}.order-total{color:#4a1233;font:600 24px/1.1 'Playfair Display',Georgia,serif}.payment-tag{border-radius:999px;background:#f4eeea;padding:5px 10px;color:#4a1233;font-size:10px;font-weight:800;letter-spacing:.06em}.order-summary small{color:#66585b;font-size:11px}
        .order-progress{display:flex;align-items:flex-start;justify-content:space-between;position:relative;margin:0 22px;padding:0 12px 19px}.order-progress::before{content:"";position:absolute;top:10px;right:12%;left:12%;height:2px;background:#e7ddd7}.progress-step{position:relative;z-index:1;display:grid;justify-items:center;gap:6px;min-width:70px;color:#66585b;font-size:10px}.progress-dot{width:22px;height:22px;display:grid;place-items:center;border:2px solid #ded3cd;border-radius:50%;background:#fff;color:#66585b;font-size:10px;font-weight:700}.progress-step.complete .progress-dot,.progress-step.current .progress-dot{border-color:#c98b6b;background:#c98b6b;color:#fff}.progress-step.current{color:#4a1233;font-weight:800}
        .order-actions{display:flex;align-items:center;justify-content:flex-end;gap:9px;flex-wrap:wrap;border-top:1px solid #eee6e1;padding:14px 22px}.order-actions form{margin:0}.order-actions a,.order-actions button{min-height:38px;display:inline-flex;align-items:center;justify-content:center;border-radius:999px;padding:0 15px;font-family:Inter,ui-sans-serif,sans-serif;font-size:12px;font-weight:700;text-decoration:none;cursor:pointer;transition:background .18s ease,border-color .18s ease,color .18s ease}.action-primary{border:1px solid #4a1233;background:#4a1233;color:#fff}.action-primary:hover{background:#351025}.action-outline{border:1px solid #c98b6b;background:#fff;color:#4a1233}.action-outline:hover{background:#f8eee8}.action-ghost{border:1px solid transparent;background:transparent;color:#4a1233}.action-ghost:hover{background:#f7eee9}.order-actions .action-cancel{border:0;background:transparent;color:#a23e3b}.request-status{color:#4a1233;font-size:12px;font-weight:700}
        .order-actions :focus-visible,.orders-filter-form :focus-visible,.orders-tabs a:focus-visible{outline:3px solid #c98b6b;outline-offset:3px}
        .summary-line span{color:#66585b}
        @media(max-width:1399px){.order-card{display:block;padding:0}.orders-header{display:flex;grid-template-columns:none}.order-actions{grid-column:auto}.details-button{width:auto}}
        @media(max-width:1023px) and (min-width:721px){.orders-header{align-items:flex-start}.orders-filter-form{width:66%;max-width:none}.orders-title{font-size:42px}.order-card-body{gap:15px}.product-thumb{width:54px;height:54px}}
        @media(max-width:720px){.orders-header{display:grid;grid-template-columns:1fr;gap:16px;align-items:stretch}.orders-title{font-size:38px}.orders-filter-form{width:100%;display:grid;grid-template-columns:minmax(0,1fr) 140px;gap:8px}.search-field{grid-column:1/-1;width:100%}.sort-field{width:100%;min-width:0;flex-basis:auto}.filter-submit{height:44px}.orders-tabs{margin-right:-20px;padding-right:20px;gap:20px}.orders-list{gap:15px}.order-card-header{padding:15px}.order-card-body{align-items:stretch;flex-direction:column;padding:16px 15px;gap:17px}.order-product{align-items:flex-start;gap:13px}.product-preview{padding-left:7px}.product-thumb{width:55px;height:55px;border-radius:12px}.product-description{padding-top:4px}.order-summary{justify-items:start;grid-template-columns:auto 1fr;align-items:center;column-gap:8px}.summary-label{grid-column:1}.order-total{grid-column:2;grid-row:1}.payment-tag{grid-column:1}.order-summary small{grid-column:2}.order-progress{margin:0 10px;padding:0 3px 16px}.progress-step{min-width:57px;font-size:9px}.order-progress::before{right:13%;left:13%}.order-actions{display:grid;grid-template-columns:1fr;padding:13px 15px}.order-actions>*{width:100%;min-width:0}.order-actions form{display:block}.order-actions form button,.order-actions a{width:100%;min-height:42px}.order-actions .request-status{grid-column:1/-1;text-align:center}.empty-orders{padding:38px 18px}.empty-orders h2{font-size:30px}}
        @media(prefers-reduced-motion:reduce){.order-card:hover{transform:none}}
    </style>
</head>
<body>
<header class="profile-topbar">
    <div class="profile-topbar-inner">
        <button type="button" class="mobile-menu-button" data-profile-menu aria-label="Open account menu">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M4 6h16"/><path d="M4 12h16"/><path d="M4 18h16"/></svg>
        </button>
        <a href="{{ route('shop.index') }}" class="profile-logo" aria-label="Lumora shop">
            <span class="profile-logo-brand">LUM<span>O</span>RA</span>
            <span class="profile-logo-tagline">Beauty lives here</span>
        </a>
        <form action="{{ route('shop.index') }}" method="GET" class="topbar-search">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="m21 21-4.3-4.3"/><circle cx="11" cy="11" r="7"/></svg>
            <input type="search" name="search" placeholder="Search Lumora" aria-label="Search Lumora">
        </form>
        <div class="topbar-actions">
            <a href="{{ route('profile.edit') }}#wishlist" class="topbar-action" aria-label="Wishlist">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8Z"/></svg>
            </a>
            <a href="{{ route('buyer.cart') }}" class="topbar-action" aria-label="Cart">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.1 2.1h3l2.7 12.4a2 2 0 0 0 2 1.6h7.8a2 2 0 0 0 2-1.6L21 7H6"/></svg>
                @if ($cartCount > 0)<span class="topbar-badge">{{ $cartCount }}</span>@endif
            </a>
        </div>
    </div>
</header>

<div class="drawer-backdrop" data-profile-backdrop></div>

<main class="profile-page">
    <div class="profile-layout">
        @include('profile.partials.account-sidebar', ['active' => 'orders'])

        <section class="orders-content">
            @if (session('success'))
                <div class="order-success-message" role="status" aria-live="polite">
                    <span>{{ session('success') }}</span>
                    <button type="button" aria-label="Dismiss message" onclick="this.parentElement.remove()">&times;</button>
                </div>
            @endif
            <nav class="breadcrumb" aria-label="Breadcrumb">
                <a href="{{ route('shop.index') }}">Home</a>
                <span>/</span>
                <a href="{{ route('profile.edit') }}">Account</a>
                <span>/</span>
                <span>My Orders</span>
            </nav>

            <header class="orders-header">
                <div>
                    <p class="orders-label">Account</p>
                    <h1 class="orders-title">My Orders</h1>
                    <p class="orders-subtitle">{{ $totalOrderCount }} {{ \Illuminate\Support\Str::plural('order', $totalOrderCount) }} placed</p>
                </div>
                <form class="orders-filter-form" method="GET" action="{{ route('buyer.orders.index') }}">
                    @if ($activeStatus !== 'all')<input type="hidden" name="status" value="{{ $activeStatus }}">@endif
                    <input class="search-field" type="search" name="search" value="{{ $search }}" placeholder="Search order number or product…" aria-label="Search order number or product">
                    <select class="sort-field" name="sort" aria-label="Sort orders" onchange="this.form.submit()">
                        <option value="latest" @selected($sort === 'latest')>Latest</option>
                        <option value="oldest" @selected($sort === 'oldest')>Oldest</option>
                        <option value="highest" @selected($sort === 'highest')>Highest total</option>
                    </select>
                    <button class="filter-submit" type="submit">Search</button>
                </form>
            </header>

            @php
                $tabLabels = [
                    'all' => 'All',
                    'pending' => 'To Pack',
                    'packed' => 'To Ship',
                    'shipped' => 'To Receive',
                    'delivered' => 'Completed',
                    'cancelled' => 'Cancelled',
                ];
            @endphp
            <nav class="orders-tabs" aria-label="Order status filters">
                @foreach ($tabLabels as $status => $label)
                    @php
                        $tabQuery = array_filter([
                            'status' => $status === 'all' ? null : $status,
                            'search' => $search ?: null,
                            'sort' => $sort !== 'latest' ? $sort : null,
                        ]);
                    @endphp
                    <a class="orders-tab {{ $activeStatus === $status ? 'active' : '' }}" href="{{ route('buyer.orders.index', $tabQuery) }}" @if($activeStatus === $status) aria-current="page" @endif>
                        {{ $label }} <span class="tab-count">{{ $status === 'all' ? $totalOrderCount : (int) $statusCounts->get($status, 0) }}</span>
                    </a>
                @endforeach
            </nav>

            @if ($orders->isEmpty())
                <section class="empty-orders" aria-labelledby="empty-orders-heading">
                    <div class="empty-icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M6 2h12v20l-3-2-3 2-3-2-3 2Z"/><path d="M9 8h6"/><path d="M9 12h6"/></svg>
                    </div>
                    <h2 id="empty-orders-heading">No orders found</h2>
                    <p>There are no orders in this view. Try another filter or browse the latest from Lumora.</p>
                    <a class="btn-primary" href="{{ route('shop.index') }}">Start shopping</a>
                </section>
            @else
                <div class="orders-list">
                    @foreach ($orders as $order)
                        @php
                            $itemCount = (int) $order->items->sum('quantity');
                            $previewItems = $order->items->take(3);
                            $remainingItems = max($order->items->count() - $previewItems->count(), 0);
                            $status = $order->status ?? 'pending';
                            $statusLabel = ucwords(str_replace('_', ' ', $status));
                            $firstItem = $order->items->first();
                            $activeProgress = in_array($status, ['pending', 'packed', 'shipped'], true);
                            $progressMap = ['pending' => 1, 'packed' => 2, 'shipped' => 3];
                            $progress = $progressMap[$status] ?? 0;
                        @endphp
                        <article class="order-card" data-order-card data-href="{{ route('buyer.orders.show', $order) }}" tabindex="0" aria-label="Order {{ $order->order_number }}, {{ $statusLabel }}. Open order details">
                            <header class="order-card-header">
                                <div class="order-info">
                                    <h2 class="order-number">{{ $order->order_number }}</h2>
                                    <div class="order-meta"><span>{{ optional($order->created_at)->format('M d, Y') }}</span><span>{{ $itemCount }} {{ \Illuminate\Support\Str::plural('item', $itemCount) }}</span></div>
                                </div>
                                <span class="status-badge status-{{ $status }}"><i aria-hidden="true"></i>{{ $statusLabel }}</span>
                            </header>

                            <div class="order-card-body">
                                <div class="order-product">
                                    <div class="product-preview" aria-label="{{ $previewItems->count() }} product thumbnails">
                                        @foreach ($previewItems as $item)
                                            @php($product = $item->product)
                                            <div class="product-thumb" title="{{ $product?->name ?? 'Product unavailable' }}">
                                                @if ($product)<img src="{{ $product->image_url }}" alt="{{ $product->name }}" loading="lazy" onerror="this.onerror=null;this.src='{{ asset('images/product-placeholder.png') }}';">@else<span>L</span>@endif
                                            </div>
                                        @endforeach
                                        @if ($remainingItems > 0)<div class="product-thumb product-more">+{{ $remainingItems }}</div>@endif
                                    </div>
                                    <div class="product-description">
                                        <strong>{{ $firstItem?->product?->name ?? 'Product unavailable' }}</strong>
                                        <span>{{ $order->items->count() > 1 ? '+'.($order->items->count() - 1).' more items' : 'Qty '.$itemCount }}</span>
                                        @if ($order->estimated_delivery && in_array($status, ['pending', 'processing', 'packed', 'shipped', 'out_for_delivery'], true))
                                            <span class="delivery-estimate">Estimated delivery {{ $order->estimated_delivery->format('M j, Y') }}</span>
                                        @endif
                                    </div>
                                </div>

                                <div class="order-summary">
                                    <span class="summary-label">Total</span>
                                    <strong class="order-total">₱{{ number_format((float) $order->total, 2) }}</strong>
                                    <span class="payment-tag">{{ strtoupper($order->payment_method) }}</span>
                                    @if (in_array($order->payment_method, ['cod', 'cash_on_delivery'], true) && $status !== 'delivered' && $status !== 'cancelled')<small>Pay upon delivery</small>@endif
                                </div>
                            </div>

                            @if ($activeProgress)
                                <div class="order-progress" role="list" aria-label="Order progress">
                                    @foreach (['Placed', 'Packed', 'Shipped', 'Delivered'] as $stepIndex => $step)
                                        @php($stepNumber = $stepIndex + 1)
                                        <div class="progress-step {{ $stepNumber < $progress ? 'complete' : ($stepNumber === $progress ? 'current' : '') }}" role="listitem" @if($stepNumber === $progress) aria-current="step" @endif>
                                            <span class="progress-dot">{{ $stepNumber < $progress ? '✓' : $stepNumber }}</span><span>{{ $step }}</span>
                                        </div>
                                    @endforeach
                                </div>
                            @endif

                            <footer class="order-actions">
                                @if ($status === 'pending')
                                    <form method="POST" action="{{ route('buyer.orders.cancel', $order) }}" onsubmit="return confirm('Cancel this order?');" data-card-action>@csrf @method('PATCH')<button class="action-cancel" type="submit">Cancel order</button></form>
                                    <a class="action-outline" href="{{ route('buyer.orders.show', $order) }}" data-card-action>View details</a>
                                @elseif (in_array($status, ['packed', 'shipped'], true))
                                    @if ($firstItem?->seller)<form method="POST" action="{{ route('buyer.chats.start-seller', $firstItem->seller) }}" data-card-action>@csrf<button class="action-ghost" type="submit">Contact seller</button></form>@endif
                                    <a class="action-primary" href="{{ route('buyer.orders.show', $order) }}#order-tracking" data-card-action>Track my order</a>
                                @elseif ($status === 'delivered')
                                    <a class="action-ghost" href="{{ route('buyer.orders.show', $order) }}" data-card-action>View details</a>
                                    @if ($firstItem?->product_id)<a class="action-outline" href="{{ route('shop.product', $firstItem->product_id) }}#reviews" data-card-action>Write a review</a>@endif
                                    <form method="POST" action="{{ route('buyer.orders.reorder', $order) }}" data-card-action>@csrf<button class="action-primary" type="submit">Buy again</button></form>
                                    @if ($returnRequestsEnabled)
                                        @if (! $order->returnRequest)<button class="action-outline" type="button" data-return-open="{{ $order->id }}" data-card-action>Return / Refund</button>@else<span class="request-status">Return request {{ ucfirst(str_replace('_', ' ', $order->returnRequest->status)) }}</span>@endif
                                    @endif
                                @else
                                    <a class="action-ghost" href="{{ route('buyer.orders.show', $order) }}" data-card-action>View details</a>
                                @endif
                            </footer>
                        </article>
                    @endforeach
                </div>

                <div class="pagination-row">
                    <p>
                        Showing {{ $orders->firstItem() }}-{{ $orders->lastItem() }} of {{ $orders->total() }} orders
                    </p>
                    <nav class="pagination-links" aria-label="Orders pagination">
                        @if ($orders->onFirstPage())
                            <span class="disabled">Previous</span>
                        @else
                            <a href="{{ $orders->previousPageUrl() }}">Previous</a>
                        @endif

                        @foreach ($orders->getUrlRange(1, $orders->lastPage()) as $page => $url)
                            @if ($page === $orders->currentPage())
                                <span class="active">{{ $page }}</span>
                            @else
                                <a href="{{ $url }}">{{ $page }}</a>
                            @endif
                        @endforeach

                        @if ($orders->hasMorePages())
                            <a href="{{ $orders->nextPageUrl() }}">Next</a>
                        @else
                            <span class="disabled">Next</span>
                        @endif
                    </nav>
                </div>
            @endif
        </section>
    </div>
</main>

@foreach ($orders as $order)
    @if ($returnRequestsEnabled && $order->status === 'delivered' && ! $order->returnRequest)
        <div class="return-modal" id="return-modal-{{ $order->id }}" hidden>
            <section class="return-dialog" role="dialog" aria-modal="true" aria-labelledby="return-title-{{ $order->id }}">
                <h2 id="return-title-{{ $order->id }}">Return / Refund Request</h2>
                <p>Order {{ $order->order_number }} · Tell us what happened and attach up to five photos or videos as proof.</p>
                <form method="POST" action="{{ route('buyer.orders.return-request', $order) }}" enctype="multipart/form-data">
                    @csrf
                    <label for="reason-{{ $order->id }}">Reason</label>
                    <select id="reason-{{ $order->id }}" name="reason" required>
                        <option value="">Choose a reason</option>
                        <option value="damaged">Item arrived damaged</option><option value="wrong_item">Wrong item received</option>
                        <option value="missing_items">Item or parts are missing</option><option value="not_as_described">Not as described</option>
                        <option value="changed_mind">Changed my mind</option><option value="other">Other</option>
                    </select>
                    <label for="details-{{ $order->id }}">What happened?</label>
                    <textarea id="details-{{ $order->id }}" name="details" minlength="10" maxlength="2000" required placeholder="Please share details to help us review your request."></textarea>
                    <label for="evidence-{{ $order->id }}">Proof (optional)</label>
                    <input id="evidence-{{ $order->id }}" type="file" name="evidence[]" accept="image/jpeg,image/png,image/webp,video/mp4,video/quicktime,video/webm" multiple>
                    <p>Up to 5 files, 50 MB each. Images and videos are accepted.</p>
                    <div class="return-modal-actions"><button class="return-cancel" type="button" data-return-close>Cancel</button><button class="return-submit" type="submit">Submit Request</button></div>
                </form>
            </section>
        </div>
    @endif
@endforeach

<script>
document.querySelectorAll('[data-return-open]').forEach((button) => button.addEventListener('click', () => {
    const modal = document.getElementById(`return-modal-${button.dataset.returnOpen}`);
    if (modal) { modal.hidden = false; modal.querySelector('select')?.focus(); }
}));
document.querySelectorAll('[data-order-card]').forEach((card) => {
    card.addEventListener('click', (event) => {
        if (event.target.closest('[data-card-action]') || event.target.closest('button, a, form, input, select, textarea, label')) return;
        window.location.href = card.dataset.href;
    });
    card.addEventListener('keydown', (event) => {
        if (event.target === card && (event.key === 'Enter' || event.key === ' ')) {
            event.preventDefault();
            window.location.href = card.dataset.href;
        }
    });
});
document.querySelectorAll('[data-return-close]').forEach((button) => button.addEventListener('click', () => { button.closest('.return-modal').hidden = true; }));
document.querySelectorAll('.return-modal').forEach((modal) => modal.addEventListener('click', (event) => { if (event.target === modal) modal.hidden = true; }));
document.addEventListener('keydown', (event) => { if (event.key === 'Escape') document.querySelectorAll('.return-modal:not([hidden])').forEach((modal) => { modal.hidden = true; }); });
document.querySelectorAll('input[type="file"][name="evidence[]"]').forEach((input) => input.addEventListener('change', () => {
    if (input.files.length > 5) { alert('Please select no more than 5 files.'); input.value = ''; }
}));
</script>

@auth
    @include('components.chat-widget')
@endauth

</body>
</html>
