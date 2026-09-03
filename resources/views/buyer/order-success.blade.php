<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lumora | Order placed</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        body { margin:0; background:#fbefea; color:#3a2e30; font-family:Inter,sans-serif; }
        .box { max-width:680px; margin:80px auto; padding:38px; background:#fffdfb; border:1px solid #ebddd8; border-radius:14px; text-align:center; }
        h1 { color:#3d1b3d; font-family:Georgia,serif; }
        .number { color:#b96562; font-weight:bold; }
        a { display:inline-block; margin:18px 8px 0; padding:12px 18px; border:1px solid #b96562; border-radius:8px; color:#3d1b3d; text-decoration:none; }
    </style>
</head>
<body>
    <main class="box">
        <h1>Thank you for your order.</h1>
        <p>Your order <span class="number">#{{ $order->id }}</span> has been placed and is currently pending.</p>
        <p>Total: <strong>₱{{ number_format((float) $order->total, 2) }}</strong></p>
        <a href="{{ route('shop.index') }}">Continue shopping</a>
        <a href="{{ route('buyer.cart') }}">View cart</a>
    </main>
</body>
</html>