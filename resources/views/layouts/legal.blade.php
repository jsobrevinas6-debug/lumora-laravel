<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Lumora Legal Information')</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body { margin:0; background:#fffaf6; color:#351128; font-family:Inter, sans-serif; }
        .legal-page { width:min(860px, calc(100% - 40px)); margin:0 auto; padding:48px 0 72px; }
        .legal-back { display:inline-block; margin-bottom:20px; color:#4a1233; font-size:.85rem; text-underline-offset:3px; }
        .legal-page h1 { margin:0 0 22px; font:600 clamp(2rem, 5vw, 2.6rem)/1.15 'Playfair Display', Georgia, serif; }
        .legal-page .legal-document { padding:clamp(20px, 5vw, 36px); border:1px solid #e8d8d0; border-radius:18px; background:#fffdfb; line-height:1.75; }
        @media (max-width:520px) { .legal-page { width:min(100% - 28px, 860px); padding-top:28px; } }
    </style>
</head>
<body>
    @yield('content')
</body>
</html>
