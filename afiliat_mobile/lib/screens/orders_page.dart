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

    return Container(
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
    );
  }
}
