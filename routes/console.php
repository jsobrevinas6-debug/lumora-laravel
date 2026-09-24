<?php

use App\Models\Product;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('products:check-images', function () {
    $publicStoragePath = public_path('storage');
    $expectedStorageTarget = storage_path('app/public');
    $resolvedPublicStorage = realpath($publicStoragePath);
    $resolvedStorageTarget = realpath($expectedStorageTarget);

    $this->line('APP_URL: '.config('app.url'));
    $this->line('Public disk URL: '.config('filesystems.disks.public.url'));
    $this->line('public/storage: '.(file_exists($publicStoragePath) ? 'EXISTS' : 'MISSING'));
    $this->line('public/storage is symlink: '.(is_link($publicStoragePath) ? 'YES' : 'NO'));
    $this->line('public/storage resolved path: '.($resolvedPublicStorage ?: 'MISSING'));
    $this->line('Expected target: '.$expectedStorageTarget);
    $this->line('public/storage points to expected target: '.($resolvedPublicStorage && $resolvedStorageTarget && $resolvedPublicStorage === $resolvedStorageTarget ? 'YES' : 'NO'));
    $this->newLine();

    Product::query()
        ->select('id', 'name', 'image')
        ->orderBy('id')
        ->each(function (Product $product) {
            $normalizedPath = Product::normalizeImagePath($product->image);
            $publicProductPath = Product::publicProductImagePath($product->image);
            $storagePath = $normalizedPath ? Storage::disk('public')->path($normalizedPath) : null;
            $publicStoragePath = $normalizedPath ? public_path('storage/'.$normalizedPath) : null;
            $publicProductsPath = $publicProductPath ? public_path($publicProductPath) : null;
            $storageExists = $normalizedPath && Storage::disk('public')->exists($normalizedPath);
            $publicStorageExists = $publicStoragePath && file_exists($publicStoragePath);
            $publicProductsExists = $publicProductsPath && file_exists($publicProductsPath);

            $this->line('-----------------------------------------');
            $this->line('ID: '.$product->id);
            $this->line('Name: '.$product->name);
            $this->line('Database Image Value: '.($product->image ?: 'NULL'));
            $this->line('Normalized Path: '.($normalizedPath ?: 'NULL'));
            $this->line('Expected Storage Path: '.($storagePath ?: 'NULL'));
            $this->line('Storage File Exists: '.($storageExists ? 'YES' : 'NO'));
            $this->line('Expected Public Storage Path: '.($publicStoragePath ?: 'NULL'));
            $this->line('Public Storage File Exists: '.($publicStorageExists ? 'YES' : 'NO'));
            $this->line('Expected Public Products Path: '.($publicProductsPath ?: 'NULL'));
            $this->line('Public Products File Exists: '.($publicProductsExists ? 'YES' : 'NO'));
            $this->line('Generated image_url: '.$product->image_url);
        });

    $this->line('-----------------------------------------');
})->purpose('Report product image paths, disk existence, and generated URLs without changing data');

Artisan::command('products:migrate-images-to-public', function () {
    $targetDirectory = public_path(Product::PUBLIC_PRODUCT_IMAGE_DIRECTORY);

    if (! File::exists($targetDirectory)) {
        File::makeDirectory($targetDirectory, 0755, true);
    }

    Product::query()
        ->select('id', 'name', 'image')
        ->orderBy('id')
        ->each(function (Product $product) use ($targetDirectory) {
            $stored = $product->image;
            $normalizedPath = Product::normalizeImagePath($stored);
            $publicPath = Product::publicProductImagePath($stored);

            $this->line('-----------------------------------------');
            $this->line('Product #'.$product->id.' '.$product->name);
            $this->line('OLD: '.($stored ?: 'NULL'));

            if (! $normalizedPath || ! $publicPath) {
                $this->line('SKIPPED: no image value');
                return;
            }

            if (file_exists(public_path($normalizedPath)) && $stored !== $normalizedPath) {
                $product->forceFill(['image' => $normalizedPath])->save();
                $this->line('SOURCE: '.public_path($normalizedPath));
                $this->line('DATABASE: '.$normalizedPath);
                $this->line('RESULT: normalized existing public path');
                return;
            }

            if (file_exists(public_path($publicPath))) {
                if ($stored !== $publicPath) {
                    $product->forceFill(['image' => $publicPath])->save();
                }

                $this->line('SOURCE: '.public_path($publicPath));
                $this->line('DATABASE: '.$publicPath);
                $this->line('RESULT: already in public/products');
                return;
            }

            if (! Storage::disk('public')->exists($normalizedPath)) {
                $this->line('SOURCE: '.Storage::disk('public')->path($normalizedPath));
                $this->line('SKIPPED: source file missing');
                return;
            }

            $source = Storage::disk('public')->path($normalizedPath);
            $extension = strtolower(pathinfo($normalizedPath, PATHINFO_EXTENSION) ?: pathinfo($source, PATHINFO_EXTENSION) ?: 'jpg');
            $filename = Str::uuid()->toString().'.'.$extension;
            $newPublicPath = Product::PUBLIC_PRODUCT_IMAGE_DIRECTORY.'/'.$filename;
            $target = $targetDirectory.DIRECTORY_SEPARATOR.$filename;

            File::copy($source, $target);
            $product->forceFill(['image' => $newPublicPath])->save();

            $this->line('SOURCE: '.$source);
            $this->line('COPIED: '.$target);
            $this->line('DATABASE: '.$newPublicPath);
        });

    $this->line('-----------------------------------------');
})->purpose('Copy legacy product images into public/products and update product image paths safely');

Artisan::command('google:check-oauth', function () {
    $clientId = config('services.google.client_id');
    $clientSecret = config('services.google.client_secret');
    $redirectUri = config('services.google.redirect');

    $this->line('Google redirect route exists: '.(Route::has('google.redirect') ? 'YES' : 'NO'));
    $this->line('Google callback route exists: '.(Route::has('google.callback') ? 'YES' : 'NO'));
    $this->line('Google redirect path: /auth/google/redirect');
    $this->line('Google callback path: /auth/google/callback');
    $this->line('Configured redirect URI: '.($redirectUri ?: 'NULL'));
    $this->line('Client ID configured: '.(filled($clientId) ? 'YES' : 'NO'));
    $this->line('Client secret configured: '.(filled($clientSecret) ? 'YES' : 'NO'));
})->purpose('Check Google OAuth route/config status without printing secrets');
