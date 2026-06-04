import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';

class OrderCreationForm extends StatefulWidget {
  final List<CartItemModel> cartItems;
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

  String? selectedWilaya = '16 - Alger';
  String? selectedCommune = 'Hydra';
  bool _isLoading = false;

  List<Map<String, dynamic>> _territories = [];
  List<String> wilayas = ['16 - Alger', '09 - Blida', '31 - Oran'];
  List<String> communes = ['Hydra', 'El Biar', 'Bab Ezzouar'];
  String _deliveryType = 'home';

  late List<CartItemModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cartItems);
    _loadTerritories();
  }

  Future<void> _loadTerritories() async {
    try {
      final data = await ApiService.instance.get('/delivery/territories');
      final territories = List<Map<String, dynamic>>.from(
        (data['data'] ?? data).map((item) => Map<String, dynamic>.from(item)),
      );
      if (territories.isEmpty || !mounted) return;

      setState(() {
        _territories = territories;
        wilayas = territories.map(_territoryLabel).toList();
        selectedWilaya = wilayas.first;
        communes = _communesFor(selectedWilaya);
        selectedCommune = communes.isNotEmpty ? communes.first : null;
      });
    } catch (_) {
      // Keep the local fallback values when ZR Express territories are unavailable.
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

  double get subtotal =>
      _items.fold(0, (total, item) => total + (item.price * item.quantity));
  double get totalCommission => _items.fold(
    0,
    (total, item) => total + (item.commission * item.quantity),
  );
  double get total => subtotal + widget.shippingCost;

  Future<void> _submitOrder() async {
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
          'shipping_fee': widget.shippingCost,
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
                    color: Colors.green.withValues(alpha: 0.1),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    _buildClientInformationCard(theme),
                    const SizedBox(height: 16),
                    _buildOrderSummaryCard(theme),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(
                            0xFFF97316,
                          ).withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Confirm Order'.tr,
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

  Widget _buildClientInformationCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
            color: Colors.black.withValues(alpha: 0.03),
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
            'DZD ${widget.shippingCost.toStringAsFixed(0)}',
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
              color: const Color(0xFFF97316).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF97316).withValues(alpha: 0.2),
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
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
      initialValue: value,
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
                  final stock = int.tryParse(v['stock'].toString()) ?? 0;
                  final isAvailable = stock > 0 && v['status'] == 'active';

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
                              quantity: item.quantity > stock
                                  ? stock
                                  : item.quantity,
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
                              ).colorScheme.primary.withValues(alpha: 0.1)
                            : (isAvailable
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest
                                  : Colors.grey.withValues(alpha: 0.1)),
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
