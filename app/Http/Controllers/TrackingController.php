<?php

namespace App\Http\Controllers;

use App\Models\Parcel;
use App\Models\Shipment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class TrackingController extends Controller
{
    public function index(Request $request, ?string $trackingNumber = null): View|JsonResponse
    {
        $trackingNumber = trim((string) ($trackingNumber ?? $request->query('tracking', '')));
        $shipment = null;
        $parcel = null;
        $notFound = false;

        if ($trackingNumber !== '') {
            $numericOrderId = null;
            if (preg_match('/^(?:LMR-\d{4}-0*|ORD-0*|PH-LMR-0*)(\d+)$/i', $trackingNumber, $ordMatches)) {
                $numericOrderId = $ordMatches[1];
            }

            $shipment = Shipment::query()
                ->with(['order', 'trackingEvents', 'parcels.rider.user', 'parcels.area', 'parcels.scans'])
                ->where(function ($query) use ($trackingNumber) {
                    $query->where('tracking_number', $trackingNumber);
                    if (preg_match('/^LM-TRK-0*(\d+)$/i', $trackingNumber, $matches)) {
                        $query->orWhere('id', $matches[1]);
                    }
                })
                ->first();

            if (! $shipment) {
                // Check if search matches parcel barcode, parcel number, or e-commerce order ID/number
                $parcel = Parcel::with(['shipment.order', 'shipment.trackingEvents', 'rider.user', 'area', 'scans'])
                    ->where(function ($q) use ($trackingNumber, $numericOrderId) {
                        $q->where('barcode', $trackingNumber)
                          ->orWhere('parcel_number', $trackingNumber);
                        if ($numericOrderId !== null) {
                            $q->orWhere('barcode', $numericOrderId);
                        }
                    })
                    ->first();

                if ($parcel && $parcel->shipment) {
                    $shipment = $parcel->shipment;
                }
            } else {
                $parcel = $shipment->parcels->first();
            }

            $notFound = ($shipment === null && $parcel === null);
        }

        $effectiveStatus = $parcel?->status === 'returned'
            ? 'returned'
            : ($shipment?->status ?? $parcel?->status ?? 'pending');
        $currentStage = ($shipment || $parcel) ? $this->stageFor($effectiveStatus) : 0;
        $stages = [
            ['key' => 'pending', 'label' => 'Order Received'],
            ['key' => 'packed', 'label' => 'Sorting Center'],
            ['key' => 'in_transit', 'label' => 'In Transit'],
            ['key' => 'out_for_delivery', 'label' => 'Out for Delivery'],
            ['key' => 'delivered', 'label' => 'Delivered'],
        ];

        if ($request->wantsJson() || $request->query('format') === 'json') {
            $branchName = $parcel?->branch ?: ($parcel?->city ?: null);
            $hubName = $branchName ? (stripos($branchName, 'hub') !== false ? $branchName : "{$branchName} Hub") : 'Laguna Central Sorting Hub';
            $riderProfile = $parcel?->rider ?: $shipment?->parcels?->first()?->rider;

            return response()->json([
                'status' => 'success',
                'tracking_number' => $parcel?->parcel_number ?? ($shipment?->tracking_number ?? $trackingNumber),
                'parcel_number' => $parcel?->parcel_number ?? $shipment?->tracking_number,
                'barcode' => $parcel?->barcode,
                'found' => ! $notFound,
                'effective_status' => $effectiveStatus,
                'parcel_status' => $parcel?->status ?? $effectiveStatus,
                'status_label' => ucwords(str_replace('_', ' ', $parcel?->status ?? $effectiveStatus)),
                'current_stage' => $currentStage,
                'is_delivered' => $effectiveStatus === 'delivered',
                'is_out_for_delivery' => $effectiveStatus === 'out_for_delivery',
                'branch' => $branchName,
                'hub_name' => $hubName,
                'area_name' => $parcel?->area?->name,
                'sort_bin' => $parcel?->sort_bin,
                'courier_name' => $riderProfile?->user?->name,
                'courier_phone' => $riderProfile?->phone,
                'courier_vehicle' => $parcel?->metadata['linehaul_truck'] ?? ($riderProfile?->vehicle_type ?? 'Motorcycle Fleet'),
                'linehaul_truck' => $parcel?->metadata['linehaul_truck'] ?? null,
                'is_hub_transfer' => (bool) ($parcel?->metadata['is_hub_transfer'] ?? false),
                'transfer_state' => $parcel?->metadata['transfer_state'] ?? null,
                'destination' => $parcel
                    ? implode(', ', array_filter([$parcel->address_line, $parcel->city, $parcel->province]))
                    : ($shipment ? ($shipment->destination_city . ', ' . $shipment->destination_state) : ''),
                'events' => ($shipment?->trackingEvents ?? collect())->map(fn ($e) => [
                    'status' => $e->status,
                    'label' => $e->label,
                    'description' => $e->description,
                    'notes' => $e->description,
                    'location' => $e->location,
                    'time' => $e->occurred_at?->format('M j, Y g:i A'),
                    'occurred_at' => $e->occurred_at?->format('M j, Y h:i A'),
                    'diff' => $e->occurred_at?->diffForHumans(),
                ]),
                'scans' => ($parcel?->scans ?? collect())->map(fn ($s) => [
                    'type' => $s->scan_type,
                    'scan_type' => ucwords(str_replace('_', ' ', $s->scan_type)),
                    'location' => $branchName ?: 'Laguna Hub',
                    'note' => $s->note,
                    'notes' => $s->note,
                    'time' => $s->scanned_at?->format('M j, Y g:i A'),
                    'scanned_at' => $s->scanned_at?->format('M j, Y h:i A'),
                    'diff' => $s->scanned_at?->diffForHumans(),
                ]),
            ]);
        }

        return view('tracking.index', compact('shipment', 'parcel', 'trackingNumber', 'notFound', 'currentStage', 'stages'));
    }

    private function stageFor(?string $status): int
    {
        return match ($status) {
            'delivered' => 4,
            'out_for_delivery' => 3,
            'in_transit', 'rider_received' => 2,
            'packed', 'sorted', 'assigned', 'scanned' => 1,
            'pending', 'received' => 0,
            default => 0,
        };
    }
}
