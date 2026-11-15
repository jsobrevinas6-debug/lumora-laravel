<?php

namespace App\Support;

use App\Models\ReturnRequestEvidence;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Support\Facades\Storage;
use Throwable;

class ReturnEvidenceFiles
{
    private const DIRECTORY = 'return_request_evidence';

    public static function diskName(): string
    {
        return (string) config('filesystems.return_evidence_disk', config('filesystems.default', 'local'));
    }

    /** @return array{0: FilesystemAdapter, 1: string}|null */
    public static function locate(?string $storedPath): ?array
    {
        $path = ltrim(str_replace('\\', '/', trim((string) $storedPath)), '/');
        $path = preg_replace('#^(?:public/|storage/)+#', '', $path);

        if ($path === '' || preg_match('#(^|/)\.{1,2}(/|$)#', $path)) {
            return null;
        }

        $paths = str_starts_with($path, self::DIRECTORY.'/')
            ? [$path, self::DIRECTORY.'/'.basename($path)]
            : [self::DIRECTORY.'/'.basename($path)];

        $diskNames = array_unique([
            self::diskName(),
            config('filesystems.default', 'local'),
            'local',
            'public',
            ...collect(config('filesystems.disks', []))
                ->filter(fn ($disk) => ($disk['driver'] ?? null) === 's3')
                ->keys()
                ->all(),
        ]);

        foreach ($diskNames as $diskName) {
            try {
                $disk = Storage::disk($diskName);
                foreach (array_unique($paths) as $candidate) {
                    if ($disk->exists($candidate)) {
                        return [$disk, $candidate];
                    }
                }
            } catch (Throwable) {
                // A disk may be configured only in some environments (for example S3).
            }
        }

        return null;
    }

    public static function response(ReturnRequestEvidence $evidence)
    {
        $location = self::locate($evidence->file_path);
        abort_unless($location, 404);

        [$disk, $path] = $location;
        $mimeType = $evidence->mime_type;
        if (! filled($mimeType)) {
            try {
                $mimeType = $disk->mimeType($path);
            } catch (Throwable) {
                $mimeType = null;
            }
        }
        $mimeType ??= str_ends_with(strtolower($path), '.mp4') ? 'video/mp4' : 'image/jpeg';

        return $disk->response($path, basename($path), [
            'Content-Type' => $mimeType,
            'X-Content-Type-Options' => 'nosniff',
            'Cache-Control' => 'private, no-store',
        ], 'inline');
    }
}
