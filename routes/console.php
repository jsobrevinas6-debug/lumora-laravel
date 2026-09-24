<?php

use App\Models\Product;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Storage;

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
            $storagePath = $normalizedPath ? Storage::disk('public')->path($normalizedPath) : null;
            $publicPath = $normalizedPath ? public_path('storage/'.$normalizedPath) : null;
            $storageExists = $normalizedPath && Storage::disk('public')->exists($normalizedPath);
            $publicExists = $publicPath && file_exists($publicPath);

            $this->line('-----------------------------------------');
            $this->line('ID: '.$product->id);
            $this->line('Name: '.$product->name);
            $this->line('Database Image Value: '.($product->image ?: 'NULL'));
            $this->line('Normalized Path: '.($normalizedPath ?: 'NULL'));
            $this->line('Expected Storage Path: '.($storagePath ?: 'NULL'));
            $this->line('Storage File Exists: '.($storageExists ? 'YES' : 'NO'));
            $this->line('Expected Public Path: '.($publicPath ?: 'NULL'));
            $this->line('Public File Exists: '.($publicExists ? 'YES' : 'NO'));
            $this->line('Generated image_url: '.$product->image_url);
        });

    $this->line('-----------------------------------------');
})->purpose('Report product image paths, disk existence, and generated URLs without changing data');
