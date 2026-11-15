<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Lumora | Checkout</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Playfair+Display:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --plum: #4a1233;
            --plum-dark: #2c102c;
            --rose: #c98b6b;
            --rose-soft: #d5a187;
            --gold: #c9972b;
            --cream: #fffdfb;
            --blush: #fbefea;
            --blush-deep: #f3d8de;
            --ink: #3a2e30;
            --muted: #8a7b7e;
            --line: #ebddd8;
        }

        * { box-sizing: border-box; }
        html, body { min-height: 100%; }
        body {
            margin: 0;
            color: var(--ink);
            font-family: Inter, Arial, sans-serif;
            background: linear-gradient(135deg, #fffdfb 0%, #fbefea 44%, #f3d8de 100%);
        }
        a { color: inherit; text-decoration: none; }
        a:focus-visible, button:focus-visible, input:focus-visible, textarea:focus-visible { outline:3px solid rgba(201,139,107,.55); outline-offset:3px; }
        [hidden] { display:none !important; }
        h1, h2, h3 { margin: 0; color: var(--plum); font-family: 'Playfair Display', Georgia, serif; font-weight: 600; }

        .checkout-header {
            height: 106px;
            background: rgba(255, 253, 251, .96);
            border-bottom: 1px solid var(--line);
        }
        .header-inner {
            width: min(1380px, calc(100% - 96px));
            height: 100%;
            margin: 0 auto;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .steps {
            display: flex;
            align-items: center;
            gap: 23px;
            color: var(--muted);
            font-size: 15px;
        }
        .step { display: flex; align-items: center; gap: 18px; white-space: nowrap; }
        .step.active { color: var(--plum); font-weight: 600; }
        .mobile-steps { display:none; }
        .step.active::after {
            content: '';
            position: absolute;
            margin-top: 55px;
            margin-left: 10px;
            width: 58px;
            height: 2px;
            background: var(--gold);
        }
        .chevron { color: #b9a7a7; font-size: 25px; font-weight: 300; }
        .secure { display: flex; align-items: center; gap: 10px; color: var(--ink); font-size: 14px; }
        .lock { display: inline-flex; color: var(--gold); }

        .page {
            width: min(1380px, calc(100% - 96px));
            margin: 0 auto;
            padding: 54px 0 100px;
        }
        .page-title { margin-bottom: 29px; font-size: 47px; line-height: 1; }
        .layout {
            display: grid;
            grid-template-columns: minmax(0, 1.55fr) minmax(360px, .85fr);
            gap: 62px;
            align-items: start;
        }
        .left-column { min-width: 0; }
        .card {
            background: rgba(255, 253, 251, .91);
            border: 1px solid var(--line);
            border-radius: 22px;
            box-shadow: 0 8px 30px rgba(61, 27, 61, .035);
        }
        .delivery-card { padding: 29px 34px 27px; }
        .card-title { font-size: 29px; line-height: 1; margin-bottom: 25px; }
        .delivery-heading { display:flex; align-items:center; justify-content:space-between; gap:16px; margin-bottom:25px; }
        .delivery-heading .card-title { margin:0; }
        .add-address-button { display:inline-flex; min-height:42px; flex:0 0 auto; align-items:center; justify-content:center; gap:8px; padding:0 15px; border:1px solid var(--plum); border-radius:9px; background:transparent; color:var(--plum); font:600 13px Inter,Arial,sans-serif; cursor:pointer; transition:background .18s ease,color .18s ease; }
        .add-address-button:hover { background:var(--plum); color:#fff; }
        .delivery-address-select { width:min(100%,440px); min-height:43px; margin:0 0 18px; padding:0 12px; border:1px solid var(--line); border-radius:9px; background:#fff; color:var(--plum); font:500 13px Inter,Arial,sans-serif; }
        .delivery-address-label { display:block; margin-bottom:7px; color:var(--muted); font-size:11px; font-weight:700; letter-spacing:.04em; text-transform:uppercase; }
        .selected-address-display { min-width:0; }
        .selected-address-label { display:inline-flex; margin:0 0 8px; padding:4px 9px; border-radius:999px; background:#fbefea; color:var(--plum); font-size:10px; font-weight:700; text-transform:capitalize; }
        .address-empty { margin:0 0 18px; padding:15px 17px; border:1px dashed var(--rose-soft); border-radius:12px; background:#fffaf7; color:var(--muted); font-size:13px; line-height:1.55; }
        .address-management-actions { display:flex; align-items:center; gap:10px; margin-top:10px; flex-wrap:wrap; }
        .address-management-actions button { min-height:34px; padding:0 12px; border:1px solid var(--rose-soft); border-radius:999px; background:#fff; color:var(--plum); font-size:12px; font-weight:700; cursor:pointer; }
        .address-management-actions button:hover { background:#fbefea; }
        .address-management-actions .address-delete { color:#8f3447; }
        .address-row { display: flex; align-items: center; gap: 31px; }
        .pin {
            width: 90px;
            height: 90px;
            flex: 0 0 90px;
            display: grid;
            place-items: center;
            color: var(--rose);
            background: #fcedeb;
            border-radius: 50%;
            font-size: 38px;
        }
        .address-copy {
            min-height: 90px;
            padding-left: 31px;
            border-left: 1px solid var(--line);
            font-size: 15px;
            line-height: 1.52;
        }
        .address-name { margin-bottom: 4px; color: var(--ink); font-weight: 600; font-size: 16px; }
        .contact { margin-top: 6px; color: var(--ink); }
        .address-actions { display:flex; align-items:center; gap:12px; margin-top:10px; flex-wrap:wrap; }
        .address-change { display:inline-flex; align-items:center; min-height:34px; padding:0 13px; border:1px solid var(--rose-soft); border-radius:999px; background:#fff; color:var(--plum); font-size:12px; font-weight:700; }
        .delivery-notes { width:100%; min-height:74px; margin-top:18px; padding:12px 14px; resize:vertical; border:1px solid var(--line); border-radius:10px; background:#fff; color:var(--ink); font:13px Inter,Arial,sans-serif; }
        .delivery-notes:focus-visible { outline:3px solid rgba(201,139,107,.35); outline-offset:2px; }
        .address-modal { position:fixed; inset:0; z-index:1100; display:none; align-items:center; justify-content:center; padding:20px; background:rgba(37,17,38,.56); backdrop-filter:blur(3px); }
        .address-modal.is-open { display:flex; }
        .address-modal-card { position:relative; width:min(720px,100%); max-height:min(90vh,820px); overflow:auto; padding:30px; border:1px solid var(--line); border-radius:18px; background:#fffdfb; box-shadow:0 24px 70px rgba(37,17,38,.24); }
        .address-modal-heading { display:flex; align-items:flex-start; justify-content:space-between; gap:14px; margin-bottom:22px; }
        .address-modal-heading h2 { margin:0 0 6px; font:600 27px/1.15 'Playfair Display',Georgia,serif; }
        .address-modal-heading p { margin:0; color:var(--muted); font-size:13px; }
        .address-modal-close { display:grid; width:40px; height:40px; flex:0 0 40px; place-items:center; border:1px solid var(--line); border-radius:50%; background:#fff; color:var(--plum); font-size:23px; cursor:pointer; }
        .address-form-grid { display:grid; grid-template-columns:1fr 1fr; gap:14px; }
        .address-form-field { display:grid; gap:6px; min-width:0; }
        .address-form-field.full { grid-column:1/-1; }
        .address-form-field label { color:var(--plum); font-size:12px; font-weight:700; }
        .address-form-field input,.address-form-field select { width:100%; min-height:44px; padding:0 11px; border:1px solid #ded2cc; border-radius:8px; background:#fff; color:var(--ink); font:13px Inter,Arial,sans-serif; }
        .address-default-choice { display:flex; grid-column:1/-1; align-items:center; gap:9px; color:var(--ink); font-size:13px; }
        .address-default-choice input { width:18px; height:18px; accent-color:var(--plum); }
        .address-modal-error { grid-column:1/-1; margin:0; color:#9f3349; font-size:12px; line-height:1.5; }
        .address-modal-actions { display:flex; justify-content:flex-end; gap:10px; margin-top:22px; }
        .address-modal-actions button { min-height:44px; padding:0 18px; border:1px solid var(--plum); border-radius:9px; background:#fff; color:var(--plum); font:600 13px Inter,Arial,sans-serif; cursor:pointer; }
        .address-modal-actions .address-save { background:var(--plum); color:#fff; }
        .items-card { margin-top: 16px; padding: 27px 34px 17px; }
        .items-card .card-title { margin-bottom: 14px; }
        .item {
            min-height: 113px;
            display: flex;
            align-items: center;
            gap: 29px;
            border-top: 1px solid var(--line);
        }
        .item-image {
            width: 160px;
            height: 96px;
            flex: 0 0 160px;
            border-radius: 8px;
            object-fit: cover;
            background: #f2e8e3;
        }
        .item-details { flex: 1; min-width: 0; }
        .item-name { color: var(--ink); font: 600 17px/1.2 Inter, Arial, sans-serif; }
        .item-meta { margin-top: 8px; color: var(--muted); font-size: 14px; }
        .quantity-control { display:flex; align-items:center; gap:7px; }
        .quantity-button { width:30px; height:30px; border:1px solid var(--line); border-radius:50%; background:#fff; color:var(--plum); font-size:17px; cursor:pointer; }
        .quantity-button:disabled { opacity:.4; cursor:not-allowed; }
        .quantity-value { min-width:22px; color:var(--ink); font-size:13px; text-align:center; }
        .item-price { width:140px; color:var(--plum); font-size:16px; font-weight:600; text-align:right; white-space:nowrap; }
        .item-price-current { display:block; }
        .item-price-original { display:block; color:var(--muted); font-size:12px; font-weight:400; }
        .discount-chip, .method-chip { display:inline-flex; align-items:center; border-radius:999px; background:#fbefea; padding:3px 8px; color:var(--plum); font-size:10px; font-weight:700; }
        .return-link { display: inline-flex; gap: 11px; margin-top: 24px; color: var(--rose); font-size: 14px; text-decoration: underline; text-underline-offset: 3px; }

        .summary-card {
            position: sticky;
            top: 25px;
            min-height: 610px;
            padding: 34px 42px 31px;
            overflow: hidden;
        }
        .summary-card::after {
            content: '';
            position: absolute;
            width: 250px;
            height: 180px;
            right: -88px;
            bottom: -55px;
            border: 1px solid rgba(201, 151, 43, .45);
            border-radius: 50% 40% 0 50%;
            transform: rotate(-24deg);
            opacity: .45;
        }
        .summary-title { padding-bottom: 23px; border-bottom: 1px solid #d8c9bd; font-size: 30px; }
        .summary-row { display: flex; justify-content: space-between; gap: 20px; margin-top: 23px; color: var(--ink); font-size: 15px; }
        .summary-row strong { font-weight: 500; }
        .summary-row.discount strong { color: var(--rose); }
        .voucher-box { margin-top: 24px; padding-top: 20px; border-top: 1px dashed #d8c9bd; position: relative; z-index: 1; }
        .voucher-label { display: flex; align-items: center; justify-content: space-between; margin-bottom: 9px; color: var(--plum); font-size: 13px; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; }
        .voucher-input-group { display: flex; gap: 8px; align-items: stretch; }
        .voucher-input { flex: 1; min-width: 0; height: 44px; padding: 0 14px; border: 1px solid var(--line); border-radius: 8px; background: #fffdfb; color: var(--plum); font: 600 13px Inter, Arial, sans-serif; letter-spacing: .04em; text-transform: uppercase; outline: none; transition: border-color .2s ease, box-shadow .2s ease; }
        .voucher-input::placeholder { color: var(--muted); font-weight: 400; letter-spacing: normal; text-transform: none; }
        .voucher-input:focus { border-color: var(--rose); box-shadow: 0 0 0 3px rgba(185, 101, 98, .12); }
        .voucher-apply-btn { height: 44px; padding: 0 18px; border: 1px solid var(--plum); border-radius: 8px; background: var(--plum); color: #fff; font: 600 13px Inter, Arial, sans-serif; cursor: pointer; white-space: nowrap; transition: background .2s ease, transform .15s ease; }
        .voucher-apply-btn:hover { background: var(--plum-dark); transform: translateY(-1px); }
        .voucher-feedback { margin-top: 8px; font-size: 12px; line-height: 1.4; display: none; }
        .voucher-feedback.success { display: flex; align-items: center; justify-content: space-between; gap: 8px; color: #4f7a5a; font-weight: 600; }
        .voucher-feedback.error { display: block; color: var(--rose); font-weight: 500; }
        .voucher-remove-btn { border: 0; background: transparent; color: var(--rose); font-size: 11px; font-weight: 700; text-decoration: underline; cursor: pointer; padding: 0; }
        .summary-total { display: flex; justify-content: space-between; margin-top: 22px; padding-top: 24px; border-top: 1px solid #d8c9bd; color: var(--plum); font: 600 29px 'Playfair Display', Georgia, serif; }
        .savings-line { margin:7px 0 0; color:#39704c; font-size:12px; font-weight:700; text-align:right; }
        .payment-label { display: block; margin-top: 39px; margin-bottom: 14px; color: var(--plum); font: 600 21px 'Playfair Display', Georgia, serif; }
        .payment-option {
            display: flex;
            align-items: center;
            gap: 15px;
            margin-bottom: 10px;
            min-height: 61px;
            padding: 0 17px;
            border: 1px solid var(--rose-soft);
            border-radius: 8px;
            color: var(--ink);
            font-size: 15px;
        }
        .payment-option input { width: 21px; height: 21px; accent-color: var(--plum); }
        .payment-option span small { display: block; margin-top: 3px; color: var(--muted); font-size: 12px; }
        .payment-card {
            margin-top: 36px;
            padding-top: 27px;
            border-top: 1px solid #d8c9bd;
        }
        .payment-card-head {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 18px;
            margin-bottom: 16px;
        }
        .payment-card-title {
            margin: 0;
            color: var(--plum);
            font: 600 26px/1 'Playfair Display', Georgia, serif;
        }
        .payment-card-subtitle {
            margin: 7px 0 0;
            color: var(--muted);
            font-size: 13px;
            line-height: 1.55;
        }
        .manage-wallet {
            flex: 0 0 auto;
            color: var(--rose);
            font-size: 12px;
            font-weight: 700;
            text-decoration: underline;
            text-underline-offset: 3px;
        }
        .payment-options,
        .wallet-list {
            display: grid;
            gap: 10px;
        }
        .payment-radio-card,
        .wallet-card {
            display: grid;
            grid-template-columns: auto minmax(0, 1fr);
            gap: 12px;
            align-items: flex-start;
            min-height: 62px;
            margin: 0;
            border: 1px solid var(--line);
            border-radius: 14px;
            background: rgba(255, 253, 251, .78);
            padding: 13px 14px;
            color: var(--ink);
            cursor: pointer;
            transition: border-color .2s ease, background-color .2s ease;
        }
        .payment-radio-card:has(input:checked),
        .wallet-card:has(input:checked) {
            border-color: var(--rose-soft);
            background: #fff7f3;
        }
        .payment-radio-card:focus-within, .wallet-card:focus-within { outline:3px solid rgba(201,139,107,.38); outline-offset:2px; }
        .payment-radio-card input,
        .wallet-card input {
            width: 19px;
            height: 19px;
            margin-top: 2px;
            accent-color: var(--plum);
        }
        .payment-explanation { display:none; margin:7px 2px 2px 31px; color:#5f5053; font-size:12px; line-height:1.5; }
        .payment-explanation.is-visible { display:block; }
        .payment-radio-card strong,
        .wallet-card strong {
            display: block;
            color: var(--plum);
            font-size: 14px;
            font-weight: 700;
        }
        .payment-radio-card strong .method-chip { display:inline-flex; width:max-content; margin:0 0 0 8px; padding:3px 8px; font-size:10px; vertical-align:middle; }
        .payment-radio-card span,
        .wallet-card span {
            display: block;
            margin-top: 4px;
            color: var(--muted);
            font-size: 12px;
            line-height: 1.45;
        }
        .wallet-title-row {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }
        .wallet-section-title {
            margin: 19px 0 10px;
            color: var(--plum);
            font-size: 12px;
            font-weight: 800;
            letter-spacing: .08em;
            text-transform: uppercase;
        }
        .wallet-badge {
            display: inline-flex;
            align-items: center;
            min-height: 20px;
            border-radius: 999px;
            background: rgba(111, 143, 120, .13);
            padding: 0 8px;
            color: #6F8F78;
            font-size: 10px;
            font-weight: 800;
            text-transform: uppercase;
        }
        .payment-note {
            margin: 8px 0 0 31px;
            color: var(--muted);
            font-size: 12px;
            line-height: 1.45;
        }
        .payment-note a {
            color: var(--rose);
            font-weight: 700;
            text-decoration: underline;
            text-underline-offset: 3px;
        }
        .payment-error {
            display: block;
            margin-top: 10px;
            color: var(--rose);
            font-size: 12px;
            line-height: 1.45;
        }
        .wallet-modal-backdrop { position:fixed; inset:0; z-index:1000; display:grid; place-items:center; padding:20px; background:rgba(35,20,28,.62); }
        .wallet-modal-backdrop[hidden] { display:none; }
        .wallet-modal { width:min(100%,560px); max-height:min(92vh,900px); overflow:auto; padding:24px; border-radius:18px; background:#fff; box-shadow:0 22px 70px rgba(0,0,0,.24); }
        .wallet-modal-head { display:flex; justify-content:space-between; align-items:flex-start; gap:16px; margin-bottom:14px; }
        .wallet-modal-head h2 { color:var(--plum); font:600 25px 'Playfair Display',Georgia,serif; }
        .wallet-modal-close { border:0; background:none; color:var(--muted); font-size:26px; cursor:pointer; }
        .wallet-qr { display:block; width:min(100%,300px); margin:0 auto 12px; border:1px solid #eee; border-radius:8px; }
        .wallet-modal-note { margin:10px 0; color:var(--muted); font-size:13px; line-height:1.5; }
        .wallet-modal label { display:block; margin-top:14px; color:var(--plum); font-size:13px; font-weight:700; }
        .wallet-modal input[type=file] { display:block; width:100%; margin-top:7px; padding:10px; border:1px solid #e8d8d7; border-radius:8px; }
        .reference-slots { display:flex; gap:8px; margin-top:8px; }
        .reference-slots input { width:42px; height:48px; border:1px solid #dfcecc; border-radius:8px; text-align:center; font-size:20px; color:var(--plum); }
        .wallet-modal-actions { display:flex; justify-content:flex-end; gap:10px; margin-top:20px; }
        .wallet-modal-actions button { padding:11px 17px; border:1px solid #e8d8d7; border-radius:8px; background:#fff; color:var(--plum); font:inherit; font-size:14px; font-weight:600; cursor:pointer; }
        .wallet-modal-actions .confirm { background:var(--plum); border-color:var(--plum); color:#fff; }
        @media(max-width:420px) { .wallet-modal { padding:18px; } .reference-slots { gap:5px; } .reference-slots input { width:calc((100vw - 100px)/6); max-width:42px; } }
        .place-order {
            width: 100%;
            height: 69px;
            margin-top: 31px;
            border: 0;
            border-radius: 8px;
            background: var(--plum);
            color: white;
            font: 500 20px 'Playfair Display', Georgia, serif;
            cursor: pointer;
            transition: background .2s ease, transform .2s ease;
        }
        .place-order:hover { background: var(--plum-dark); transform: translateY(-1px); }
        .place-order:disabled { opacity:.68; cursor:wait; transform:none; }
        .order-legal { margin:12px 0 0; color:#63565a; font-size:11px; line-height:1.6; text-align:center; }
        .order-legal a { color:var(--plum); text-decoration:underline; text-underline-offset:2px; }
        .secure-returns { margin:7px 0 0; color:#63565a; font-size:11px; text-align:center; }
        .mobile-checkout-bar { display:none; }
        .success-message { margin:0 0 12px; padding:10px 12px; border-radius:10px; background:#edf6ef; color:#315d3d; font-size:12px; }
        .error { margin-bottom: 18px; padding: 12px 15px; border-radius: 8px; color: var(--rose); background: #fff3e9; font-size: 13px; }

        @media (max-width: 900px) {
            .header-inner, .page { width: min(100% - 44px, 850px); }
            .steps { gap:9px; font-size:12px; }
            .step { gap:7px; }
            .layout { grid-template-columns: 1fr; gap: 24px; }
            .summary-card { position: static; min-height: auto; }
        }
        @media (max-width: 620px) {
            .checkout-header { height: 78px; }
            .header-inner, .page { width: calc(100% - 32px); }
            .secure { font-size: 12px; }
            .page { padding-top: 31px; }
            .page-title { font-size: 38px; }
            .steps { display:none; }
            .mobile-steps { display:flex; align-items:center; gap:10px; margin:-14px 0 24px; color:var(--muted); font-size:11px; }
            .mobile-steps strong { color:var(--plum); }
            .delivery-card, .items-card, .summary-card { padding: 22px 18px; }
            .card-title, .summary-title { font-size: 25px; }
            .address-row { gap: 16px; align-items: flex-start; }
            .pin { width: 58px; height: 58px; flex-basis: 58px; font-size: 25px; }
            .address-copy { padding-left: 16px; font-size: 12px; }
            .delivery-heading { align-items:flex-start; margin-bottom:20px; }
            .delivery-heading .card-title { font-size:23px; line-height:1.1; }
            .add-address-button { min-height:40px; padding:0 10px; font-size:11px; }
            .address-modal { align-items:flex-end; padding:0; }
            .address-modal-card { width:100%; max-height:92vh; padding:23px 18px calc(22px + env(safe-area-inset-bottom)); border-radius:18px 18px 0 0; }
            .address-form-grid { grid-template-columns:1fr; gap:12px; }
            .address-form-field.full,.address-default-choice,.address-modal-error { grid-column:auto; }
            .item { gap: 10px; flex-wrap:wrap; padding:12px 0; }
            .item-image { width: 76px; height: 68px; flex-basis: 76px; }
            .item-name { font-size: 13px; }
            .item-meta { font-size: 11px; }
            .item-price { width:auto; margin-left:auto; font-size:12px; }
            .quantity-control { margin-left:88px; }
            .payment-card-head { flex-direction: column; gap: 8px; }
            .manage-wallet { align-self: flex-start; }
            .mobile-checkout-bar { position:fixed; z-index:900; right:0; bottom:0; left:0; display:flex; align-items:center; justify-content:space-between; gap:12px; padding:11px 16px calc(11px + env(safe-area-inset-bottom)); border-top:1px solid var(--line); background:rgba(255,253,251,.97); box-shadow:0 -8px 25px rgba(61,27,61,.09); }
            .mobile-checkout-total { color:var(--plum); font:600 18px 'Playfair Display',Georgia,serif; white-space:nowrap; }
            .mobile-checkout-bar .place-order { width:auto; height:48px; min-width:170px; margin:0; padding:0 16px; font:600 13px Inter,Arial,sans-serif; }
            body { padding-bottom:78px; }
        }
    </style>
</head>
<body>
<header class="checkout-header">
    <div class="header-inner">
        <x-logo :href="route('shop.index')" aria-label="Lumora shop" />
        <nav class="steps" aria-label="Checkout progress">
            <span class="step">Cart <span class="chevron">&rsaquo;</span></span>
            <span class="step active">Checkout <span class="chevron">&rsaquo;</span></span>
            <span class="step">Done</span>
        </nav>
        <div class="secure"><span class="lock" aria-hidden="true"><svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="5" y="10" width="14" height="11" rx="2"></rect><path d="M8 10V7a4 4 0 0 1 8 0v3"></path></svg></span> Secure checkout</div>
    </div>
</header>

<main class="page">
    <h1 class="page-title">Checkout</h1>
    <nav class="mobile-steps" aria-label="Checkout progress"><span>Cart</span><span aria-hidden="true">›</span><strong aria-current="step">Checkout</strong><span aria-hidden="true">›</span><span>Done</span></nav>

    @if($errors->any())
        <div class="error">{{ $errors->first() }}</div>
    @endif

    <div class="layout">
        <section class="left-column">
            <div class="card delivery-card">
                <div class="delivery-heading">
                    <h2 class="card-title">Delivery information</h2>
                    <button class="add-address-button" type="button" id="addAddressButton"><span aria-hidden="true">+</span> Add Address</button>
                </div>
                <p class="address-empty" id="addressEmptyPrompt" @if($addresses->isNotEmpty()) hidden @endif>You have no saved delivery addresses yet. Add one to continue with checkout.</p>
                @if($addresses->isNotEmpty())
                    <label class="delivery-address-label" for="deliveryAddressSelect">Deliver to</label>
                    <select class="delivery-address-select" id="deliveryAddressSelect" aria-label="Select delivery address">
                        @foreach($addresses as $savedAddress)
                            <option value="{{ $savedAddress->id }}" @selected((int) $selectedAddressId === (int) $savedAddress->id)>{{ ucfirst($savedAddress->label) }} · {{ $savedAddress->full_name }}{{ $savedAddress->is_default ? ' · Default' : '' }}</option>
                        @endforeach
                    </select>
                    <input type="hidden" id="checkoutAddressId" name="address_id" form="checkoutForm" value="{{ $selectedAddressId }}">
                    <div class="address-row" id="selectedAddressRow" @if(!$selectedAddress) hidden @endif>
                        <div class="pin" aria-hidden="true"><svg viewBox="0 0 24 24" width="38" height="38" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M20 10c0 5-8 11-8 11S4 15 4 10a8 8 0 1 1 16 0Z"></path><circle cx="12" cy="10" r="2.7"></circle></svg></div>
                        <div class="address-copy selected-address-display" id="selectedAddressDisplay">
                            @if($selectedAddress)
                                <span class="selected-address-label" data-address-label>{{ ucfirst($selectedAddress->label) }}{{ $selectedAddress->is_default ? ' · Default' : '' }}</span>
                                <div class="address-name" data-address-name>{{ $selectedAddress->full_name }}</div>
                                <span data-address-street>{{ $selectedAddress->street_address }}</span><br>
                                <span data-address-locality>{{ $selectedAddress->barangay }}, {{ $selectedAddress->city_municipality }}, {{ $selectedAddress->province }}, {{ $selectedAddress->region }}</span><br>
                                <span>Philippines · <span data-address-postal>{{ $selectedAddress->postal_code }}</span></span><br>
                                <div class="contact" data-address-phone>{{ $selectedAddress->phone_number }}</div>
                            @endif
                            <div class="address-management-actions" id="addressManagementActions" @if(!$selectedAddress) hidden @endif>
                                <button type="button" id="editAddressButton">Edit address</button>
                                <button type="button" class="address-delete" id="deleteAddressButton">Delete address</button>
                            </div>
                        </div>
                    </div>
                @else
                    <input type="hidden" id="checkoutAddressId" name="address_id" form="checkoutForm" value="">
                    <div class="address-row" id="selectedAddressRow" hidden>
                        <div class="pin" aria-hidden="true"><svg viewBox="0 0 24 24" width="38" height="38" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M20 10c0 5-8 11-8 11S4 15 4 10a8 8 0 1 1 16 0Z"></path><circle cx="12" cy="10" r="2.7"></circle></svg></div>
                        <div class="address-copy selected-address-display" id="selectedAddressDisplay">
                            <span class="selected-address-label" data-address-label></span>
                            <div class="address-name" data-address-name></div>
                            <span data-address-street></span><br>
                            <span data-address-locality></span><br>
                            <span>Philippines · <span data-address-postal></span></span><br>
                            <div class="contact" data-address-phone></div>
                            <div class="address-management-actions" id="addressManagementActions" hidden>
                                <button type="button" id="editAddressButton">Edit address</button>
                                <button type="button" class="address-delete" id="deleteAddressButton">Delete address</button>
                            </div>
                        </div>
                    </div>
                @endif
                @error('address_id')<span class="payment-error" role="alert">{{ $message }}</span>@enderror
                <label class="delivery-notes-label" for="deliveryNotes">Delivery notes for the rider (optional)</label>
                <textarea class="delivery-notes" id="deliveryNotes" name="delivery_notes" form="checkoutForm" maxlength="200" placeholder="Gate code, landmark, or delivery instructions (200 characters max)">{{ old('delivery_notes') }}</textarea>
                @error('delivery_notes')<span class="payment-error" role="alert">{{ $message }}</span>@enderror
            </div>

            <div class="card items-card">
                <h2 class="card-title">Items to purchase</h2>
                @foreach($cartItems as $item)
                    @php
                        $product = $item['product'];
                        $quantity = (int) old('quantities.'.$item['product_id'], $item['quantity']);
                        $discountPercent = (float) ($product->discount_percent ?? 0);
                        $sellerName = $product->seller?->name ?? 'Lumora seller';
                    @endphp
                    <div class="item" data-checkout-item data-product-id="{{ $item['product_id'] }}" data-cart-update-url="{{ route('buyer.cart.update', $product) }}" data-cart-sync="{{ ($checkoutMode ?? 'cart') === 'cart' ? 'true' : 'false' }}" data-original-unit="{{ $item['original_price'] }}" data-sale-unit="{{ $item['unit_price'] }}" data-discount-percent="{{ $discountPercent }}">
                        <img class="item-image" src="{{ $product->image_url }}" alt="{{ $product->name }}" loading="lazy" onerror="this.onerror=null;this.src='{{ asset('images/product-placeholder.png') }}';">
                        <div class="item-details">
                            <div class="item-name">{{ $product->name }}</div>
                            <div class="item-meta">
                                @if(filled($product->size))Size {{ $product->size }} &middot; @endif
                                @if(filled($product->variant_type)){{ \Illuminate\Support\Str::headline($product->variant_type) }} &middot; @endif
                                {{ $sellerName }}
                            </div>
                            <div class="quantity-control" aria-label="Quantity for {{ $product->name }}">
                                <button class="quantity-button" type="button" data-quantity-decrement aria-label="Decrease quantity for {{ $product->name }}" @disabled($quantity <= 1)>&#8722;</button>
                                <output class="quantity-value" data-quantity-output>{{ $quantity }}</output>
                                <button class="quantity-button" type="button" data-quantity-increment aria-label="Increase quantity for {{ $product->name }}" @disabled($quantity >= min((int) $product->stock, 99))>+</button>
                                <span class="sr-only">Quantity: {{ $quantity }}</span>
                            </div>
                            <input type="hidden" form="checkoutForm" name="quantities[{{ $item['product_id'] }}]" value="{{ $quantity }}" data-quantity-input data-max-quantity="{{ min((int) $product->stock, 99) }}">
                        </div>
                        <div class="item-price" data-item-price>
                            <span class="item-price-current">&#8369;{{ number_format($item['line_total'], 2) }}</span>
                            @if($discountPercent > 0)
                                <del class="item-price-original">&#8369;{{ number_format($item['original_price'] * $quantity, 2) }}</del>
                                <span class="discount-chip">{{ rtrim(rtrim(number_format($discountPercent, 2), '0'), '.') }}% off</span>
                            @endif
                        </div>
                    </div>
                @endforeach
            </div>
            <a class="return-link" href="{{ route('buyer.cart') }}">&larr; &nbsp;Back to cart</a>
        </section>

        <aside class="card summary-card">
            <h2 class="summary-title">Order summary</h2>
            <div class="summary-row"><span>Subtotal</span><strong id="subtotalAmount" data-base-subtotal="{{ (float) $summary['subtotal'] }}">&#8369;{{ number_format($summary['subtotal'], 2) }}</strong></div>
            <div class="summary-row discount" id="discountSummaryRow" @if($summary['discount'] <= 0) hidden @endif><span>Discount</span><strong id="discountAmount" data-base-discount="{{ (float) $summary['discount'] }}">&minus; &#8369;{{ number_format($summary['discount'], 2) }}</strong></div>
            <div class="summary-row"><span>Shipping</span><strong id="shippingAmount" data-shipping="{{ (float) $summary['shipping'] }}">&#8369;{{ number_format($summary['shipping'], 2) }}</strong></div>
            <div class="summary-row discount" id="voucherSummaryRow" hidden><span>Voucher (<span id="voucherSummaryCode"></span>)</span><strong id="voucherSummaryAmount">&minus; &#8369;0.00</strong></div>
            <div class="voucher-box">
                <label class="voucher-label" for="voucherCodeInput">Voucher Code</label>
                <div class="voucher-input-group">
                    <input type="text" id="voucherCodeInput" class="voucher-input" placeholder="Enter voucher code" value="{{ old('voucher_code', '') }}" autocomplete="off" aria-describedby="voucherFeedback" aria-label="Voucher code">
                    <button type="button" id="applyVoucherBtn" class="voucher-apply-btn">Apply</button>
                </div>
                <div id="voucherFeedback" class="voucher-feedback @if($errors->has('voucher_code')) error @endif" aria-live="polite" role="status">
                    @error('voucher_code')<span class="voucher-error-text">{{ $message }}</span>@enderror
                </div>
            </div>
            <div class="summary-total"><span>Total</span><strong id="summaryTotalAmount" data-base-total="{{ (float) $summary['total'] }}" data-net-items="{{ round((float) $summary['subtotal'] - (float) $summary['discount'], 2) }}" data-shipping="{{ (float) $summary['shipping'] }}">&#8369;{{ number_format($summary['total'], 2) }}</strong></div>
            <p class="savings-line" id="savingsLine" @if($summary['total_savings'] <= 0) hidden @endif>You save <span id="savingsAmount">&#8369;{{ number_format($summary['total_savings'], 2) }}</span></p>
            <form id="checkoutForm" method="POST" action="{{ route('buyer.checkout.store') }}" enctype="multipart/form-data">
                @csrf
                <input type="hidden" name="checkout_mode" value="{{ $checkoutMode ?? 'cart' }}">
                <input type="hidden" name="checkout_token" value="{{ old('checkout_token', $checkoutToken) }}">
                <input type="hidden" name="voucher_code" id="appliedVoucherHidden" value="">
                @php
                    $wallets = collect($paymentMethods ?? [])
                        ->whereIn('type', ['gcash', 'maya'])
                        ->values();
                    $walletsByType = $wallets->groupBy('type');
                    $defaultWallet = $wallets->firstWhere('is_default', true);
                    $cartPaymentOption = in_array($cartPaymentOption ?? 'cod', ['cod', 'wallet'], true) ? $cartPaymentOption : 'cod';
                    $initialWallet = $cartPaymentOption === 'wallet' ? $defaultWallet : null;
                    $selectedWalletId = old('payment_method_id', $initialWallet?->id);
                    $selectedPaymentType = old('payment_method', $initialWallet?->type ?? 'cod');
                    if (! in_array($selectedPaymentType, ['cod', 'gcash', 'maya'], true)) $selectedPaymentType = 'cod';
                    $paymentOptions = [
                        'cod' => [
                            'label' => 'Cash on Delivery',
                            'chip' => 'COD',
                            'description' => 'Pay the rider when your order arrives.',
                            'empty' => null,
                        ],
                        'gcash' => [
                            'label' => 'GCash',
                            'chip' => 'GCash',
                            'description' => 'Pay securely using GCash.',
                            'empty' => null,
                        ],
                        'maya' => [
                            'label' => 'Maya',
                            'chip' => 'Maya',
                            'description' => 'Pay securely using Maya.',
                            'empty' => null,
                        ],
                    ];

                    $maskWallet = function ($wallet): string {
                        $identifier = (string) $wallet->account_identifier;
                        $digits = preg_replace('/\D+/', '', $identifier);
                        $tail = substr($digits ?: $identifier, -4);

                        if (in_array($wallet->type, ['gcash', 'maya'], true)) {
                            return substr($digits ?: $identifier, 0, 4) . ' *** ' . $tail;
                        }

                        return '•••• •••• ' . $tail;
                    };
                @endphp

                <section class="payment-card" aria-labelledby="checkout-payment-heading">
                    <div class="payment-card-head">
                        <div>
                            <h3 class="payment-card-title" id="checkout-payment-heading">Payment Method</h3>
                            <p class="payment-card-subtitle">Choose how you want to pay for your order.</p>
                        </div>
                        <a class="manage-wallet" href="{{ route('buyer.wallet.index') }}">Manage Wallet</a>
                    </div>

                    <div class="payment-options">
                        @foreach($paymentOptions as $value => $option)
                            @php
                                $savedCount = $walletsByType->get($value, collect())->count();
                            @endphp
                            <div>
                                <label class="payment-radio-card">
                                    <input
                                        type="radio"
                                        name="payment_method"
                                        value="{{ $value }}"
                                        data-payment-method
                                        @checked($selectedPaymentType === $value)
                                    >
                                    <span>
                                        <strong><span>{{ $option['label'] }}</span><span class="method-chip">{{ $option['chip'] }}</span></strong>
                                        <span>{{ $option['description'] }}</span>
                                    </span>
                                </label>
                                <p class="payment-explanation" data-payment-explanation="{{ $value }}">
                                    @if($value === 'cod')Please prepare <span data-cod-total>&#8369;{{ number_format($summary['total'], 2) }}</span> in cash for the rider.@elseif($value === 'gcash' || $value === 'maya')How it works: Open the QR payment panel, scan the code, upload your receipt and enter the last six reference digits to place your order.@endif
                                </p>

                                @if($value !== 'cod' && $savedCount === 0 && $option['empty'])
                                    <p class="payment-note">
                                        {{ $option['empty'] }}
                                        <a href="{{ route('buyer.wallet.index') }}">Add Wallet</a>
                                    </p>
                                @endif
                            </div>
                        @endforeach
                    </div>

                    @if($wallets->isNotEmpty())
                        <h4 class="wallet-section-title">Saved Wallets</h4>
                        <div class="wallet-list">
                            @foreach($wallets as $wallet)
                                <label class="wallet-card">
                                    <input
                                        type="radio"
                                        name="payment_method_id"
                                        value="{{ $wallet->id }}"
                                        data-wallet-radio
                                        data-wallet-type="{{ $wallet->type }}"
                                        @checked((string) $selectedWalletId === (string) $wallet->id)
                                    >
                                    <span>
                                        <span class="wallet-title-row">
                                            <strong>{{ $paymentOptions[$wallet->type]['label'] ?? 'Wallet' }}</strong>
                                            @if($wallet->is_default)
                                                <span class="wallet-badge">Default</span>
                                            @endif
                                        </span>
                                        <span>{{ $wallet->account_name ?: 'Lumora wallet' }}</span>
                                        <span>{{ $maskWallet($wallet) }}</span>
                                    </span>
                                </label>
                            @endforeach
                        </div>
                    @else
                        <p class="payment-note">No saved wallets yet. <a href="{{ route('buyer.wallet.index') }}">Add Wallet</a></p>
                    @endif

                    @error('payment_method')<span class="payment-error">{{ $message }}</span>@enderror
                    @error('payment_method_id')<span class="payment-error">{{ $message }}</span>@enderror
                </section>

                <button class="place-order" type="submit" data-place-order @disabled(!$selectedAddress)>Place order · &#8369;<span data-button-total>{{ number_format($summary['total'], 2) }}</span></button>
                <p class="order-legal">By placing your order you agree to our <a href="{{ route('legal.user-agreement') }}" target="_blank" rel="noopener">Terms</a> and <a href="{{ route('help.center', 'returns') }}" target="_blank" rel="noopener">Return Policy</a>.</p>
                <p class="secure-returns">Secure payment · Easy returns</p>
                <div class="wallet-modal-backdrop" data-wallet-modal hidden>
                    <section class="wallet-modal" role="dialog" aria-modal="true" aria-labelledby="walletModalTitle">
                        <div class="wallet-modal-head">
                            <div><h2 id="walletModalTitle">Pay with <span data-wallet-label>GCash</span></h2><p class="wallet-modal-note">Scan this InstaPay QR code to complete your payment.</p></div>
                            <button class="wallet-modal-close" type="button" aria-label="Close payment popup" data-wallet-close>&times;</button>
                        </div>
                        <img class="wallet-qr" src="{{ asset('payments/instapay-gcash.png') }}" alt="InstaPay QR code" data-wallet-qr>
                        <p class="wallet-modal-note" style="text-align:center">Transfer fees may apply.</p>
                        <label for="paymentProof">Payment receipt screenshot</label>
                        <input id="paymentProof" name="payment_proof" type="file" accept="image/jpeg,image/png,image/webp" data-payment-proof>
                        <p class="wallet-modal-note">JPG, PNG, or WEBP, up to 5 MB. This screenshot will be attached to your order.</p>
                        @error('payment_proof')<span class="payment-error">{{ $message }}</span>@enderror
                        <label for="referenceDigit1">Input the last 6 digits of Reference Number</label>
                        <div class="reference-slots" data-reference-slots aria-label="Last six digits of reference number">
                            @for ($slot = 1; $slot <= 6; $slot++)
                                <input id="referenceDigit{{ $slot }}" type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="one-time-code" aria-label="Reference digit {{ $slot }}" data-reference-digit>
                            @endfor
                        </div>
                        <input type="hidden" name="payment_reference_last6" data-reference-value>
                        @error('payment_reference_last6')<span class="payment-error">{{ $message }}</span>@enderror
                        <span class="payment-error" data-wallet-modal-error hidden></span>
                        <div class="wallet-modal-actions">
                            <button type="button" data-wallet-cancel>Cancel</button>
                            <button type="button" class="confirm" data-wallet-confirm>Confirm Payment</button>
                        </div>
                    </section>
                </div>
            </form>
        </aside>
    </div>
</main>
<div class="address-modal" id="addressModal" aria-hidden="true">
    <section class="address-modal-card" role="dialog" aria-modal="true" aria-labelledby="addressModalTitle">
        <div class="address-modal-heading">
            <div><h2 id="addressModalTitle">Add delivery address</h2><p>Save an address for this and future orders.</p></div>
            <button type="button" class="address-modal-close" data-close-address-modal aria-label="Close address form">&times;</button>
        </div>
        <form id="addressForm" method="POST" action="{{ route('buyer.addresses.store') }}" data-address-base="{{ url('/account/addresses') }}" data-regions-url="{{ route('address.regions') }}">
            @csrf
            <input type="hidden" name="_method" id="addressFormMethod" value="POST">
            <div class="address-form-grid">
                <div class="address-form-field"><label for="addressFullName">Full Name</label><input id="addressFullName" name="full_name" autocomplete="name" value="{{ $buyer->name }}" required maxlength="255"></div>
                <div class="address-form-field"><label for="addressPhone">Phone Number</label><input id="addressPhone" name="phone_number" autocomplete="tel" value="{{ $formattedPhone }}" required maxlength="25" inputmode="tel"></div>
                <div class="address-form-field"><label for="addressRegion">Region</label><select id="addressRegion" name="region" required><option value="">Select region</option></select><input type="hidden" name="region_code" id="addressRegionCode"></div>
                <div class="address-form-field"><label for="addressProvince">Province</label><select id="addressProvince" name="province" required disabled><option value="">Select province</option></select><input type="hidden" name="province_code" id="addressProvinceCode"></div>
                <div class="address-form-field"><label for="addressCity">City / Municipality</label><select id="addressCity" name="city_municipality" required disabled><option value="">Select city / municipality</option></select><input type="hidden" name="city_municipality_code" id="addressCityCode"></div>
                <div class="address-form-field"><label for="addressBarangay">Barangay</label><select id="addressBarangay" name="barangay" required disabled><option value="">Select barangay</option></select><input type="hidden" name="barangay_code" id="addressBarangayCode"></div>
                <div class="address-form-field full"><label for="addressStreet">Street Address / House Number</label><input id="addressStreet" name="street_address" autocomplete="street-address" required maxlength="255"></div>
                <div class="address-form-field"><label for="addressPostal">Postal Code</label><input id="addressPostal" name="postal_code" inputmode="numeric" pattern="[0-9]{4}" maxlength="4" required></div>
                <div class="address-form-field"><label for="addressLabel">Address Label</label><select id="addressLabel" name="label" required><option value="home">Home</option><option value="work">Work</option><option value="other">Other</option></select></div>
                <label class="address-default-choice"><input type="checkbox" name="is_default" value="1" id="addressDefault"> Set as default address</label>
                <p class="address-modal-error" id="addressModalError" role="alert" hidden></p>
            </div>
            <div class="address-modal-actions"><button type="button" data-close-address-modal>Cancel</button><button type="submit" class="address-save" id="addressSaveButton">Save address</button></div>
        </form>
    </section>
</div>
<div class="mobile-checkout-bar" aria-label="Checkout total and place order">
    <span class="mobile-checkout-total">&#8369;<span data-mobile-total>{{ number_format($summary['total'], 2) }}</span></span>
    <button class="place-order" type="submit" form="checkoutForm" data-place-order @disabled(!$selectedAddress)>Place order</button>
</div>
<script>
document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('addressForm');
    const modal = document.getElementById('addressModal');
    if (!form || !modal) return;

    const addressBase = form.dataset.addressBase;
    const regionsUrl = form.dataset.regionsUrl;
    const addressSelect = document.getElementById('deliveryAddressSelect');
    const addressId = document.getElementById('checkoutAddressId');
    const addressRow = document.getElementById('selectedAddressRow');
    const addressDisplay = document.getElementById('selectedAddressDisplay');
    const emptyPrompt = document.getElementById('addressEmptyPrompt');
    const actions = document.getElementById('addressManagementActions');
    const saveButton = document.getElementById('addressSaveButton');
    const errorBox = document.getElementById('addressModalError');
    const token = form.querySelector('input[name="_token"]')?.value || '';
    let addressRecords = {{ Illuminate\Support\Js::from($addresses) }};
    let activeAddress = null;
    let lastFocus = null;

    const field = (name) => form.elements.namedItem(name);
    const setField = (name, value) => { const target = field(name); if (target) target.value = value ?? ''; };
    const setAddressDisplay = (address) => {
        activeAddress = address || null;
        if (!address) {
            addressRow.hidden = true;
            actions.hidden = true;
            if (emptyPrompt) emptyPrompt.hidden = false;
            addressId.value = '';
            document.querySelectorAll('[data-place-order]').forEach((button) => { button.disabled = true; });
            return;
        }
        if (emptyPrompt) emptyPrompt.hidden = true;
        addressRow.hidden = false;
        actions.hidden = false;
        addressId.value = address.id;
        addressDisplay.querySelector('[data-address-label]').textContent = `${String(address.label || 'home').replace(/^./, (letter) => letter.toUpperCase())}${address.is_default ? ' · Default' : ''}`;
        addressDisplay.querySelector('[data-address-name]').textContent = address.full_name || '';
        addressDisplay.querySelector('[data-address-street]').textContent = address.street_address || '';
        addressDisplay.querySelector('[data-address-locality]').textContent = [address.barangay, address.city_municipality, address.province, address.region].filter(Boolean).join(', ');
        addressDisplay.querySelector('[data-address-postal]').textContent = address.postal_code || '';
        addressDisplay.querySelector('[data-address-phone]').textContent = address.phone_number || '';
        document.querySelectorAll('[data-place-order]').forEach((button) => { button.disabled = false; });
    };

    const renderAddresses = (addresses, selectedId) => {
        addressRecords = addresses || [];
        if (!addressSelect && addressRecords.length) {
            window.location.reload();
            return;
        }
        if (addressSelect) {
            addressSelect.replaceChildren();
            addressRecords.forEach((address) => {
                const option = document.createElement('option');
                option.value = address.id;
                option.textContent = `${String(address.label || 'home').replace(/^./, (letter) => letter.toUpperCase())} · ${address.full_name}${address.is_default ? ' · Default' : ''}`;
                addressSelect.append(option);
            });
            addressSelect.hidden = addressRecords.length === 0;
            if (addressRecords.length) {
                const preferred = addressRecords.find((address) => Number(address.id) === Number(selectedId)) || addressRecords.find((address) => address.is_default) || addressRecords[0];
                addressSelect.value = preferred.id;
                setAddressDisplay(preferred);
            } else {
                setAddressDisplay(null);
            }
        }
    };

    const populateSelect = async (select, url, placeholder, selectedCode = '') => {
        select.replaceChildren(new Option(placeholder, ''));
        select.disabled = true;
        const response = await fetch(url, { headers: { 'Accept': 'application/json' } });
        if (!response.ok) throw new Error('Address regions could not be loaded. Please try again.');
        const payload = await response.json();
        (payload.data || []).forEach((item) => {
            const code = String(item.code ?? item.psgc_code ?? item.id ?? '');
            const name = String(item.name ?? item.regionName ?? '');
            if (!code || !name) return;
            const option = new Option(name, name);
            option.dataset.code = code;
            select.add(option);
        });
        select.disabled = false;
        if (selectedCode) {
            const selected = [...select.options].find((option) => option.dataset.code === String(selectedCode));
            if (selected) select.value = selected.value;
        }
        return select.selectedOptions[0]?.dataset.code || '';
    };

    const resetChildren = (from) => {
        const children = [
            ['province', 'Select province'], ['city_municipality', 'Select city / municipality'], ['barangay', 'Select barangay'],
        ];
        const start = children.findIndex(([name]) => name === from);
        children.slice(start).forEach(([name, placeholder]) => {
            const select = field(name);
            select.replaceChildren(new Option(placeholder, ''));
            select.disabled = true;
            setField(`${name}_code`, '');
        });
    };

    const regions = field('region');
    const provinces = field('province');
    const cities = field('city_municipality');
    const barangays = field('barangay');
    const loadProvinces = async (regionCode, selected = '') => {
        resetChildren('province');
        setField('region_code', regionCode);
        if (regionCode) await populateSelect(provinces, `${regionsUrl}/${encodeURIComponent(regionCode)}/provinces`, 'Select province', selected);
        setField('province_code', provinces.selectedOptions[0]?.dataset.code || '');
    };
    const loadCities = async (provinceCode, selected = '') => {
        resetChildren('city_municipality');
        setField('province_code', provinceCode);
        if (provinceCode) await populateSelect(cities, `/address/provinces/${encodeURIComponent(provinceCode)}/municipalities`, 'Select city / municipality', selected);
        setField('city_municipality_code', cities.selectedOptions[0]?.dataset.code || '');
    };
    const loadBarangays = async (cityCode, selected = '') => {
        resetChildren('barangay');
        setField('city_municipality_code', cityCode);
        if (cityCode) await populateSelect(barangays, `/address/municipalities/${encodeURIComponent(cityCode)}/barangays`, 'Select barangay', selected);
        setField('barangay_code', barangays.selectedOptions[0]?.dataset.code || '');
    };

    regions.addEventListener('change', async () => {
        try { await loadProvinces(regions.selectedOptions[0]?.dataset.code || ''); setField('region', regions.selectedOptions[0]?.textContent || ''); }
        catch (error) { errorBox.textContent = error.message; errorBox.hidden = false; }
    });
    provinces.addEventListener('change', async () => {
        try { await loadCities(provinces.selectedOptions[0]?.dataset.code || ''); setField('province', provinces.selectedOptions[0]?.textContent || ''); }
        catch (error) { errorBox.textContent = error.message; errorBox.hidden = false; }
    });
    cities.addEventListener('change', async () => {
        try { await loadBarangays(cities.selectedOptions[0]?.dataset.code || ''); setField('city_municipality', cities.selectedOptions[0]?.textContent || ''); }
        catch (error) { errorBox.textContent = error.message; errorBox.hidden = false; }
    });
    barangays.addEventListener('change', () => {
        setField('barangay_code', barangays.selectedOptions[0]?.dataset.code || '');
        setField('barangay', barangays.selectedOptions[0]?.textContent || '');
    });

    const showModal = async (address = null) => {
        lastFocus = document.activeElement;
        errorBox.hidden = true;
        errorBox.textContent = '';
        form.reset();
        form.action = `${addressBase}${address ? `/${address.id}` : ''}`;
        document.getElementById('addressFormMethod').value = address ? 'PATCH' : 'POST';
        document.getElementById('addressModalTitle').textContent = address ? 'Edit delivery address' : 'Add delivery address';
        saveButton.textContent = address ? 'Save changes' : 'Save address';
        ['full_name', 'phone_number', 'street_address', 'postal_code', 'label'].forEach((name) => setField(name, address?.[name] ?? (name === 'label' ? 'home' : field(name).defaultValue)));
        document.getElementById('addressDefault').checked = Boolean(address?.is_default);
        try {
            await populateSelect(regions, regionsUrl, 'Select region', address?.region_code || '');
            setField('region', regions.selectedOptions[0]?.textContent === 'Select region' ? '' : (regions.selectedOptions[0]?.textContent || address?.region || ''));
            if (address?.region_code) {
                await loadProvinces(address.region_code, address.province_code || '');
                setField('province', provinces.selectedOptions[0]?.textContent || address.province || '');
                if (address.province_code) {
                    await loadCities(address.province_code, address.city_municipality_code || '');
                    setField('city_municipality', cities.selectedOptions[0]?.textContent || address.city_municipality || '');
                    if (address.city_municipality_code) {
                        await loadBarangays(address.city_municipality_code, address.barangay_code || '');
                        setField('barangay', barangays.selectedOptions[0]?.textContent || address.barangay || '');
                    }
                }
            }
        } catch (error) {
            errorBox.textContent = `${error.message} Refresh the page and try again.`;
            errorBox.hidden = false;
        }
        modal.classList.add('is-open');
        modal.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';
        document.getElementById('addressFullName').focus();
    };
    const closeModal = () => {
        modal.classList.remove('is-open');
        modal.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
        lastFocus?.focus();
    };

    document.getElementById('addAddressButton').addEventListener('click', () => showModal());
    document.getElementById('editAddressButton')?.addEventListener('click', () => activeAddress && showModal(activeAddress));
    document.querySelectorAll('[data-close-address-modal]').forEach((button) => button.addEventListener('click', closeModal));
    modal.addEventListener('click', (event) => { if (event.target === modal) closeModal(); });
    document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && modal.classList.contains('is-open')) closeModal(); });

    addressSelect?.addEventListener('change', () => {
        const chosen = addressRecords.find((address) => Number(address.id) === Number(addressSelect.value));
        setAddressDisplay(chosen);
    });

    form.addEventListener('submit', async (event) => {
        event.preventDefault();
        errorBox.hidden = true;
        saveButton.disabled = true;
        saveButton.textContent = 'Saving…';
        const payload = new FormData(form);
        if (!document.getElementById('addressDefault').checked) payload.set('is_default', '0');
        try {
            const response = await fetch(form.action, {
                method: 'POST',
                headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                body: payload,
            });
            const result = await response.json();
            if (!response.ok) {
                const firstError = Object.values(result.errors || {}).flat()[0];
                throw new Error(firstError || result.message || 'Unable to save this address.');
            }
            renderAddresses(result.addresses || [result.address], result.address.id);
            closeModal();
        } catch (error) {
            errorBox.textContent = error.message;
            errorBox.hidden = false;
        } finally {
            saveButton.disabled = false;
            saveButton.textContent = document.getElementById('addressFormMethod').value === 'PATCH' ? 'Save changes' : 'Save address';
        }
    });

    const removeSelectedAddress = async (confirmed = false) => {
        if (!activeAddress) return;
        const url = `${addressBase}/${activeAddress.id}${confirmed ? '?confirm_active_orders=1' : ''}`;
        const response = await fetch(url, {
            method: 'DELETE',
            headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest', 'X-CSRF-TOKEN': token },
        });
        const result = await response.json();
        if (response.status === 409 && result.requires_confirmation) {
            if (window.confirm(result.message)) return removeSelectedAddress(true);
            return;
        }
        if (!response.ok) throw new Error(result.message || 'Unable to delete this address.');
        renderAddresses(result.addresses || [], result.selected_address_id);
    };
    document.getElementById('deleteAddressButton')?.addEventListener('click', async () => {
        if (!activeAddress || !window.confirm('Delete this saved delivery address?')) return;
        try { await removeSelectedAddress(); }
        catch (error) { window.alert(error.message); }
    });

    if (addressSelect && addressRecords.length) {
        const initial = addressRecords.find((address) => Number(address.id) === Number(addressId.value || addressSelect.value));
        if (initial) setAddressDisplay(initial);
    } else if (!addressRecords.length) {
        setAddressDisplay(null);
    }
});
</script>
<script>
    document.addEventListener('DOMContentLoaded', () => {
        const checkoutForm = document.getElementById('checkoutForm');
        const methodRadios = [...document.querySelectorAll('[data-payment-method]')];
        const walletRadios = [...document.querySelectorAll('[data-wallet-radio]')];
        const proofInput = document.querySelector('[data-payment-proof]');
        const walletModal = document.querySelector('[data-wallet-modal]');
        const walletLabel = document.querySelector('[data-wallet-label]');
        const referenceDigits = [...document.querySelectorAll('[data-reference-digit]')];
        const referenceValue = document.querySelector('[data-reference-value]');
        const modalError = document.querySelector('[data-wallet-modal-error]');
        const placeButtons = [...document.querySelectorAll('[data-place-order]')];
        const voucherInput = document.getElementById('voucherCodeInput');
        const applyVoucherBtn = document.getElementById('applyVoucherBtn');
        const voucherFeedback = document.getElementById('voucherFeedback');
        const voucherSummaryRow = document.getElementById('voucherSummaryRow');
        const voucherSummaryCode = document.getElementById('voucherSummaryCode');
        const voucherSummaryAmount = document.getElementById('voucherSummaryAmount');
        const appliedVoucherHidden = document.getElementById('appliedVoucherHidden');
        const subtotalAmount = document.getElementById('subtotalAmount');
        const discountSummaryRow = document.getElementById('discountSummaryRow');
        const discountAmount = document.getElementById('discountAmount');
        const shippingAmount = document.getElementById('shippingAmount');
        const summaryTotalAmount = document.getElementById('summaryTotalAmount');
        const savingsLine = document.getElementById('savingsLine');
        const savingsAmount = document.getElementById('savingsAmount');
        const builtInVouchers = Object.assign({
            LUMORA10: { type: 'percent', value: 10, min_spend: 0, label: '10% OFF' },
            LUMORA20: { type: 'percent', value: 20, min_spend: 0, label: '20% OFF' },
            FREESHIP: { type: 'shipping', value: 0, min_spend: 0, label: 'Free Shipping' },
        }, @json($activeVouchers ?? []), @json($unavailableVouchers ?? []));
        let appliedCode = '';
        let appliedRule = null;
        let confirmedWalletPayment = false;
        let submissionStarted = false;
        const formatCurrency = (value) => '\u20B1' + Number(value || 0).toLocaleString('en-PH', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        const roundMoney = (value) => Math.round((Number(value) + Number.EPSILON) * 100) / 100;
        const selectedMethod = () => methodRadios.find((radio) => radio.checked)?.value || 'cod';

        function currentItemsTotals() {
            let subtotal = 0;
            let productDiscount = 0;
            document.querySelectorAll('[data-checkout-item]').forEach((item) => {
                const quantityInput = item.querySelector('[data-quantity-input]');
                const quantity = Math.max(1, parseInt(quantityInput?.value || '1', 10));
                const original = parseFloat(item.dataset.originalUnit || '0');
                const sale = parseFloat(item.dataset.saleUnit || '0');
                subtotal += original * quantity;
                productDiscount += Math.max(0, original - sale) * quantity;
                const output = item.querySelector('[data-quantity-output]');
                if (output) output.textContent = String(quantity);
                const currentPrice = item.querySelector('.item-price-current');
                const originalPrice = item.querySelector('.item-price-original');
                if (currentPrice) currentPrice.textContent = formatCurrency(sale * quantity);
                if (originalPrice) originalPrice.textContent = formatCurrency(original * quantity);
                const minus = item.querySelector('[data-quantity-decrement]');
                const plus = item.querySelector('[data-quantity-increment]');
                const max = parseInt(quantityInput?.dataset.maxQuantity || '99', 10);
                if (minus) minus.disabled = quantity <= 1;
                if (plus) plus.disabled = quantity >= max;
            });
            return { subtotal: roundMoney(subtotal), productDiscount: roundMoney(productDiscount) };
        }

        function voucherSavings(netItems, shipping) {
            if (!appliedRule) return { items: 0, shipping: 0 };
            if (appliedRule.type === 'shipping') return { items: 0, shipping };
            return { items: roundMoney(netItems * (parseFloat(appliedRule.value || '0') / 100)), shipping: 0 };
        }

        function renderTotals() {
            const items = currentItemsTotals();
            const shipping = parseFloat(shippingAmount?.dataset.shipping || '0');
            const netItems = Math.max(0, roundMoney(items.subtotal - items.productDiscount));
            const voucher = voucherSavings(netItems, shipping);
            const totalDiscount = roundMoney(items.productDiscount + voucher.items);
            const totalSavings = roundMoney(totalDiscount + voucher.shipping);
            const total = Math.max(0, roundMoney(items.subtotal + shipping - totalDiscount - voucher.shipping));
            if (subtotalAmount) subtotalAmount.textContent = formatCurrency(items.subtotal);
            if (discountAmount) discountAmount.textContent = '\u2212 ' + formatCurrency(items.productDiscount);
            if (discountSummaryRow) discountSummaryRow.hidden = items.productDiscount <= 0;
            if (summaryTotalAmount) {
                summaryTotalAmount.textContent = formatCurrency(total);
                summaryTotalAmount.dataset.baseTotal = String(roundMoney(items.subtotal + shipping - items.productDiscount));
                summaryTotalAmount.dataset.netItems = String(netItems);
                summaryTotalAmount.dataset.shipping = String(shipping);
            }
            if (savingsAmount) savingsAmount.textContent = formatCurrency(totalSavings);
            if (savingsLine) savingsLine.hidden = totalSavings <= 0;
            if (voucherSummaryCode) voucherSummaryCode.textContent = appliedCode;
            if (voucherSummaryAmount) voucherSummaryAmount.textContent = '\u2212 ' + formatCurrency(voucher.items || voucher.shipping);
            if (voucherSummaryRow) voucherSummaryRow.hidden = !appliedRule;
            document.querySelectorAll('[data-cod-total]').forEach((node) => { node.textContent = formatCurrency(total); });
            document.querySelectorAll('[data-button-total]').forEach((node) => { node.textContent = Number(total).toLocaleString('en-PH', { minimumFractionDigits: 2, maximumFractionDigits: 2 }); });
            document.querySelectorAll('[data-mobile-total]').forEach((node) => { node.textContent = Number(total).toLocaleString('en-PH', { minimumFractionDigits: 2, maximumFractionDigits: 2 }); });
            return total;
        }

        function updatePaymentExplanation() {
            const method = selectedMethod();
            document.querySelectorAll('[data-payment-explanation]').forEach((node) => {
                node.classList.toggle('is-visible', node.dataset.paymentExplanation === method);
            });
        }

        document.querySelectorAll('[data-quantity-increment], [data-quantity-decrement]').forEach((button) => {
            button.addEventListener('click', () => {
                const item = button.closest('[data-checkout-item]');
                const input = item?.querySelector('[data-quantity-input]');
                if (!input) return;
                const current = parseInt(input.value || '1', 10);
                const max = parseInt(input.dataset.maxQuantity || '99', 10);
                input.value = String(button.hasAttribute('data-quantity-increment') ? Math.min(max, current + 1) : Math.max(1, current - 1));
                renderTotals();
                if (item.dataset.cartSync === 'true') {
                    fetch(item.dataset.cartUpdateUrl, {
                        method: 'PATCH',
                        headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '',
                        },
                        body: JSON.stringify({ quantity: Number(input.value) }),
                    }).catch(() => {});
                }
            });
        });

        function showVoucherError(message) {
            appliedCode = '';
            appliedRule = null;
            if (appliedVoucherHidden) appliedVoucherHidden.value = '';
            if (voucherFeedback) {
                voucherFeedback.className = 'voucher-feedback error';
                voucherFeedback.textContent = message;
            }
            renderTotals();
        }

        function clearVoucher() {
            appliedCode = '';
            appliedRule = null;
            if (appliedVoucherHidden) appliedVoucherHidden.value = '';
            if (voucherInput) voucherInput.value = '';
            if (voucherFeedback) {
                voucherFeedback.className = 'voucher-feedback';
                voucherFeedback.replaceChildren();
            }
            renderTotals();
        }

        function applyVoucherCode() {
            const code = (voucherInput?.value || '').trim().toUpperCase();
            if (voucherInput) voucherInput.value = code;
            if (!code) return showVoucherError('Please enter a voucher code.');
            const rule = builtInVouchers[code];
            if (!rule) return showVoucherError('This voucher code is invalid.');
            if (rule.error) return showVoucherError(rule.error);
            const totals = currentItemsTotals();
            const netItems = Math.max(0, roundMoney(totals.subtotal - totals.productDiscount));
            if (netItems < parseFloat(rule.min_spend || '0')) {
                return showVoucherError('The minimum spend of ' + formatCurrency(rule.min_spend) + ' for this voucher has not been met.');
            }
            appliedCode = code;
            appliedRule = rule;
            if (appliedVoucherHidden) appliedVoucherHidden.value = code;
            renderTotals();
            if (voucherFeedback) {
                voucherFeedback.className = 'voucher-feedback success';
                voucherFeedback.replaceChildren();
                const message = document.createElement('span');
                message.textContent = code + ' applied. You saved ' + formatCurrency(voucherSavings(netItems, parseFloat(shippingAmount?.dataset.shipping || '0')).items || voucherSavings(netItems, parseFloat(shippingAmount?.dataset.shipping || '0')).shipping) + '.';
                const remove = document.createElement('button');
                remove.type = 'button';
                remove.className = 'voucher-remove-btn';
                remove.textContent = 'Remove';
                remove.addEventListener('click', clearVoucher);
                voucherFeedback.append(message, remove);
            }
        }

        voucherInput?.addEventListener('input', () => {
            const start = voucherInput.selectionStart;
            voucherInput.value = voucherInput.value.toUpperCase();
            voucherInput.setSelectionRange(start, start);
            if (appliedCode && voucherInput.value.trim() !== appliedCode) {
                appliedCode = '';
                appliedRule = null;
                if (appliedVoucherHidden) appliedVoucherHidden.value = '';
                if (voucherFeedback) { voucherFeedback.className = 'voucher-feedback'; voucherFeedback.replaceChildren(); }
                renderTotals();
            }
        });
        applyVoucherBtn?.addEventListener('click', applyVoucherCode);
        voucherInput?.addEventListener('keydown', (event) => {
            if (event.key === 'Enter') { event.preventDefault(); applyVoucherCode(); }
        });

        const walletForType = (type) => walletRadios.find((radio) => radio.dataset.walletType === type);
        walletRadios.forEach((walletRadio) => walletRadio.addEventListener('change', () => {
            if (!walletRadio.checked) return;
            const matchingMethod = methodRadios.find((radio) => radio.value === walletRadio.dataset.walletType);
            if (matchingMethod) matchingMethod.checked = true;
            updatePaymentExplanation();
        }));
        methodRadios.forEach((radio) => radio.addEventListener('change', () => {
            if (!radio.checked) return;
            if (radio.value === 'cod') {
                walletRadios.forEach((wallet) => { wallet.checked = false; });
            } else if (!walletRadios.some((wallet) => wallet.checked && wallet.dataset.walletType === radio.value)) {
                walletRadios.forEach((wallet) => { wallet.checked = false; });
                const first = walletForType(radio.value);
                if (first) first.checked = true;
            }
            updatePaymentExplanation();
        }));
        updatePaymentExplanation();
        renderTotals();

        const savedVoucherCode = (voucherInput?.value || '').trim().toUpperCase();
        if (savedVoucherCode && builtInVouchers[savedVoucherCode] && !builtInVouchers[savedVoucherCode].error) {
            if (voucherInput) voucherInput.value = savedVoucherCode;
            applyVoucherCode();
        }

        const closeWalletModal = () => { if (walletModal) walletModal.hidden = true; };
        document.querySelectorAll('[data-wallet-close], [data-wallet-cancel]').forEach((button) => button.addEventListener('click', closeWalletModal));
        walletModal?.addEventListener('click', (event) => { if (event.target === walletModal) closeWalletModal(); });
        referenceDigits.forEach((input, index) => {
            input.addEventListener('input', () => {
                input.value = input.value.replace(/\D/g, '').slice(-1);
                if (input.value && referenceDigits[index + 1]) referenceDigits[index + 1].focus();
            });
            input.addEventListener('keydown', (event) => {
                if (event.key === 'Backspace' && !input.value && referenceDigits[index - 1]) referenceDigits[index - 1].focus();
            });
            input.addEventListener('paste', (event) => {
                const pasted = event.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6).split('');
                if (!pasted.length) return;
                event.preventDefault();
                pasted.forEach((digit, digitIndex) => { if (referenceDigits[digitIndex]) referenceDigits[digitIndex].value = digit; });
                referenceDigits[Math.min(pasted.length, 5)].focus();
            });
        });
        @if ($errors->has('payment_proof') || $errors->has('payment_reference_last6'))
            walletLabel.textContent = @json(old('payment_method') === 'maya' ? 'Maya' : 'GCash');
            walletModal.hidden = false;
            const oldReference = @json(old('payment_reference_last6', ''));
            [...String(oldReference)].slice(-6).forEach((digit, index) => { if (referenceDigits[index]) referenceDigits[index].value = digit; });
        @endif
        document.querySelector('[data-wallet-confirm]')?.addEventListener('click', () => {
            const reference = referenceDigits.map((input) => input.value).join('');
            if (referenceValue) referenceValue.value = reference;
            if (!proofInput?.files?.length) {
                modalError.textContent = 'Please upload your payment receipt screenshot.';
                modalError.hidden = false;
                proofInput?.focus();
                return;
            }
            if (!/^\d{6}$/.test(reference)) {
                modalError.textContent = 'Enter all 6 digits of your reference number.';
                modalError.hidden = false;
                referenceDigits.find((input) => !input.value)?.focus();
                return;
            }
            confirmedWalletPayment = true;
            closeWalletModal();
            checkoutForm.requestSubmit();
        });

        checkoutForm?.addEventListener('submit', (event) => {
            if (submissionStarted) { event.preventDefault(); return; }
            const method = selectedMethod();
            if (['gcash', 'maya'].includes(method) && !confirmedWalletPayment) {
                event.preventDefault();
                walletLabel.textContent = method === 'maya' ? 'Maya' : 'GCash';
                walletModal.hidden = false;
                modalError.hidden = true;
                return;
            }
            submissionStarted = true;
            placeButtons.forEach((button) => {
                button.disabled = true;
                button.textContent = 'Placing order…';
            });
        });
    });
</script>
</body>
</html>
