<?php

namespace App\Providers;

use App\Services\Delivery\DeliveryGateway;
use App\Services\Delivery\MockDeliveryGateway;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(DeliveryGateway::class, MockDeliveryGateway::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
