import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  int _selectedFilterIndex = 0;
  List<String> get _filters => [
        'All'.tr,
        'Pending'.tr,
        'Confirmed'.tr,
        'Shipped'.tr,
        'Delivered'.tr,
        'Failed'.tr,
        'Cancelled'.tr,
      ];

  final List<String?> _statusKeys = [null, 'pending', 'confirmed', 'shipped', 'delivered', 'failed', 'cancelled'];

  String _searchQuery = '';
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  List<dynamic> _orders = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final params = <String, dynamic>{'per_page': '50'};
      final statusKey = _statusKeys[_selectedFilterIndex];
      if (statusKey != null) params['status'] = statusKey;
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;
      final data = await ApiService.instance.get('/orders', query: params);
      if (mounted) {
        setState(() {
          _orders = data['data'] ?? data;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load orders.'; _loading = false; });
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Order'.tr),
        content: Text('Are you sure you want to cancel this order?'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No'.tr)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.instance.post('/orders/$orderId/cancel');
      _loadOrders();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order cancelled successfully'.tr)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cancelling order'.tr)));
    }
  }

  void _selectFilter(int index) {
    setState(() => _selectedFilterIndex = index);
    _loadOrders();
  }

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search orders...'.tr,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            _buildFilters(theme),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                      : _orders.isEmpty
                          ? Center(child: Text('No orders found.'.tr, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: _orders.length,
                              itemBuilder: (context, i) => _buildOrderCard(theme, _orders[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () => _selectFilter(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(ThemeData theme, Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final statusColors = {
      'pending': [theme.colorScheme.primaryContainer, theme.colorScheme.primary],
      'confirmed': [const Color(0xFFDCFCE7), const Color(0xFF16A34A)],
      'shipped': [const Color(0xFFEDE9FE), const Color(0xFF7C3AED)],
      'delivered': [theme.colorScheme.tertiaryContainer, theme.colorScheme.tertiary],
      'failed': [const Color(0xFFFFE4E4), const Color(0xFFBA1A1A)],
      'cancelled': [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant],
    };
    final colors = statusColors[status] ?? statusColors['pending']!;
    final items = order['items'] as List? ?? [];
    final commission = order['marketer_commission'];
    final total = order['total'];
    
    final returnFeeTx = order['return_fee_transaction'];
    final returnFee = returnFeeTx != null ? returnFeeTx['amount'] : null;

    return InkWell(
      onTap: () => _showOrderDetails(order),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['reference'] ?? '#${order['id']}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: colors[0], borderRadius: BorderRadius.circular(12)),
                child: Text(status, style: TextStyle(color: colors[1], fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.shopping_bag_outlined, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['client_name'] ?? '—',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      items.isNotEmpty ? '${items.length} item(s)' : 'No items',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DZD ${total ?? 0}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              if (status == 'failed')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-DZD ${returnFee ?? 400}',
                    style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              else if (commission != null && double.tryParse(commission.toString())! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+DZD $commission',
                    style: TextStyle(color: theme.colorScheme.tertiary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order['created_at'] != null
                ? DateTime.tryParse(order['created_at'])?.toLocal().toString().split(' ').first ?? ''
                : '',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _cancelOrder(order['id']),
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                  label: Text('Cancel Order'.tr, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final status = order['status'] as String? ?? 'pending';
    final items = order['items'] as List? ?? [];

    final statusColors = {
      'pending': [theme.colorScheme.primaryContainer, theme.colorScheme.primary],
      'confirmed': [const Color(0xFFDCFCE7), const Color(0xFF16A34A)],
      'shipped': [const Color(0xFFEDE9FE), const Color(0xFF7C3AED)],
      'delivered': [theme.colorScheme.tertiaryContainer, theme.colorScheme.tertiary],
      'failed': [const Color(0xFFFFE4E4), const Color(0xFFBA1A1A)],
      'cancelled': [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant],
    };
    final colors = statusColors[status] ?? statusColors['pending']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Details'.tr,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: colors[0], borderRadius: BorderRadius.circular(12)),
                    child: Text(status.toUpperCase().tr, style: TextStyle(color: colors[1], fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order['reference'] ?? '#${order['id']}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              
              // 1. Customer Info & Localization (Shipping Address Details)
              _buildDetailSectionTitle('Address & Delivery'.tr, Icons.location_on_outlined, theme),
              const SizedBox(height: 12),
              _buildDetailCard(theme, [
                _buildDetailRow(
                  label: 'Customer Name'.tr,
                  value: order['client_name'] ?? '—',
                  icon: Icons.person_outline,
                  theme: theme,
                ),
                _buildDetailRow(
                  label: 'Phone Number'.tr,
                  value: order['client_phone'] ?? '—',
                  icon: Icons.phone_outlined,
                  theme: theme,
                ),
                _buildDetailRow(
                  label: 'Wilaya'.tr,
                  value: order['wilaya'] ?? '—',
                  icon: Icons.map_outlined,
                  theme: theme,
                ),
                _buildDetailRow(
                  label: 'Commune'.tr,
                  value: order['commune'] ?? '—',
                  icon: Icons.location_city_outlined,
                  theme: theme,
                ),
                _buildDetailRow(
                  label: 'Address'.tr,
                  value: order['address'] ?? '—',
                  icon: Icons.home_outlined,
                  theme: theme,
                ),
                _buildDetailRow(
                  label: 'Delivery Type'.tr,
                  value: (order['delivery_type'] == 'home' ? 'Home Delivery'.tr : 'Desk Delivery'.tr),
                  icon: Icons.local_shipping_outlined,
                  theme: theme,
                ),
              ]),
              const SizedBox(height: 24),

              // 2. Items Ordered
              _buildDetailSectionTitle('Items Ordered'.tr, Icons.shopping_bag_outlined, theme),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(item['product_name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('SKU: ${item['sku'] ?? '—'}  x${item['quantity'] ?? 1}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      ),
                      trailing: Text('DZD ${item['line_total'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. Payment Summary
              _buildDetailSectionTitle('Payment Summary'.tr, Icons.monetization_on_outlined, theme),
              const SizedBox(height: 12),
              _buildDetailCard(theme, [
                _buildSummaryRow('Subtotal'.tr, 'DZD ${order['subtotal'] ?? 0}', theme),
                _buildSummaryRow('Shipping Fee'.tr, 'DZD ${order['shipping_fee'] ?? 0}', theme),
                const Divider(),
                _buildSummaryRow('Total'.tr, 'DZD ${order['total'] ?? 0}', theme, isBold: true, valueColor: primaryColor),
                _buildSummaryRow('Expected Profit'.tr, 'DZD ${order['marketer_commission'] ?? 0}', theme, isBold: true, valueColor: theme.colorScheme.tertiary),
              ]),

              // 4. Tracking & Notes
              if (order['tracking_number'] != null || order['notes'] != null) ...[
                const SizedBox(height: 24),
                _buildDetailSectionTitle('Other Info'.tr, Icons.info_outline, theme),
                const SizedBox(height: 12),
                _buildDetailCard(theme, [
                  if (order['tracking_number'] != null)
                    _buildDetailRow(
                      label: 'Tracking Number'.tr,
                      value: order['tracking_number'],
                      icon: Icons.qr_code_scanner,
                      theme: theme,
                    ),
                  if (order['notes'] != null)
                    _buildDetailRow(
                      label: 'Notes'.tr,
                      value: order['notes'],
                      icon: Icons.notes,
                      theme: theme,
                    ),
                ]),
              ],

              // 5. Actions
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Close'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (status == 'pending') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _cancelOrder(order['id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Cancel Order'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(ThemeData theme, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
