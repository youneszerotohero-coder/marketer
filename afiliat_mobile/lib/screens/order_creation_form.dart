import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';

class OrderCreationForm extends StatefulWidget {
  final List<CartItemModel> cartItems;
  // shippingCost kept for backward compatibility but ignored — we compute it dynamically
  final double shippingCost;

  const OrderCreationForm({
    super.key,
    required this.cartItems,
    required this.shippingCost,
  });

  @override
  State<OrderCreationForm> createState() => _OrderCreationFormState();
}

class _OrderCreationFormState extends State<OrderCreationForm> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? selectedWilaya;
  String? selectedCommune;
  bool _isLoading = false;
  bool _isLoadingTerritories = true;

  // Territories from /delivery/territories (active wilayas with communes)
  List<Map<String, dynamic>> _territories = [];
  // Rates from /delivery/rates (all wilayas with prices + active flags)
  List<Map<String, dynamic>> _allRates = [];

  List<String> wilayas = [];
  List<String> communes = [];
  String _deliveryType = 'home';

  late List<CartItemModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cartItems);
    _loadData();
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.instance.get('/delivery/territories'),
        ApiService.instance.get('/delivery/rates'),
      ]);

      final territories = List<Map<String, dynamic>>.from(
        (results[0]['data'] ?? results[0]).map((item) => Map<String, dynamic>.from(item)),
      );
      final rates = List<Map<String, dynamic>>.from(
        (results[1]['data'] ?? results[1]).map((item) => Map<String, dynamic>.from(item)),
      );

      if (!mounted) return;

      setState(() {
        _territories = territories;
        _allRates = rates;
        wilayas = territories.map(_territoryLabel).toList();
        if (wilayas.isNotEmpty) {
          selectedWilaya = wilayas.first;
          communes = _communesFor(selectedWilaya);
          selectedCommune = communes.isNotEmpty ? communes.first : null;
        }
        _isLoadingTerritories = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTerritories = false);
      }
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

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
              return (item['name'] ?? item['label'] ?? item['commune'] ?? '').toString();
            }
            return item.toString();
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [];
  }

  /// Get the rate record for the currently selected wilaya
  Map<String, dynamic>? get _selectedRate {
    if (selectedWilaya == null || _allRates.isEmpty) return null;
    final code = selectedWilaya!.split(' - ').first.trim();
    try {
      return _allRates.firstWhere(
        (r) => r['code'].toString() == code || r['wilaya_code'].toString() == code,
      );
    } catch (_) {
      return null;
    }
  }

  bool get _wilayaActive => _selectedRate?['is_active'] as bool? ?? true;
  bool get _homeActive => _selectedRate?['home_active'] as bool? ?? true;
  bool get _deskActive => _selectedRate?['desk_active'] as bool? ?? true;

  double get _computedShippingCost {
    final rate = _selectedRate;
    if (rate == null) return 0;
    if (_deliveryType == 'home') {
      return (rate['home'] ?? rate['home_price'] ?? 0).toDouble();
    } else {
      return (rate['desk'] ?? rate['desk_price'] ?? 0).toDouble();
    }
  }

  bool get _canSubmit {
    if (!_wilayaActive) return false;
    if (_deliveryType == 'home' && !_homeActive) return false;
    if (_deliveryType == 'desk' && !_deskActive) return false;
    return true;
  }

  // ─── Computed totals (use dynamic shipping) ────────────────────────────────

  double get subtotal =>
      _items.fold(0, (total, item) => total + (item.price * item.quantity));
  double get totalCommission => _items.fold(
    0,
    (total, item) => total + (item.commission * item.quantity),
  );
  double get total => subtotal + _computedShippingCost + totalCommission;


  Future<void> _submitOrder() async {
    if (!_canSubmit) {
      String msg;
      if (!_wilayaActive) {
        msg = 'Delivery to this wilaya is currently unavailable.'.tr;
      } else if (_deliveryType == 'home' && !_homeActive) {
        msg = 'Home delivery is not available for this wilaya.'.tr;
      } else {
        msg = 'Desk delivery is not available for this wilaya.'.tr;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields.'.tr)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final items = _items
          .map(
            (item) => {
              'product_variant_id': item.id,
              'quantity': item.quantity,
              'price': item.price,
            },
          )
          .toList();

      await ApiService.instance.post(
        '/orders',
        body: {
          'client_name': _nameController.text.trim(),
          'client_phone': _phoneController.text.trim(),
          'wilaya': selectedWilaya,
          'commune': selectedCommune,
          'delivery_type': _deliveryType,
          'items': items,
          'status': 'pending',
          'shipping_fee': _computedShippingCost,
        },
      );

      _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'Failed to submit order'.tr}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surfaceContainerLowest,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // To make the card compact
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 24.0),
                Text(
                  'Order Successful!'.tr,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Your order has been placed successfully. You can track its status in the orders page.'
                      .tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32.0),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Back to Home'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
              padding: EdgeInsets.all(16.0),
              child: CustomHeader(showBackButton: true),
            ),
            if (_isLoadingTerritories)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      // ⚠️ Blocking banners
                      if (!_wilayaActive) _buildBlockingBanner(
                        theme,
                        message: 'Delivery to this wilaya is currently unavailable.'.tr,
                      )
                      else if (_deliveryType == 'home' && !_homeActive) _buildBlockingBanner(
                        theme,
                        message: 'Home delivery is not available for this wilaya.'.tr,
                      )
                      else if (_deliveryType == 'desk' && !_deskActive) _buildBlockingBanner(
                        theme,
                        message: 'Desk delivery is not available for this wilaya.'.tr,
                      ),
                      if (!_wilayaActive || (_deliveryType == 'home' && !_homeActive) || (_deliveryType == 'desk' && !_deskActive))
                        const SizedBox(height: 12),
                      _buildClientInformationCard(theme),
                      const SizedBox(height: 16),
                      _buildOrderSummaryCard(theme),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_isLoading || !_canSubmit) ? null : _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canSubmit
                                ? const Color(0xFFF97316)
                                : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: _canSubmit ? 4 : 0,
                            shadowColor: const Color(0xFFF97316).withOpacity(0.4),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _canSubmit
                                      ? 'Confirm Order'.tr
                                      : 'Delivery Unavailable'.tr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockingBanner(ThemeData theme, {required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInformationCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: Color(0xFFF97316),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Client Information'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 20),

          _buildInputField(
            label: 'FULL NAME'.tr,
            child: _buildTextField(
              hint: 'e.g. Ahmed Benali'.tr,
              controller: _nameController,
            ),
          ),

          const SizedBox(height: 20),
          _buildInputField(
            label: 'PHONE NUMBER'.tr,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    '+213',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildTextField(
                    hint: '0550 00 00 00',
                    keyboardType: TextInputType.phone,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                    controller: _phoneController,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'WILAYA'.tr,
                  child: _buildDropdown(
                    value: selectedWilaya,
                    items: wilayas,
                    onChanged: (val) => setState(() {
                      selectedWilaya = val;
                      communes = _communesFor(val);
                      selectedCommune = communes.isNotEmpty
                          ? communes.first
                          : null;
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  label: 'COMMUNE'.tr,
                  child: _buildDropdown(
                    value: selectedCommune,
                    items: communes,
                    onChanged: (val) => setState(() => selectedCommune = val),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildInputField(
            label: 'DELIVERY TYPE'.tr,
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: RadioListTile<String>(
                      title: Text(
                        'A Domicile'.tr,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: 'home',
                      groupValue: _deliveryType,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) => setState(() => _deliveryType = val!),
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: RadioListTile<String>(
                      title: Text(
                        'Stop Desk'.tr,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: 'desk',
                      groupValue: _deliveryType,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) => setState(() => _deliveryType = val!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFFF97316),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Order Summary'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),

          // Product List
          ..._items.asMap().entries.map(
            (entry) => _buildProductItemRow(entry.value, entry.key),
          ),

          const SizedBox(height: 8),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),

          // Cost Breakdown
          _buildSummaryRow('Subtotal'.tr, 'DZD ${subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Shipping Fee'.tr,
            'DZD ${_computedShippingCost.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Commission'.tr,
            'DZD ${totalCommission.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'DZD ${total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Commission Earnings Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF97316).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFFF97316),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Your Commission'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
                Text(
                  '+ DZD ${totalCommission.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItemRow(CartItemModel item, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.availableVariants != null &&
                    item.availableVariants!.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showVariantSelector(context, index, item),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.variantSku.isNotEmpty
                                  ? 'Option: ${item.variantSku}'
                                  : 'Select Option'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'DZD ${item.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x${item.quantity}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              try {
                // Remove from CartService if exists
                final globalItems = CartService.instance.items;
                final globalIndex = globalItems.indexWhere(
                  (i) => i.id == item.id && i.variantSku == item.variantSku,
                );
                if (globalIndex != -1) {
                  CartService.instance.removeItem(globalIndex);
                }
              } catch (_) {}

              setState(() {
                _items.removeAt(index);
              });

              if (_items.isEmpty) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    BorderRadius? borderRadius,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,

      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _showVariantSelector(
    BuildContext context,
    int index,
    CartItemModel item,
  ) {
    if (item.availableVariants == null || item.availableVariants!.isEmpty)
      return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Option'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.availableVariants!.map((v) {
                  final isSelected = v['id'].toString() == item.id;
                  final isAvailable = v['status'] == 'active';

                  return InkWell(
                    onTap: isAvailable
                        ? () {
                            final updatedItem = CartItemModel(
                              id: v['id'].toString(),
                              brand: item.brand,
                              title: item.title,
                              variantSku: v['sku'] ?? '',
                              price:
                                  double.tryParse(v['sale_price'].toString()) ??
                                  item.price,
                              commission:
                                  double.tryParse(
                                    v['commission_value'].toString(),
                                  ) ??
                                  item.commission,
                              imageUrl: item.imageUrl,
                              quantity: item.quantity,
                              availableVariants: item.availableVariants,
                            );

                            try {
                              final globalItems = CartService.instance.items;
                              final globalIndex = globalItems.indexWhere(
                                (i) =>
                                    i.id == item.id &&
                                    i.variantSku == item.variantSku,
                              );
                              if (globalIndex != -1) {
                                CartService.instance.updateItem(
                                  globalIndex,
                                  updatedItem,
                                );
                              }
                            } catch (_) {}

                            setState(() {
                              _items[index] = updatedItem;
                            });

                            Navigator.pop(ctx);
                          }
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1)
                            : (isAvailable
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest
                                  : Colors.grey.withOpacity(0.1)),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        v['sku']?.toString() ?? 'Option',
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : (isAvailable
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.grey),
                          decoration: isAvailable
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
