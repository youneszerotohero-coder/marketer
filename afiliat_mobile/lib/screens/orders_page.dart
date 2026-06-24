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
    'Retour Facturé'.tr,
    'Retour Exonéré'.tr,
    'Cancelled'.tr,
  ];

  final List<String?> _statusKeys = [
    null,
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'retour_facture',
    'retour_exonere',
    'cancelled',
  ];

  String _searchQuery = '';
  Timer? _debounce;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _loadOrders(refresh: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && !_isLoadingMore && _hasMore) {
        _loadOrders(loadNextPage: true);
      }
    }
  }

  List<dynamic> _orders = [];
  bool _loading = true;
  String _error = '';

  List<Map<String, dynamic>> _territories = [];
  List<Map<String, dynamic>> _allRates = [];
  List<String> wilayas = ['16 - Alger', '09 - Blida', '31 - Oran'];
  List<String> communes = ['Hydra', 'El Biar', 'Bab Ezzouar'];

  @override
  void initState() {
    super.initState();
    _loadOrders(refresh: true);
    _loadTerritories();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadTerritories() async {
    try {
      final data = await ApiService.instance.get('/delivery/territories');
      final territories = List<Map<String, dynamic>>.from(
        (data['data'] ?? data).map((item) => Map<String, dynamic>.from(item)),
      );
      
      final ratesData = await ApiService.instance.get('/delivery/rates');
      final rates = List<Map<String, dynamic>>.from(
        (ratesData['data'] ?? ratesData).map((item) => Map<String, dynamic>.from(item)),
      );

      if (territories.isEmpty || !mounted) return;

      setState(() {
        _territories = territories;
        wilayas = territories.map(_territoryLabel).toList();
        _allRates = rates;
      });
    } catch (_) {
    }
  }

  String _territoryLabel(Map<String, dynamic> territory) {
    final code = (territory['code'] ?? '').toString();
    final name = (territory['name'] ?? '').toString();
    return code.isNotEmpty ? '$code - $name' : name;
  }

  List<String> _communesFor(String? wilaya) {
    final territory = _territories.cast<Map<String, dynamic>?>().firstWhere(
      (item) => _territoryLabel(item ?? {}) == wilaya,
      orElse: () => null,
    );
    final values = territory?['communes'];
    if (values is List && values.isNotEmpty) {
      return values
          .map((item) {
            if (item is Map) {
              return (item['name'] ?? item['label'] ?? item['commune'] ?? '')
                  .toString();
            }
            return item.toString();
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return communes;
  }

  Future<void> _loadOrders({bool refresh = false, bool loadNextPage = false}) async {
    if (loadNextPage) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _orders = [];
        _loading = true;
        _error = '';
      });
    }
    try {
      final params = <String, dynamic>{
        'page': _currentPage.toString(),
        'per_page': '15',
      };
      final statusKey = _statusKeys[_selectedFilterIndex];
      if (statusKey != null) params['status'] = statusKey;
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;
      final data = await ApiService.instance.get('/orders', query: params);
      if (mounted) {
        final newOrders = data['data'] as List? ?? [];
        final lastPage = data['last_page'] ?? 1;

        setState(() {
          if (_currentPage == 1) {
            _orders = newOrders;
          } else {
            _orders.addAll(newOrders);
          }
          _hasMore = _currentPage < lastPage;
          if (_hasMore) {
            _currentPage++;
          }
          _loading = false;
          _isLoadingMore = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load orders.';
          _loading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Order'.tr),
        content: Text('Are you sure you want to cancel this order?'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No'.tr),
          ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order cancelled successfully'.tr)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cancelling order'.tr)));
      }
    }
  }

  void _selectFilter(int index) {
    setState(() => _selectedFilterIndex = index);
    _loadOrders(refresh: true);
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
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
                  ? Center(
                      child: Text(
                        _error.tr,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _orders.isEmpty
                  ? Center(
                      child: Text(
                        'No orders found.'.tr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _orders.length,
                          itemBuilder: (context, i) =>
                              _buildOrderCard(theme, _orders[i]),
                        ),
                        if (_isLoadingMore)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Loading more...'.tr, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
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
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
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
      'pending': [
        theme.colorScheme.primaryContainer,
        theme.colorScheme.primary,
      ],
      'confirmed': [const Color(0xFFDCFCE7), const Color(0xFF16A34A)],
      'shipped': [const Color(0xFFEDE9FE), const Color(0xFF7C3AED)],
      'delivered': [
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.tertiary,
      ],
      'failed': [const Color(0xFFFFE4E4), const Color(0xFFBA1A1A)],
      'retour_facture': [const Color(0xFFFFE4E4), const Color(0xFFBA1A1A)],
      'retour_exonere': [const Color(0xFFFEF3C7), const Color(0xFFD97706)],
      'cancelled': [
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ],
    };
    final colors = statusColors[status] ?? statusColors['pending']!;
    final items = order['items'] as List? ?? [];
    final commission = order['marketer_commission'];
    final total = order['total'];

    final returnFeeTx = order['return_fee_transaction'];
    final returnFee = returnFeeTx != null ? returnFeeTx['amount'] : null;

    return InkWell(
      onTap: () => _openOrderDetails(order),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors[0],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.tr,
                    style: TextStyle(
                      color: colors[1],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['client_name'] ?? '—',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        items.isNotEmpty
                            ? '${items.length} item(s)'
                            : 'No items',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (status == 'retour_facture')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-DZD ${returnFee ?? 400}',
                      style: const TextStyle(
                        color: Color(0xFFBA1A1A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (status == 'retour_exonere')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Exonéré ✓',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (status != 'cancelled' &&
                    status != 'failed' &&
                    commission != null &&
                    double.tryParse(commission.toString())! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+DZD $commission',
                      style: TextStyle(
                        color: theme.colorScheme.tertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order['created_at'] != null
                  ? DateTime.tryParse(
                          order['created_at'],
                        )?.toLocal().toString().split(' ').first ??
                        ''
                  : '',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _cancelOrder(order['id']),
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: Text(
                      'Cancel Order'.tr,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openOrderDetails(Map<String, dynamic> order) async {
    var latestOrder = order;
    if (order['tracking_number'] != null) {
      try {
        final data = await ApiService.instance.post(
          '/orders/${order['id']}/delivery-status',
        );
        latestOrder = Map<String, dynamic>.from(data['order'] ?? data);
        if (mounted) {
          setState(() {
            _orders = _orders
                .map(
                  (item) =>
                      item['id'] == latestOrder['id'] ? latestOrder : item,
                )
                .toList();
          });
        }
      } catch (_) {
        latestOrder = order;
      }
    }

    if (mounted) _showOrderDetails(latestOrder);
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final status = order['status'] as String? ?? 'pending';
    final items = order['items'] as List? ?? [];

    final statusColors = {
      'pending': [
        theme.colorScheme.primaryContainer,
        theme.colorScheme.primary,
      ],
      'confirmed': [const Color(0xFFDCFCE7), const Color(0xFF16A34A)],
      'shipped': [const Color(0xFFEDE9FE), const Color(0xFF7C3AED)],
      'delivered': [
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.tertiary,
      ],
      'failed': [const Color(0xFFFFE4E4), const Color(0xFFBA1A1A)],
      'retour_facture': [const Color(0xFFFFE4E4), const Color(0xFFBA1A1A)],
      'retour_exonere': [const Color(0xFFFEF3C7), const Color(0xFFD97706)],
      'cancelled': [
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ],
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors[0],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase().tr,
                      style: TextStyle(
                        color: colors[1],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order['reference'] ?? '#${order['id']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Customer Info & Localization (Shipping Address Details)
              _buildDetailSectionTitle(
                'Address & Delivery'.tr,
                Icons.location_on_outlined,
                theme,
              ),
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
                  value: (order['delivery_type'] == 'home'
                      ? 'Home Delivery'.tr
                      : 'Desk Delivery'.tr),
                  icon: Icons.local_shipping_outlined,
                  theme: theme,
                ),
              ]),
              const SizedBox(height: 24),

              // 2. Items Ordered
              _buildDetailSectionTitle(
                'Items Ordered'.tr,
                Icons.shopping_bag_outlined,
                theme,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color:
                      theme.cardTheme.color ??
                      theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(
                        item['product_name'] ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'SKU: ${item['sku'] ?? '—'}  x${item['quantity'] ?? 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      trailing: Text(
                        'DZD ${item['line_total'] ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. Payment Summary
              _buildDetailSectionTitle(
                'Payment Summary'.tr,
                Icons.monetization_on_outlined,
                theme,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(theme, [
                _buildSummaryRow(
                  'Subtotal'.tr,
                  'DZD ${order['subtotal'] ?? 0}',
                  theme,
                ),
                _buildSummaryRow(
                  'Shipping Fee'.tr,
                  'DZD ${order['shipping_fee'] ?? 0}',
                  theme,
                ),
                const Divider(),
                _buildSummaryRow(
                  'Total'.tr,
                  'DZD ${order['total'] ?? 0}',
                  theme,
                  isBold: true,
                  valueColor: primaryColor,
                ),
                _buildSummaryRow(
                  (status == 'delivered'
                          ? 'Profit Earned'
                          : (status == 'retour_facture' ||
                                  status == 'retour_exonere' ||
                                  status == 'cancelled' ||
                                  status == 'failed')
                              ? 'Profit'
                              : 'Expected Profit')
                      .tr,
                  'DZD ${(status == 'retour_facture' || status == 'retour_exonere' || status == 'cancelled' || status == 'failed') ? 0 : (order['marketer_commission'] ?? 0)}',
                  theme,
                  isBold: true,
                  valueColor: theme.colorScheme.tertiary,
                ),
                if (status == 'retour_facture') ...[
                  const Divider(),
                  _buildSummaryRow(
                    'Frais de retour'.tr,
                    '-DZD ${order['return_fee_transaction']?['amount'] ?? 400}',
                    theme,
                    isBold: true,
                    valueColor: const Color(0xFFBA1A1A),
                  ),
                ],
                if (status == 'retour_exonere') ...[
                  const Divider(),
                  _buildSummaryRow(
                    'Frais de retour'.tr,
                    'Exonéré ✓',
                    theme,
                    isBold: true,
                    valueColor: const Color(0xFF065F46),
                  ),
                ],
              ]),

              // 4. Tracking & Notes
              if (order['tracking_number'] != null ||
                  order['delivery_status'] != null ||
                  order['delivery_current_location'] != null ||
                  order['notes'] != null) ...[
                const SizedBox(height: 24),
                _buildDetailSectionTitle(
                  'ZR Express Tracking'.tr,
                  Icons.info_outline,
                  theme,
                ),
                const SizedBox(height: 12),
                _buildDetailCard(theme, [
                  if (order['tracking_number'] != null)
                    _buildDetailRow(
                      label: 'Tracking Number'.tr,
                      value: order['tracking_number'],
                      icon: Icons.qr_code_scanner,
                      theme: theme,
                    ),
                  if (order['delivery_status'] != null)
                    _buildDetailRow(
                      label: 'Current Status'.tr,
                      value: order['delivery_status'],
                      icon: Icons.local_shipping_outlined,
                      theme: theme,
                    ),
                  if (order['delivery_current_location'] != null)
                    _buildDetailRow(
                      label: 'Current Location'.tr,
                      value: order['delivery_current_location'],
                      icon: Icons.location_on_outlined,
                      theme: theme,
                    ),
                  if (order['delivery_last_synced_at'] != null)
                    _buildDetailRow(
                      label: 'Last Sync'.tr,
                      value:
                          DateTime.tryParse(
                            order['delivery_last_synced_at'],
                          )?.toLocal().toString() ??
                          order['delivery_last_synced_at'],
                      icon: Icons.sync,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Close'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditOrderSheet(order);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Edit Order'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel Order'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildDetailSectionTitle(
    String title,
    IconData icon,
    ThemeData theme,
  ) {
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
        color:
            theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
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
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    Color? valueColor,
  }) {
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
              color: isBold
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
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

  double _getShippingCost(String? wilayaLabel, String deliveryType) {
    if (wilayaLabel == null || _allRates.isEmpty) return 0.0;
    
    String wilayaName = wilayaLabel;
    String? wilayaCode;
    if (wilayaLabel.contains(' - ')) {
      final parts = wilayaLabel.split(' - ');
      wilayaCode = parts[0].trim();
      wilayaName = parts[1].trim();
    }
    
    final rate = _allRates.firstWhere(
      (r) => (wilayaCode != null && r['wilaya_code']?.toString() == wilayaCode) ||
             r['wilaya_name']?.toString().toLowerCase() == wilayaName.toLowerCase(),
      orElse: () => {},
    );
    
    if (rate.isEmpty) return 0.0;
    
    if (deliveryType == 'home') {
      return (rate['home'] ?? rate['home_price'] ?? 0).toDouble();
    } else {
      return (rate['desk'] ?? rate['desk_price'] ?? 0).toDouble();
    }
  }

  void _showEditOrderSheet(Map<String, dynamic> order) {
    final clientNameController = TextEditingController(text: order['client_name']);
    final clientPhoneController = TextEditingController(text: order['client_phone']);
    final addressController = TextEditingController(text: order['address']);
    final notesController = TextEditingController(text: order['notes']);
    String selectedWilaya = order['wilaya'] ?? wilayas.first;
    String deliveryType = order['delivery_type'] ?? 'home';

    // ensure wilaya is in list
    if (!wilayas.contains(selectedWilaya)) {
      selectedWilaya = wilayas.first;
    }
    List<String> currentCommunes = _communesFor(selectedWilaya);
    String? selectedCommune = order['commune'];
    if (!currentCommunes.contains(selectedCommune)) {
      selectedCommune = currentCommunes.isNotEmpty ? currentCommunes.first : null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool isSubmitting = false;

            Future<void> updateOrder() async {
              setSheetState(() => isSubmitting = true);
              try {
                await ApiService.instance.put('/orders/${order['id']}', body: {
                  'client_name': clientNameController.text.trim(),
                  'client_phone': clientPhoneController.text.trim(),
                  'wilaya': selectedWilaya,
                  'commune': selectedCommune,
                  'address': addressController.text.trim(),
                  'delivery_type': deliveryType,
                  'notes': notesController.text.trim(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadOrders();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order updated successfully!'.tr)),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating order'.tr)),
                );
              } finally {
                if (context.mounted) {
                  setSheetState(() => isSubmitting = false);
                }
              }
            }

            final currentShippingFee = _getShippingCost(selectedWilaya, deliveryType);
            final subtotal = double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
            final total = subtotal + currentShippingFee;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Order'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: clientNameController, 
                      decoration: InputDecoration(
                        labelText: 'Customer Name'.tr,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      )
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          ),
                          child: Text('+213', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: clientPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number'.tr,
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedWilaya,
                      isExpanded: true,
                      items: wilayas.map((w) => DropdownMenuItem(value: w, child: Text(w, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            selectedWilaya = val;
                            currentCommunes = _communesFor(val);
                            selectedCommune = currentCommunes.isNotEmpty ? currentCommunes.first : null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Wilaya'.tr,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCommune,
                      isExpanded: true,
                      items: currentCommunes.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setSheetState(() => selectedCommune = val),
                      decoration: InputDecoration(
                        labelText: 'Commune'.tr,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Address'.tr,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes'.tr,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Text('Delivery Type'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: deliveryType,
                      onChanged: (val) => setSheetState(() => deliveryType = val!),
                      child: Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: RadioListTile<String>(
                                title: Text('A Domicile'.tr, style: const TextStyle(fontSize: 14)),
                                value: 'home',
                                contentPadding: EdgeInsets.zero,
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: RadioListTile<String>(
                                title: Text('Stop Desk'.tr, style: const TextStyle(fontSize: 14)),
                                value: 'desk',
                                contentPadding: EdgeInsets.zero,
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Order Summary'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal'.tr, style: const TextStyle(fontSize: 13)),
                              Text('DZD $subtotal', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Shipping Fee'.tr, style: const TextStyle(fontSize: 13)),
                              Text('DZD $currentShippingFee', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('DZD $total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : updateOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Update Order'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
