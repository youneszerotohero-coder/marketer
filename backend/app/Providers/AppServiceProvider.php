<?php

namespace App\Providers;

use App\Models\Setting;
use App\Services\Delivery\DeliveryGateway;
use App\Services\Delivery\MockDeliveryGateway;
use App\Services\Delivery\ZrExpressGateway;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(DeliveryGateway::class, function () {
            $provider = Setting::where('key', 'delivery.provider')->first()?->value ?? 'zr_express';

            return $provider === 'mock'
                ? app(MockDeliveryGateway::class)
                : app(ZrExpressGateway::class);
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
