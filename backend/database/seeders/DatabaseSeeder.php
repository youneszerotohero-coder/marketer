<?php

namespace Database\Seeders;

use App\Models\Brand;
use App\Models\Category;
use App\Models\Product;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@marketer.local'],
            [
                'name' => 'Default Admin',
                'role' => 'admin',
                'status' => 'active',
                'password' => 'password',
            ]
        );

        User::updateOrCreate(
            ['email' => 'confirmatrice@marketer.local'],
            [
                'name' => 'Default Confirmatrice',
                'role' => 'confirmatrice',
                'status' => 'active',
                'password' => 'password',
            ]
        );

        User::updateOrCreate(
            ['email' => 'marketer@marketer.local'],
            [
                'name' => 'Default Marketer',
                'role' => 'marketer',
                'status' => 'active',
                'suspended_at' => null,
                'password' => 'password',
            ]
        );

        $category = Category::firstOrCreate(['name' => 'Electronics'], ['status' => 'active']);
        $brand = Brand::firstOrCreate(['name' => 'AudioTech'], ['status' => 'active']);

        $product = Product::firstOrCreate(
            ['name' => 'Wireless Headphones'],
            [
                'category_id' => $category->id,
                'brand_id' => $brand->id,
                'description' => 'Seed product for mobile and admin integration tests.',
                'status' => 'active',
            ]
        );

        $product->variants()->firstOrCreate(
            ['sku' => 'WH-1000-SEED'],
            [
                'purchase_price' => 3000,
                'sale_price' => 4500,
                'commission_value' => 450,
                'commission_type' => 'fixed',
                'stock' => 25,
                'status' => 'active',
            ]
        );

        Setting::updateOrCreate(['key' => 'commission.default_type'], ['value' => 'fixed']);
        Setting::updateOrCreate(['key' => 'delivery.provider'], ['value' => 'mock']);
    }
}
