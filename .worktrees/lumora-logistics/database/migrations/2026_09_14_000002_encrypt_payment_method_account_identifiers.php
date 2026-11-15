<?php

use Illuminate\Contracts\Encryption\DecryptException;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('payment_methods') || ! Schema::hasColumn('payment_methods', 'account_identifier')) {
            return;
        }

        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE payment_methods MODIFY account_identifier TEXT NULL');
        }

        Schema::table('payment_methods', function (Blueprint $table) {
            $table->index(['user_id', 'type'], 'payment_methods_user_id_type_index');
        });

        DB::table('payment_methods')
            ->whereNotNull('account_identifier')
            ->orderBy('id')
            ->select('id', 'account_identifier')
            ->chunkById(100, function ($paymentMethods): void {
                foreach ($paymentMethods as $paymentMethod) {
                    $identifier = (string) $paymentMethod->account_identifier;

                    if ($identifier === '' || $this->isEncrypted($identifier)) {
                        continue;
                    }

                    DB::table('payment_methods')
                        ->where('id', $paymentMethod->id)
                        ->update(['account_identifier' => Crypt::encryptString($identifier)]);
                }
            });
    }

    public function down(): void
    {
        //
    }

    private function isEncrypted(string $value): bool
    {
        try {
            Crypt::decryptString($value);

            return true;
        } catch (DecryptException) {
            return false;
        }
    }
};
