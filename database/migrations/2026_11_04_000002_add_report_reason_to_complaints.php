<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (! Schema::hasColumn('complaints', 'report_reason')) {
            Schema::table('complaints', function (Blueprint $table) {
                $table->string('report_reason', 100)->nullable();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('complaints', 'report_reason')) {
            Schema::table('complaints', function (Blueprint $table) {
                $table->dropColumn('report_reason');
            });
        }
    }
};
