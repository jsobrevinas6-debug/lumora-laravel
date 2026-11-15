<?php

use App\Models\Product;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Schedule;
use Illuminate\Support\Str;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('users:lift-suspensions', function () {
    $count = app(\App\Services\UserAccountStatusService::class)->liftExpiredSuspensions();
    $this->info("Reactivated {$count} expired suspended account(s).");
    return self::SUCCESS;
})->purpose('Reactivate accounts whose timed suspensions have expired');

Schedule::command('users:lift-suspensions')->daily();

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

Artisan::command('products:set-approval {status : pending, approved, changes_requested, or rejected} {--seller= : Seller user ID} {--category= : Product category} {--ids= : Comma-separated product IDs}', function () {
    $status = (string) $this->argument('status');
    if (! in_array($status, Product::APPROVAL_STATUSES, true)) {
        $this->error('Status must be one of: '.implode(', ', Product::APPROVAL_STATUSES));
        return self::FAILURE;
    }
    $query = Product::query();
    if ($this->option('seller')) $query->where('seller_id', $this->option('seller'));
    if ($this->option('category')) $query->where('category', $this->option('category'));
    if ($this->option('ids')) $query->whereIn('id', array_filter(array_map('intval', explode(',', $this->option('ids')))));
    $products = $query->get();
    $this->info($products->count().' product(s) will change to '.$status.'.');
    if (! $this->confirm('Continue?')) return self::SUCCESS;
    foreach ($products as $product) {
        $old = $product->approval_status;
        $product->forceFill([
            'approval_status' => $status,
            'submitted_at' => $status === 'pending' ? now() : $product->submitted_at,
            'approval_submitted_at' => $status === 'pending' ? now() : $product->approval_submitted_at,
            'status' => $product->status === 'archived' ? 'archived' : ($status === 'approved' ? 'active' : 'inactive'),
        ])->save();
        \App\Models\ProductApprovalLog::create(['product_id' => $product->id, 'action' => 'command_'.$status, 'note' => "Changed from {$old} to {$status} by products:set-approval", 'created_at' => now()]);
        $this->line("#{$product->id}: {$old} -> {$status}");
    }
    $this->info('Updated '.$products->count().' product(s).');
    return self::SUCCESS;
})->purpose('Change approval status for existing products after confirmation');

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

Artisan::command('google:check-config', function () {
    $appUrl = config('app.url');
    $clientId = config('services.google.client_id');
    $clientSecret = config('services.google.client_secret');
    $redirect = config('services.google.redirect');

    $this->line('APP_URL: '.($appUrl ?: 'MISSING'));
    $this->line('GOOGLE_CLIENT_ID: '.($clientId ? 'CONFIGURED' : 'MISSING'));
    $this->line('GOOGLE_CLIENT_SECRET: '.($clientSecret ? 'CONFIGURED' : 'MISSING'));
    $this->line('GOOGLE_REDIRECT_URI: '.($redirect ?: 'MISSING'));
})->purpose('Check Google OAuth configuration safely');

Artisan::command('google:check-oauth', function () {
    $this->call('google:check-config');
})->purpose('Check Google OAuth configuration safely');

Artisan::command('buyers:purge-ids', function () {
    $users = \App\Models\User::query()->where('role', 'buyer')
        ->where(function ($query) { $query->whereNotNull('id_file_path')->orWhereNotNull('buyer_id_document'); })
        ->get(['id', 'id_file_path', 'buyer_id_document']);
    $paths = $users->flatMap(fn ($user) => [$user->id_file_path, $user->buyer_id_document])->filter()->unique()->values();
    $disk = Storage::disk('local');
    $existing = $paths->filter(fn ($path) => $disk->exists($path));

    $this->info($existing->count().' private buyer ID file(s) exist across '.$users->count().' buyer account(s).');
    if (! $this->confirm('Permanently delete these files and clear ID type and file path fields?')) {
        $this->info('No files or account data were changed.');
        return;
    }

    $deleted = 0;
    foreach ($existing as $path) {
        if ($disk->delete($path)) $deleted++;
    }
    \App\Models\User::query()->whereIn('id', $users->pluck('id'))->update([
        'id_type' => null, 'id_file_path' => null, 'buyer_id_document' => null,
    ]);
    \Illuminate\Support\Facades\Log::notice('Buyer ID files purged by operator.', [
        'files_found' => $existing->count(), 'files_deleted' => $deleted, 'buyer_accounts_cleared' => $users->count(),
    ]);
    $this->info("Deleted {$deleted} file(s) and cleared ID fields for {$users->count()} buyer account(s).");
})->purpose('List and, after confirmation, permanently delete stored buyer ID files');
