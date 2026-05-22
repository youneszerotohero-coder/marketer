import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../l10n/app_translations.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(),
              const SizedBox(height: 24),
              _buildBalanceCard(),
              const SizedBox(height: 24),
              _buildWithdrawalForm(theme),
              const SizedBox(height: 32),
              _buildTransactionsSection(theme),
              const SizedBox(height: 80), // Padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316), // Orange
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage('https://cdn-icons-png.flaticon.com/512/855/855281.png'),
          alignment: Alignment.centerRight,
          opacity: 0.1,
          scale: 3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance'.tr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '\$12,450.80',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '+12% this week'.tr,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request withdrawal'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 20),
          Text('Amount to withdraw'.tr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: '\$ 0.00',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 20),
          Text('Payment method'.tr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance, color: theme.colorScheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text('Bank\ntransfer'.tr, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold, height: 1.1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on, color: theme.colorScheme.onSurfaceVariant, size: 16),
                      const SizedBox(width: 8),
                      Text('Flexi'.tr, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Account details'.tr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'IBAN or Account Number'.tr,
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Request withdrawal'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Transactions'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            Text('View All'.tr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
          ],
        ),
        const SizedBox(height: 16),
        _buildTransactionItem(
          theme: theme,
          icon: Icons.trending_up,
          iconBgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          iconColor: theme.colorScheme.tertiary,
          title: 'Sales Income'.tr,
          date: 'Oct 24, 2023 • 02:30 PM',
          amount: '+\$840.00',
          amountColor: theme.colorScheme.tertiary,
          status: 'COMPLETED'.tr,
          statusBgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          statusTextColor: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 12),
        _buildTransactionItem(
          theme: theme,
          icon: Icons.local_shipping_outlined,
          iconBgColor: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          iconColor: theme.colorScheme.error,
          title: 'Shipping Fees'.tr,
          date: 'Oct 23, 2023 • 11:15 AM',
          amount: '-\$24.50',
          amountColor: theme.colorScheme.error,
          status: 'DEDUCTED'.tr,
          statusBgColor: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          statusTextColor: theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        _buildTransactionItem(
          theme: theme,
          icon: Icons.account_balance_wallet_outlined,
          iconBgColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          iconColor: theme.colorScheme.primary,
          title: 'Bank Withdrawal'.tr,
          date: 'Oct 21, 2023 • 09:00 AM',
          amount: '-\$2,000.00',
          amountColor: theme.colorScheme.onSurface,
          status: 'PENDING'.tr,
          statusBgColor: theme.colorScheme.surfaceContainerHighest,
          statusTextColor: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        _buildTransactionItem(
          theme: theme,
          icon: Icons.card_giftcard,
          iconBgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          iconColor: theme.colorScheme.tertiary,
          title: 'Performance Bonus'.tr,
          date: 'Oct 20, 2023 • 05:45 PM',
          amount: '+\$150.00',
          amountColor: theme.colorScheme.tertiary,
          status: 'REWARD'.tr,
          statusBgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          statusTextColor: theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required ThemeData theme,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String date,
    required String amount,
    required Color amountColor,
    required String status,
    required Color statusBgColor,
    required Color statusTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: amountColor)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusTextColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
