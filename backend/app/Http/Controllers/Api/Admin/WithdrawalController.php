<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\WalletTransaction;
use App\Services\Wallet\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WithdrawalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            WalletTransaction::with('marketer')
                ->where('type', 'withdrawal')
                ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
                ->latest()
                ->paginate((int) $request->query('per_page', 20))
        );
    }

    public function approve(WalletTransaction $withdrawal, WalletService $wallet): JsonResponse
    {
        abort_unless($withdrawal->type === 'withdrawal', 404);
        abort_unless($withdrawal->status === 'pending', 422, 'Withdrawal already reviewed.');

        $balance = $wallet->balanceFor($withdrawal->marketer);
        abort_if((float) $withdrawal->amount > $balance['available'] + (float) $withdrawal->amount, 422, 'Insufficient balance.');

        $withdrawal->update(['status' => 'approved']);

        return response()->json($withdrawal);
    }

    public function reject(Request $request, WalletTransaction $withdrawal): JsonResponse
    {
        abort_unless($withdrawal->type === 'withdrawal', 404);
        $withdrawal->update([
            'status' => 'rejected',
            'notes' => $request->input('notes'),
        ]);

        return response()->json($withdrawal);
    }
}
