import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../l10n/app_translations.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  int _selectedFilterIndex = 0;
  List<String> get _filters => ['All'.tr, 'Pending'.tr, 'Confirmed'.tr, 'Shipping Status'.tr, 'Delivered'.tr, 'Cancelled'.tr];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
              child: CustomHeader(),
            ),
            _buildFilters(theme),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildOrderCard(
                    theme: theme,
                    orderId: 'ORDER #MP-82931',
                    status: 'Delivered'.tr,
                    statusBgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    statusTextColor: theme.colorScheme.tertiary,
                    name: 'Amine Rahmani',
                    amount: '12,400 DZD',
                    profit: '+1,200 DZD',
                    profitColor: theme.colorScheme.tertiary,
                    profitBgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    date: 'Oct 24, 2023',
                    isActive: true,
                  ),
                  _buildOrderCard(
                    theme: theme,
                    orderId: 'ORDER #MP-82945',
                    status: 'Pending'.tr,
                    statusBgColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    statusTextColor: theme.colorScheme.primary,
                    name: 'Sarah Kaci',
                    amount: '8,200 DZD',
                    profit: '+850 DZD',
                    profitColor: theme.colorScheme.tertiary,
                    profitBgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    date: 'Oct 26, 2023',
                    isActive: true,
                  ),
                  _buildOrderCard(
                    theme: theme,
                    orderId: 'ORDER #MP-82912',
                    status: 'Confirmed'.tr,
                    statusBgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    statusTextColor: theme.colorScheme.tertiary,
                    name: 'Yacine B.',
                    amount: '15,000 DZD',
                    profit: '+2,100 DZD',
                    profitColor: theme.colorScheme.tertiary,
                    profitBgColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    date: 'Oct 22, 2023',
                    isActive: true,
                  ),
                  _buildOrderCard(
                    theme: theme,
                    orderId: 'ORDER #MP-82890',
                    status: 'Cancelled'.tr,
                    statusBgColor: theme.colorScheme.surfaceContainerHighest,
                    statusTextColor: theme.colorScheme.onSurfaceVariant,
                    name: 'Fatima Zohra',
                    amount: '5,500 DZD',
                    profit: '0 DZD',
                    profitColor: theme.colorScheme.onSurfaceVariant,
                    profitBgColor: theme.colorScheme.surfaceContainerHighest,
                    date: 'Oct 20, 2023',
                    isActive: false,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard({
    required ThemeData theme,
    required String orderId,
    required String status,
    required Color statusBgColor,
    required Color statusTextColor,
    required String name,
    required String amount,
    required String profit,
    required Color profitColor,
    required Color profitBgColor,
    required String date,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderId,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AMOUNT'.tr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: profitBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROFIT'.tr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profit,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: profitColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurface),
                  label: Text('Details'.tr, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.chat_bubble_outline, size: 16, color: theme.colorScheme.onPrimary),
                  label: Text('Contact client'.tr, style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
