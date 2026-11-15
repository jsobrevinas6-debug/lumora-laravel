<?php

namespace App\Support;

use App\Models\SellerApplication;
use Illuminate\Http\Request;

class SellerApplicationFields
{
    public const DOCUMENT_DISK = 'public';
    public const DOCUMENT_DIRECTORY = 'seller_documents';

    public static function registrationRules(): array
    {
        return [
            'business_name' => ['required_if:signup_type,seller', 'nullable', 'string', 'max:255'],
            'category' => ['required_if:signup_type,seller', 'nullable', 'string', 'max:255'],
            'id_document' => ['required_if:signup_type,seller', 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'business_permit' => ['required_if:signup_type,seller', 'nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ];
    }

    public static function applicationRules(): array
    {
        return [
            'contact_number' => ['required', 'string', 'max:20'],
            'province' => ['required', 'string', 'max:255'],
            'municipality' => ['required', 'string', 'max:255'],
            'barangay' => ['required', 'string', 'max:255'],
            'street' => ['nullable', 'string', 'max:255'],
            'house_number' => ['nullable', 'string', 'max:100'],
            'business_name' => ['required', 'string', 'max:255'],
            'category' => ['required', 'string', 'max:255'],
            'id_document' => ['required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'business_permit' => ['required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'reason' => ['nullable', 'string', 'max:2000'],
        ];
    }

    public static function createFromRequest(Request $request, int $userId): SellerApplication
    {
        return SellerApplication::create([
            'user_id' => $userId,
            'business_name' => $request->input('business_name'),
            'category' => $request->input('category'),
            'id_document' => self::storeDocument($request, 'id_document'),
            'business_permit' => self::storeDocument($request, 'business_permit'),
            'reason' => $request->input('reason'),
            'status' => 'pending',
        ]);
    }

    private static function storeDocument(Request $request, string $field): ?string
    {
        return $request->file($field)?->store(self::DOCUMENT_DIRECTORY, self::DOCUMENT_DISK);
    }
}
