@extends('layouts.legal')

@section('title', 'Data Privacy Notice')

@section('content')
<main class="legal-page">
    <a class="legal-back" href="{{ route('register') }}">&larr; Back to sign up</a>
    <h1>Data Privacy Notice</h1>
    <article class="legal-document">@include('legal.content.privacy-notice')</article>
</main>
@endsection
