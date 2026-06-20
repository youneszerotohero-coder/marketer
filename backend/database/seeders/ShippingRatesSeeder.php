<?php

namespace Database\Seeders;

use App\Models\Commune;
use App\Models\ShippingRate;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;

class ShippingRatesSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Load and decode JSON files using portable paths
        $wilayasPath = base_path('storage/app/data/Wilaya_Of_Algeria.json');
        $communesPath = base_path('storage/app/data/Commune_Of_Algeria.json');

        if (! File::exists($wilayasPath) || ! File::exists($communesPath)) {
            $this->command->error("Wilayas or Communes JSON files not found at: {$wilayasPath} / {$communesPath}");

            return;
        }

        $wilayas = json_decode(File::get($wilayasPath), true);
        $communes = json_decode(File::get($communesPath), true);

        $this->command->info('Seeding '.count($wilayas).' wilayas...');

        // Track mapping of JSON wilaya 'id' -> DB ShippingRate 'id'
        $wilayaMap = [];

        foreach ($wilayas as $w) {
            $paddedCode = str_pad($w['code'], 2, '0', STR_PAD_LEFT);

            // Default pricing logic
            $homePrice = 800;
            $deskPrice = 600;

            switch ($paddedCode) {
                case '16': // Alger
                    $homePrice = 400;
                    $deskPrice = 200;
                    break;
                case '09': // Blida
                case '35': // Boumerdes
                case '42': // Tipaza
                    $homePrice = 450;
                    $deskPrice = 250;
                    break;
                case '02': // Chlef
                case '31': // Oran
                    $homePrice = 600;
                    $deskPrice = 400;
                    break;
                case '06': // Bejaia
                case '15': // Tizi Ouzou
                    $homePrice = 700;
                    $deskPrice = 450;
                    break;
                case '25': // Constantine
                    $homePrice = 750;
                    $deskPrice = 500;
                    break;
                case '23': // Annaba
                    $homePrice = 800;
                    $deskPrice = 550;
                    break;
                case '47': // Ghardaia
                    $homePrice = 1000;
                    $deskPrice = 700;
                    break;
                case '39': // El Oued
                    $homePrice = 1100;
                    $deskPrice = 750;
                    break;
                case '01': // Adrar
                case '33': // Illizi
                case '37': // Tindouf
                    $homePrice = 1200;
                    $deskPrice = 800;
                    break;
            }

            // Correct any misspelled names from the JSON
            $nameFr = $w['name'];
            if ($paddedCode === '19') {
                $nameFr = 'Sétif';
            }
            if ($paddedCode === '20') {
                $nameFr = 'Saïda';
            }
            if ($paddedCode === '47') {
                $nameFr = 'Ghardaïa';
            }

            $rate = ShippingRate::updateOrCreate(
                ['wilaya_code' => $paddedCode],
                [
                    'wilaya_name' => $nameFr,
                    'wilaya_name_ar' => $w['ar_name'],
                    'home_price' => $homePrice,
                    'desk_price' => $deskPrice,
                    'is_active' => true,
                    'home_active' => true,
                    'desk_active' => true,
                ]
            );

            $wilayaMap[$w['id']] = $rate->id;
        }

        $this->command->info('Seeding '.count($communes).' communes...');

        // To make it faster, we can prepare the insert array
        $communeData = [];
        $now = now();

        foreach ($communes as $c) {
            $jsonWilayaId = $c['wilaya_id'];
            if (! isset($wilayaMap[$jsonWilayaId])) {
                continue;
            }

            $communeData[] = [
                'shipping_rate_id' => $wilayaMap[$jsonWilayaId],
                'name' => $c['name'],
                'name_ar' => $c['ar_name'],
                'post_code' => $c['post_code'] ?? null,
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        // Chunk insert to avoid database limits
        Commune::truncate(); // Reset communes
        foreach (array_chunk($communeData, 200) as $chunk) {
            Commune::insert($chunk);
        }

        $this->command->info('Seeding completed successfully!');
    }
}
