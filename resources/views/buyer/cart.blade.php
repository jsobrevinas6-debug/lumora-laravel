<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Lumora | Shopping Cart</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root{--plum:#3d1b3d;--rose:#b96562;--cream:#fffdfb;--blush:#fbefea;--line:#ebddd8;--ink:#3a2e30;--muted:#8a7b7e}
        *{box-sizing:border-box}body{margin:0;background:linear-gradient(160deg,#fbefea,#f3d8de 55%,#fffdfb);color:var(--ink);font-family:Inter,sans-serif}h1,h2,h3{font-family:'Playfair Display',serif;color:var(--plum)}a{text-decoration:none;color:inherit}.cart-header{background:rgba(255,253,251,.94);border-bottom:1px solid var(--line)}.header-inner{max-width:1180px;margin:auto;padding:16px 24px;display:flex;align-items:center;gap:28px}.brand{font:700 25px 'Playfair Display',serif;letter-spacing:2px;color:var(--plum)}.brand span{color:var(--rose)}.search{flex:1;max-width:500px;background:var(--cream);border:1px solid var(--line);border-radius:999px;padding:11px 18px;color:var(--muted)}.header-links{margin-left:auto;display:flex;align-items:center;gap:18px;font-size:13px}.cart-link{position:relative;color:var(--plum);font-weight:600}.badge{position:absolute;top:-12px;right:-13px;background:var(--plum);color:#fff;border-radius:50%;font-size:10px;width:18px;height:18px;display:grid;place-items:center}.page{max-width:1180px;margin:0 auto;padding:42px 24px 80px}.crumb{font-size:13px;color:var(--muted)}h1{font-size:52px;margin:18px 0 32px}.layout{display:grid;grid-template-columns:minmax(0,1.55fr) minmax(300px,.75fr);gap:24px}.panel,.summary,.promo{background:rgba(255,253,251,.9);border:1px solid var(--line);border-radius:14px}.panel{padding:26px}.panel-head{display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid var(--line);padding-bottom:18px}.panel h2,.summary h2{font-size:25px;margin:0}.select-all{display:flex;align-items:center;gap:10px;font-size:13px;color:var(--plum);font-weight:600}.select-all input,.item-check{accent-color:var(--plum);width:18px;height:18px}.cart-item{display:grid;grid-template-columns:20px 116px 1fr auto;gap:18px;align-items:center;padding:22px 0;border-bottom:1px solid var(--line)}.cart-item:last-child{border-bottom:0}.item-image{width:116px;height:116px;border-radius:9px;background:#f2e8e3;object-fit:cover}.seller{color:var(--rose);font-size:12px;margin-bottom:6px}.item-name{font:500 20px 'Playfair Display',serif;color:var(--plum);margin:0 0 8px}.price{font-weight:700;color:var(--plum)}del{font-size:12px;color:var(--muted);margin-left:8px}.sale{display:inline-block;margin-left:8px;padding:4px 8px;border:1px solid #e4aaa0;border-radius:999px;color:var(--rose);font-size:10px}.stock{font-size:12px;color:#55734c;margin:11px 0}.quantity{display:flex;align-items:center;border:1px solid var(--line);border-radius:7px;overflow:hidden;width:max-content}.quantity button{border:0;background:var(--cream);color:var(--plum);width:31px;height:29px;font-size:17px}.quantity span{min-width:30px;text-align:center;font-size:13px}.remove{display:block;background:none;border:0;text-decoration:underline;color:var(--muted);font-size:12px;margin-top:12px;padding:0}.summary{padding:26px;height:max-content;position:sticky;top:24px}.summary h2{padding-bottom:18px;border-bottom:1px solid var(--line)}.selected-label{color:var(--rose);font-size:13px;margin:18px 0}.row{display:flex;justify-content:space-between;gap:20px;font-size:13px;margin:14px 0;color:var(--muted)}.discount{color:var(--rose)}.total{border-top:1px solid var(--line);padding-top:20px;margin-top:20px;color:var(--plum);font-weight:700;font-size:18px}.checkout{width:100%;margin-top:22px;border:1px solid var(--rose);background:var(--cream);color:var(--plum);border-radius:8px;padding:14px;font-weight:700;font-size:14px}.checkout:disabled{opacity:.45;cursor:not-allowed}.note{font-size:11px;color:var(--muted);line-height:1.5;margin-top:14px}.continue{display:block;text-align:center;margin-top:17px;color:var(--plum);font-size:13px;text-decoration:underline}.promo{margin-top:22px;padding:20px;display:flex;align-items:center;gap:18px}.promo strong{font-family:'Playfair Display',serif;color:var(--plum)}.promo input{margin-left:auto;border:1px solid var(--line);border-radius:7px;padding:11px;background:#fff;width:190px}.promo button{border:1px solid var(--rose);background:var(--cream);color:var(--plum);border-radius:7px;padding:10px 18px;font-weight:600}.empty{text-align:center;padding:60px 20px;color:var(--muted)}.alert{padding:12px 16px;border-radius:8px;background:#fff3e9;color:var(--rose);margin-bottom:20px;font-size:13px}@media(max-width:800px){.header-inner{padding:14px 16px}.search{display:none}.page{padding:28px 16px 60px}h1{font-size:40px}.layout{grid-template-columns:1fr}.summary{position:static}.cart-item{grid-template-columns:20px 82px 1fr}.item-image{width:82px;height:82px}.item-name{font-size:16px}.cart-item>.remove-wrap{grid-column:3}.promo{align-items:stretch;flex-wrap:wrap}.promo input{margin-left:0;flex:1;min-width:160px}}
        /* Homepage-synchronized Lumora palette */
        :root{--plum:#3D1B3D;--plum-light:#5A2E5A;--orange:#E2703A;--rose:#B96562;--gold:#C9972B;--cream:#FFFDFB;--blush-1:#FBEFEA;--blush-2:#F3D8DE;--ink:#3A2E30;--muted:#8A7B7E;--line:#EBDDD8}
        body{background:linear-gradient(160deg,var(--blush-1) 0%,var(--blush-2) 55%,var(--blush-1) 100%);color:var(--ink)}
        .cart-header,.panel,.summary,.promo{background:rgba(255,253,251,.94);border-color:var(--line)}
        .search,.quantity button,.checkout,.promo input,.promo button{background:var(--cream);border-color:var(--line);color:var(--plum)}
        .badge{background:var(--orange)}
        .selected-label,.discount,.seller{color:var(--rose)}
        .item-name,h1,h2,h3,.price,.total,.continue,.cart-link{color:var(--plum)}
        .sale{border-color:var(--rose);color:var(--rose);background:transparent}
        .checkout,.promo button{border-color:var(--rose);background:var(--cream);color:var(--plum);transition:background-color .2s ease,border-color .2s ease,transform .2s ease}
        .checkout:hover:not(:disabled),.promo button:hover{background:#fff;border-color:var(--rose);transform:translateY(-1px)}
        .checkout:disabled{background:var(--cream);color:var(--muted)}
        .quantity{border-color:var(--line)}
        .quantity button:hover{background:#fff;color:var(--rose)}
        .remove{color:var(--muted)}
        .remove:hover{color:var(--rose)}
    </style>
</head>
<body>
<header class="cart-header"><div class="header-inner"><a class="brand" href="{{ route('shop.index') }}">LUM<span>O</span>RA</a><div class="search">Search for brands, products and more</div><div class="header-links"><a href="{{ route('shop.index') }}">Continue shopping</a><a class="cart-link" href="{{ route('buyer.cart') }}">Cart <span class="badge">{{ $cartItems->sum('quantity') }}</span></a></div></div></header>
<main class="page">
    <div class="crumb"><a href="{{ route('shop.index') }}">Home</a> &nbsp;/&nbsp; Cart</div><h1>Shopping Cart</h1>
    @if(session('success'))<div class="alert">{{ session('success') }}</div>@endif
    @if(session('error'))<div class="alert">{{ session('error') }}</div>@endif
    @if($cartItems->isEmpty())
        <section class="panel empty"><h2>Your cart is waiting</h2><p>Add products from the Lumora collection to begin.</p><a class="continue" href="{{ route('shop.index') }}">Continue shopping</a></section>
    @else
        <div class="layout">
            <section class="panel"><div class="panel-head"><h2>Your items</h2><label class="select-all"><input type="checkbox" id="select-all" {{ $selectedIds->count() === $cartItems->count() ? 'checked' : '' }}> Select all ({{ $cartItems->count() }})</label></div>
                @foreach($cartItems as $item)
                    @php($product = $item['product'])
                    <article class="cart-item" data-item data-product-id="{{ $item['product_id'] }}" data-price="{{ $item['unit_price'] }}" data-discount="{{ $item['line_discount'] }}" data-stock="{{ $product->stock }}">
                        <input class="item-check" type="checkbox" value="{{ $item['product_id'] }}" {{ $selectedIds->contains($item['product_id']) ? 'checked' : '' }} aria-label="Select {{ $product->name }}">
                        @if($product->image)<img class="item-image" src="{{ Storage::url($product->image) }}" alt="{{ $product->name }}">@else<div class="item-image"></div>@endif
                        <div><div class="seller">Lumora seller</div><h3 class="item-name">{{ $product->name }}</h3><div><span class="price">₱{{ number_format($item['unit_price'],2) }}</span>@if($item['discount_percent'] > 0)<del>₱{{ number_format($item['original_price'],2) }}</del><span class="sale">{{ rtrim(rtrim(number_format($item['discount_percent'],1),'0'),'.') }}% OFF</span>@endif</div><div class="stock">● In stock ({{ $product->stock }} available)</div><div class="quantity"><button type="button" data-minus aria-label="Decrease quantity">−</button><span data-quantity>{{ $item['quantity'] }}</span><button type="button" data-plus aria-label="Increase quantity">+</button></div></div>
                        <div class="remove-wrap"><form method="POST" action="{{ route('buyer.cart.remove', $product) }}">@csrf @method('DELETE')<button class="remove" type="submit">Remove</button></form></div>
                    </article>
                @endforeach
            </section>
            <aside class="summary"><h2>Order Summary</h2><div class="selected-label">Selected items (<span id="selected-count">{{ $summary['item_count'] }}</span>)</div><div class="row"><span>Subtotal</span><strong id="subtotal">₱{{ number_format($summary['subtotal'],2) }}</strong></div><div class="row discount"><span>Discount</span><strong id="discount">- ₱{{ number_format($summary['discount'],2) }}</strong></div><div class="row"><span>Shipping</span><strong id="shipping">₱{{ number_format($summary['shipping'],2) }}</strong></div><div class="row total"><span>Total</span><strong id="total">₱{{ number_format($summary['total'],2) }}</strong></div><form id="selection-form" method="POST" action="{{ route('buyer.cart.select') }}">@csrf<div id="selection-inputs"></div></form><form method="POST" action="{{ route('buyer.cart.checkout') }}">@csrf<button class="checkout" id="checkout" type="submit" {{ $summary['item_count'] ? '' : 'disabled' }}>Checkout selected</button></form><p class="note">Only selected items will be included in checkout. Your cart will keep unchecked items for later.</p><a class="continue" href="{{ route('shop.index') }}">Continue shopping</a></aside>
        </div>
        <div class="promo"><strong>Have a promo code?</strong><span>Enter your code to apply discount</span><input placeholder="Enter promo code"><button type="button">Apply</button></div>
    @endif
</main>
<script>
(() => {
 const csrf=document.querySelector('meta[name="csrf-token"]').content, rows=[...document.querySelectorAll('[data-item]')], all=document.querySelector('#select-all');
 const money=n=>'₱'+Number(n).toLocaleString('en-PH',{minimumFractionDigits:2,maximumFractionDigits:2});
 function selected(){return rows.filter(r=>r.querySelector('.item-check').checked)}
 function sync(){
  if(!rows.length) return;
  const chosen=selected();
  const subtotal=chosen.reduce((s,r)=>s+Number(r.dataset.price)*Number(r.querySelector('[data-quantity]').textContent),0);
  const discount=chosen.reduce((s,r)=>s+Number(r.dataset.discount),0);
  const shipping=chosen.length?15:0;
  const selectedCount=document.querySelector('#selected-count');
  const subtotalEl=document.querySelector('#subtotal');
  const discountEl=document.querySelector('#discount');
  const shippingEl=document.querySelector('#shipping');
  const totalEl=document.querySelector('#total');
  const checkout=document.querySelector('#checkout');
  const inputs=document.querySelector('#selection-inputs');
  if(selectedCount) selectedCount.textContent=chosen.reduce((s,r)=>s+Number(r.querySelector('[data-quantity]').textContent),0);
  if(subtotalEl) subtotalEl.textContent=money(subtotal+discount);
  if(discountEl) discountEl.textContent='- '+money(discount);
  if(shippingEl) shippingEl.textContent=money(shipping);
  if(totalEl) totalEl.textContent=money(subtotal+shipping);
  if(checkout) checkout.disabled=!chosen.length;
  if(all){all.checked=chosen.length===rows.length;all.indeterminate=chosen.length>0&&chosen.length<rows.length;}
  if(inputs) inputs.innerHTML=chosen.map(r=>`<input type="hidden" name="selected_ids[]" value="${r.dataset.productId}">`).join('');
 }
 async function saveSelection(){const body=new FormData();body.append('_token',csrf);selected().forEach(r=>body.append('selected_ids[]',r.dataset.productId));await fetch('{{ route('buyer.cart.select') }}',{method:'POST',headers:{'X-Requested-With':'XMLHttpRequest','Accept':'application/json'},body});}
 rows.forEach(r=>{r.querySelector('.item-check').addEventListener('change',()=>{sync();saveSelection()});r.querySelector('[data-minus]').addEventListener('click',()=>change(r,-1));r.querySelector('[data-plus]').addEventListener('click',()=>change(r,1));});
 all?.addEventListener('change',()=>{rows.forEach(r=>r.querySelector('.item-check').checked=all.checked);sync();saveSelection()});
 async function change(r,delta){const q=r.querySelector('[data-quantity]'), next=Number(q.textContent)+delta;if(next<1||next>Number(r.dataset.stock))return;q.textContent=next;sync();const body=new FormData();body.append('_token',csrf);body.append('_method','PATCH');body.append('quantity',next);await fetch(`/cart/${r.dataset.productId}`,{method:'POST',headers:{'X-Requested-With':'XMLHttpRequest','Accept':'application/json'},body});}
 sync();
})();
</script>
</body></html>
