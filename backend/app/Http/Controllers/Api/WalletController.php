<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Wallet\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function summary(Request $request, WalletService $wallet): JsonResponse
    {
        return response()->json($wallet->balanceFor($request->user()));
    }

    public function transactions(Request $request): JsonResponse
    {
        return response()->json(
            $request->user()->walletTransactions()->latest()->paginate((int) $request->query('per_page', 20))
        );
    }

    public function withdraw(Request $request, WalletService $wallet): JsonResponse
    {
        $data = $request->validate([
            'amount' => ['required', 'numeric', 'min:1'],
            'payment_method' => ['required', 'string', 'max:80'],
            'payout_details' => ['required', 'array'],
        ]);

        return response()->json($wallet->requestWithdrawal($request->user(), $data), 201);
    }
}
