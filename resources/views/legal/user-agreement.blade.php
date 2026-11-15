@extends('layouts.legal')

@section('title', 'Lumora User Agreement')

@section('content')
<main class="legal-page">
    <a class="legal-back" href="{{ route('register') }}">&larr; Back to sign up</a>
    <h1>Lumora User Agreement</h1>
    <article class="legal-document">@include('legal.content.user-agreement')</article>
</main>
@endsection
