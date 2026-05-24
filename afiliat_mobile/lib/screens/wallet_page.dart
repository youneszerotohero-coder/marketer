import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  Map<String, dynamic>? _balance;
  List<dynamic> _transactions = [];
  bool _loading = true;
  String _error = '';

  // Withdrawal form
  final _amountController = TextEditingController();
  final _methodController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _methodController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final results = await Future.wait([
        ApiService.instance.get('/wallet'),
        ApiService.instance.get('/wallet/transactions', query: {'per_page': '20'}),
      ]);
      if (mounted) {
        setState(() {
          _balance = results[0] as Map<String, dynamic>;
          final txData = results[1] as Map<String, dynamic>;
          _transactions = txData['data'] ?? [];
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load wallet data.'; _loading = false; });
    }
  }

  Future<void> _requestWithdrawal(BuildContext context) async {
    final amount = double.tryParse(_amountController.text.trim());
    final method = _methodController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter a valid amount.'.tr)));
      return;
    }
    if (method.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter a payment method.'.tr)));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.instance.post('/wallet/withdraw', body: {
        'amount': amount,
        'payment_method': method,
        'payout_details': {'method': method},
      });
      _amountController.clear();
      _methodController.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Withdrawal request submitted!'.tr), backgroundColor: Colors.green),
        );
      }
      await _loadData();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request failed.'.tr), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomHeader(),
                          const SizedBox(height: 24),
                          _buildBalanceCard(),
                          const SizedBox(height: 24),
                          _buildWithdrawalForm(context, theme),
                          const SizedBox(height: 32),
                          _buildTransactionsSection(theme),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final available = _balance?['available'] ?? 0;
    final earned = _balance?['earned'] ?? 0;
    final pending = _balance?['pending_withdrawals'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available balance'.tr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 8),
          Text(
            'DZD ${available.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Earned'.tr, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
                    Text('DZD $earned', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pending'.tr, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
                    Text('DZD $pending', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalForm(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request Withdrawal'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (DZD)'.tr,
              prefixIcon: const Icon(Icons.monetization_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _methodController,
            decoration: InputDecoration(
              labelText: 'Payment Method (e.g. BaridiMob, CCP)'.tr,
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : () => _requestWithdrawal(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Submit Request'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transaction History'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('No transactions yet.'.tr, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ))
        else
          ..._transactions.map((tx) => _buildTransactionCard(theme, tx)),
      ],
    );
  }

  Widget _buildTransactionCard(ThemeData theme, Map<String, dynamic> tx) {
    final type = tx['type'] as String? ?? 'commission';
    final status = tx['status'] as String? ?? 'pending';
    final amount = tx['amount'] ?? 0;
    final isCommission = type == 'commission';
    final statusColor = status == 'approved'
        ? theme.colorScheme.tertiary
        : status == 'rejected'
            ? const Color(0xFFBA1A1A)
            : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCommission ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4) : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCommission ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
              color: isCommission ? theme.colorScheme.tertiary : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isCommission ? 'Commission'.tr : 'Withdrawal'.tr, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                Text(
                  tx['created_at'] != null ? DateTime.parse(tx['created_at']).toLocal().toString().split(' ').first : '',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCommission ? '+' : '-'}DZD $amount',
                style: TextStyle(fontWeight: FontWeight.bold, color: isCommission ? theme.colorScheme.tertiary : const Color(0xFFBA1A1A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
