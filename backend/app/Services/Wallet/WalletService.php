<?php

namespace App\Services\Wallet;

use App\Models\Order;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Support\Facades\DB;

class WalletService
{
    public function balanceFor(User $marketer): array
    {
        $approvedCommissions = $marketer->walletTransactions()
            ->where('type', 'commission')
            ->where('status', 'approved')
            ->sum('amount');

        $returnFees = $marketer->walletTransactions()
            ->where('type', 'return_fee')
            ->where('status', 'approved')
            ->sum('amount');

        $approvedWithdrawals = $marketer->walletTransactions()
            ->where('type', 'withdrawal')
            ->where('status', 'approved')
            ->sum('amount');

        $pendingWithdrawals = $marketer->walletTransactions()
            ->where('type', 'withdrawal')
            ->where('status', 'pending')
            ->sum('amount');

        return [
            'available' => round($approvedCommissions - $returnFees - $approvedWithdrawals - $pendingWithdrawals, 2),
            'pending_withdrawals' => round($pendingWithdrawals, 2),
            'earned' => round($approvedCommissions - $returnFees, 2),
        ];
    }

    public function createCommission(Order $order): ?WalletTransaction
    {
        if ($order->status !== Order::STATUS_DELIVERED || (float) $order->marketer_commission <= 0) {
            return null;
        }

        return WalletTransaction::updateOrCreate(
            ['order_id' => $order->id, 'type' => 'commission'],
            [
                'marketer_id' => $order->marketer_id,
                'amount' => $order->marketer_commission,
                'status' => 'approved',
                'notes' => 'Commission generated after delivery.',
            ]
        );
    }

    public function cancelCommission(Order $order): void
    {
        WalletTransaction::where('order_id', $order->id)
            ->where('type', 'commission')
            ->where('status', 'approved')
            ->update([
                'status' => 'cancelled',
                'notes' => 'Commission cancelled due to status change.',
            ]);
    }

    public function createReturnFee(Order $order): ?WalletTransaction
    {
        if (!in_array($order->status, [Order::STATUS_FAILED])) {
            return null;
        }

        $setting = \App\Models\Setting::where('key', 'return_fee')->first();
        $returnFee = $setting ? (float) $setting->value : 400.0; // Default to 400 if not set

        if ($returnFee <= 0) {
            return null;
        }

        return WalletTransaction::updateOrCreate(
            ['order_id' => $order->id, 'type' => 'return_fee'],
            [
                'marketer_id' => $order->marketer_id,
                'amount' => $returnFee,
                'status' => 'approved',
                'notes' => 'Return fee deducted for failed/returned order.',
            ]
        );
    }

    public function cancelReturnFee(Order $order): void
    {
        WalletTransaction::where('order_id', $order->id)
            ->where('type', 'return_fee')
            ->where('status', 'approved')
            ->update([
                'status' => 'cancelled',
                'notes' => 'Return fee refunded due to status change.',
            ]);
    }

    public function requestWithdrawal(User $marketer, array $data): WalletTransaction
    {
        return DB::transaction(function () use ($marketer, $data) {
            $balance = $this->balanceFor($marketer);

            if ((float) $data['amount'] <= 0 || (float) $data['amount'] > $balance['available']) {
                abort(422, 'Insufficient available balance.');
            }

            return WalletTransaction::create([
                'marketer_id' => $marketer->id,
                'amount' => $data['amount'],
                'type' => 'withdrawal',
                'status' => 'pending',
                'payment_method' => $data['payment_method'] ?? null,
                'payout_details' => $data['payout_details'] ?? null,
            ]);
        });
    }
}
