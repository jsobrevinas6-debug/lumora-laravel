<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('users', 'buyer_id_document')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('buyer_id_document')->nullable()->after('marketing_opt_in');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'buyer_id_document')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('buyer_id_document');
            });
        }
    }
};
