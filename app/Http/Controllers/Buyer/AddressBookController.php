<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use App\Models\UserAddress;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AddressBookController extends Controller
{
    public function store(Request $request): JsonResponse|RedirectResponse
    {
        $data = $this->validatedAddress($request);
        $user = $request->user();

        $address = DB::transaction(function () use ($user, $data) {
            $hasAddresses = $user->addresses()->lockForUpdate()->exists();
            $makeDefault = ! $hasAddresses || (bool) ($data['is_default'] ?? false);
            unset($data['is_default']);
            if ($makeDefault) {
                $user->addresses()->update(['is_default' => false]);
            }

            return $user->addresses()->create($data + ['is_default' => $makeDefault]);
        });
        $request->session()->put('checkout_address_id', $address->id);

        return $this->respond($request, $address, 'Delivery address saved.', 201);
    }

    public function update(Request $request, int $address): JsonResponse|RedirectResponse
    {
        $record = $request->user()->addresses()->findOrFail($address);
        $data = $this->validatedAddress($request);
        $makeDefault = (bool) ($data['is_default'] ?? false);
        unset($data['is_default']);

        DB::transaction(function () use ($request, $record, $data, $makeDefault) {
            if ($makeDefault) {
                $request->user()->addresses()->where('id', '<>', $record->id)->update(['is_default' => false]);
            }
            $record->fill($data);
            $record->is_default = $makeDefault;
            $record->save();
        });
        $request->session()->put('checkout_address_id', $record->id);

        return $this->respond($request, $record->fresh(), 'Delivery address updated.');
    }

    public function destroy(Request $request, int $address): JsonResponse|RedirectResponse
    {
        $record = $request->user()->addresses()->findOrFail($address);
        $activeStatuses = ['pending', 'processing', 'packed', 'shipped', 'out_for_delivery'];
        $activeOrders = $request->user()->orders()
            ->where('shipping_address_id', $record->id)
            ->whereIn('status', $activeStatuses)
            ->count();

        if ($activeOrders > 0 && ! $request->boolean('confirm_active_orders')) {
            return response()->json([
                'requires_confirmation' => true,
                'message' => 'This address is attached to an active order. Delete it anyway? Existing orders will keep their saved delivery details.',
            ], 409);
        }

        $wasDefault = $record->is_default;
        DB::transaction(function () use ($record, $request, $wasDefault) {
            $record->delete();
            if ($wasDefault) {
                $replacement = $request->user()->addresses()->oldest('id')->first();
                $replacement?->update(['is_default' => true]);
            }
        });

        $nextAddress = $request->user()->addresses()->orderByDesc('is_default')->latest('id')->first();
        $request->session()->put('checkout_address_id', $nextAddress?->id);

        return response()->json([
            'message' => 'Delivery address deleted.',
            'addresses' => $request->user()->addresses()->orderByDesc('is_default')->latest('id')->get(),
            'selected_address_id' => $nextAddress?->id,
        ]);
    }

    private function validatedAddress(Request $request): array
    {
        return $request->validate([
            'full_name' => ['required', 'string', 'max:255'],
            'phone_number' => ['required', 'string', 'max:25', 'regex:/^[0-9+() -]{7,25}$/'],
            'region' => ['required', 'string', 'max:255'],
            'region_code' => ['nullable', 'string', 'max:20', 'regex:/^[A-Za-z0-9_-]+$/'],
            'province' => ['required', 'string', 'max:255'],
            'province_code' => ['nullable', 'string', 'max:20', 'regex:/^[A-Za-z0-9_-]+$/'],
            'city_municipality' => ['required', 'string', 'max:255'],
            'city_municipality_code' => ['nullable', 'string', 'max:20', 'regex:/^[A-Za-z0-9_-]+$/'],
            'barangay' => ['required', 'string', 'max:255'],
            'barangay_code' => ['nullable', 'string', 'max:20', 'regex:/^[A-Za-z0-9_-]+$/'],
            'street_address' => ['required', 'string', 'max:255'],
            'postal_code' => ['required', 'string', 'regex:/^\d{4}$/'],
            'label' => ['required', 'string', 'in:home,work,other'],
            'is_default' => ['nullable', 'boolean'],
        ]);
    }

    private function respond(Request $request, UserAddress $address, string $message, int $status = 200): JsonResponse|RedirectResponse
    {
        if ($request->expectsJson()) {
        return response()->json([
            'address' => $address,
            'addresses' => $request->user()->addresses()->orderByDesc('is_default')->latest('id')->get(),
            'message' => $message,
        ], $status);
        }

        return back()->with('success', $message);
    }
}
