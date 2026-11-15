<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RiderProfile extends Model
{
    protected $fillable = [
        'user_id',
        'hub_id',
        'phone',
        'vehicle_type',
        'license_number',
        'license_photo_path',
        'or_cr_photo_path',
        'registration_status',
        'availability',
        'approved_at',
        'approved_by',
        'registration_note',
    ];
    protected function casts(): array { return ['approved_at' => 'datetime']; }
    public function user() { return $this->belongsTo(User::class); }
    public function hub() { return $this->belongsTo(Hub::class); }
    public function approver() { return $this->belongsTo(User::class, 'approved_by'); }
    public function areaAssignments() { return $this->hasMany(RiderAreaAssignment::class); }
    public function areas() { return $this->belongsToMany(DestinationArea::class, 'rider_area_assignments'); }
    public function parcels() { return $this->hasMany(Parcel::class, 'assigned_rider_id'); }
    public function commissions() { return $this->hasMany(CommissionTransaction::class); }
    public function remittances() { return $this->hasMany(Remittance::class); }

    public function scopeForBranch($query, ?string $branch, $areaIds = null)
    {
        if (! $branch) {
            return $query;
        }

        $areaIds = $areaIds ? collect($areaIds)->filter()->values() : DestinationArea::forBranch($branch)->pluck('id');
        $branchLower = mb_strtolower(trim($branch));

        return $query->where(function ($rq) use ($branchLower, $areaIds) {
            if ($areaIds->isNotEmpty()) {
                // 1. Rider explicitly covers at least one Barangay delivery area in this branch
                $rq->whereHas('areas', fn ($aq) => $aq->whereIn('destination_areas.id', $areaIds));
            }

            // 2. Or rider has NO areas assigned in another branch, and their user.branch or hub matches this branch
            $rq->orWhere(function ($sub) use ($branchLower, $areaIds) {
                $sub->whereDoesntHave('areas', function ($aq) use ($branchLower, $areaIds) {
                    $aq->whereNotNull('destination_areas.branch')
                       ->whereRaw("TRIM(destination_areas.branch) != ''")
                       ->whereRaw('LOWER(TRIM(destination_areas.branch)) != ?', [$branchLower]);
                    if ($areaIds->isNotEmpty()) {
                        $aq->whereNotIn('destination_areas.id', $areaIds);
                    }
                })->where(function ($hq) use ($branchLower) {
                    $hq->whereHas('user', fn ($uq) => $uq->whereRaw('LOWER(TRIM(branch)) = ?', [$branchLower]))
                       ->orWhereHas('hub', function ($hubQ) use ($branchLower) {
                           $hubQ->whereRaw('LOWER(TRIM(branch)) = ?', [$branchLower])
                                ->orWhereRaw('LOWER(TRIM(city)) = ?', [$branchLower])
                                ->orWhereRaw('LOWER(TRIM(name)) = ?', [$branchLower . ' hub']);
                       });
                });
            });
        });
    }

    public function getLicenseUrlAttribute(): ?string
    {
        if (! $this->license_photo_path) return null;
        if (str_starts_with($this->license_photo_path, 'http')) return $this->license_photo_path;
        return asset('storage/' . $this->license_photo_path);
    }

    public function getOrCrUrlAttribute(): ?string
    {
        if (! $this->or_cr_photo_path) return null;
        if (str_starts_with($this->or_cr_photo_path, 'http')) return $this->or_cr_photo_path;
        return asset('storage/' . $this->or_cr_photo_path);
    }
}
