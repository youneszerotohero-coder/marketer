import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class ProductDetails extends StatefulWidget {
  final int? productId;

  const ProductDetails({super.key, this.productId});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  int quantity = 1;
  int currentImageIndex = 0;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;

  String? selectedWilaya = '16 - Alger';
  String? selectedCommune = 'Hydra';

  List<Map<String, dynamic>> _territories = [];
  List<Map<String, dynamic>> _allRates = [];
  List<String> wilayas = ['16 - Alger', '09 - Blida', '31 - Oran'];
  List<String> communes = ['Hydra', 'El Biar', 'Bab Ezzouar'];
  String _deliveryType = 'home';

  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _product;
  Map<String, dynamic>? _defaultVariant;

  @override
  void initState() {
    super.initState();
    _loadTerritories();
    if (widget.productId != null) {
      _loadProductDetails();
    } else {
      _loading = false;
      _error = 'No product ID provided.';
    }
  }

  Future<void> _loadTerritories() async {
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
      if (territories.isEmpty || !mounted) return;

      setState(() {
        _territories = territories;
        _allRates = rates;
        wilayas = territories.map(_territoryLabel).toList();
        selectedWilaya = wilayas.first;
        communes = _communesFor(selectedWilaya);
        selectedCommune = communes.isNotEmpty ? communes.first : null;
      });
    } catch (_) {
      // Keep fallback wilayas when ZR Express is unavailable.
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

  Future<void> _loadProductDetails() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await ApiService.instance.get(
        '/products/${widget.productId}',
      );
      if (mounted) {
        setState(() {
          _product = data['data'] ?? data;
          final variants = _product!['variants'] as List? ?? [];
          if (variants.isNotEmpty) {
            _defaultVariant = variants.first;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  List<String> get sliderImages {
    final images = <String>[];
    if (_product != null) {
      if (_product!['main_image_path'] != null) {
        images.add(ApiService.getImageUrl(_product!['main_image_path']));
      }
      final extraImages = _product!['images'] as List?;
      if (extraImages != null) {
        for (final img in extraImages) {
          if (img['path'] != null) {
            images.add(ApiService.getImageUrl(img['path']));
          }
        }
      }
    }
    if (images.isNotEmpty) {
      return images.toSet().toList();
    }
    return [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=400&q=80',
    ];
  }

  Future<void> _submitOrder() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields.'.tr)),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final items = [
        {
          'product_variant_id': _defaultVariant?['id'] ?? widget.productId,
          'quantity': quantity,
          'price': _priceNum,
        },
      ];

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order placed successfully!'.tr)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'Failed to submit order'.tr}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _downloadImages() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading to gallery is not supported on Web. Please test on Android/iOS.'.tr)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        throw Exception('Gallery permission denied'.tr);
      }

      final dio = Dio();
      final dir = await getTemporaryDirectory();
      for (int i = 0; i < sliderImages.length; i++) {
        final url = sliderImages[i];
        final path = '${dir.path}/image_$i.jpg';
        await dio.download(url, path);
        await Gal.putImage(path);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All images saved to gallery!'.tr)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'Failed to download images'.tr}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _title => _product?['name'] ?? 'Loading...';
  String get _description =>
      _product?['description'] ?? 'No description available.';
  double get _priceNum => _defaultVariant != null
      ? double.parse(_defaultVariant!['sale_price'].toString())
      : 0.0;
  double get _commissionNum => _defaultVariant != null
      ? double.parse(_defaultVariant!['commission_value'].toString())
      : 0.0;
  int get _stock => 999999;

  String get _productTotalPrice {
    final total = _priceNum * quantity;
    return 'DZD ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  /// Get rate record for the selected wilaya
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

  double get _computedShippingCost {
    final rate = _selectedRate;
    if (rate == null) return 0;
    if (_deliveryType == 'home') {
      return (rate['home'] ?? rate['home_price'] ?? 0).toDouble();
    } else {
      return (rate['desk'] ?? rate['desk_price'] ?? 0).toDouble();
    }
  }

  String get _finalTotalPrice {
    final total = (_priceNum * quantity) + _computedShippingCost + (_commissionNum * quantity);
    return 'DZD ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'; 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: Text(_error.tr)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularButton(
                    theme,
                    Icons.arrow_back,
                    () => Navigator.pop(context),
                  ),
                  _buildCircularButton(
                    theme,
                    Icons.shopping_cart_outlined,
                    () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Product Image
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            onPageChanged: (index) {
                              setState(() {
                                currentImageIndex = index;
                              });
                            },
                            itemCount: sliderImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(sliderImages[index]),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Carousel Indicator
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              sliderImages.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: currentImageIndex == index ? 10 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white54,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: _submitting ? null : _downloadImages,
                        icon: const Icon(Icons.download),
                        label: Text('Download All Images'.tr),
                        style: TextButton.styleFrom(foregroundColor: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Title, Rating, and Quantity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _productTotalPrice,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: primaryColor.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.monetization_on_rounded,
                                          size: 14,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+ DZD $_commissionNum (x$quantity)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  _buildQtyButton(theme, Icons.remove, () {
                                    if (quantity > 1)
                                      setState(() => quantity--);
                                  }),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                    ),
                                    child: Text(
                                      '$quantity',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  _buildQtyButton(theme, Icons.add, () {
                                    if (quantity < _stock)
                                      setState(() => quantity++);
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Variants Selection
                    if (_product != null &&
                        _product!['variants'] != null &&
                        (_product!['variants'] as List).length > 1) ...[
                      Text(
                        'Select Option'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: (_product!['variants'] as List).map((
                          variant,
                        ) {
                          final isSelected =
                              _defaultVariant?['id'] == variant['id'];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _defaultVariant = variant;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withValues(alpha: 0.1)
                                    : theme.colorScheme.surfaceContainerHighest,
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<int>(
                                    value: variant['id'],
                                    groupValue: _defaultVariant?['id'],
                                    onChanged: (val) {
                                      setState(() {
                                        _defaultVariant = variant;
                                      });
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    activeColor: primaryColor,
                                    visualDensity: const VisualDensity(
                                      horizontal: -4,
                                      vertical: -4,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    variant['sku']?.toString() ?? 'Option',
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? primaryColor
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 4. Description
                    Text(
                      'Description'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _description,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _description));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied!'.tr)),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text('Copy Description'.tr),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                    const SizedBox(height: 24),

                    // 5. Client Information Form (Optional here since cart also asks for it, but kept to follow instruction)
                    _buildClientInformationCard(theme),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // 7. Bottom Bar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Product Price'.tr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _productTotalPrice,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shipping Cost'.tr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'DZD ${_computedShippingCost.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Commission'.tr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'DZD ${(_commissionNum * quantity).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Price'.tr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _finalTotalPrice,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _stock > 0
                              ? () {
                                  if (_defaultVariant == null) return;
                                  final item = CartItemModel(
                                    id: _defaultVariant!['id'].toString(),
                                    brand: _product!['brand']?['name'] ?? '',
                                    title: _product!['name'] ?? '',
                                    variantSku: _defaultVariant!['sku'] ?? '',
                                    price:
                                        double.tryParse(
                                          _defaultVariant!['sale_price']
                                              .toString(),
                                        ) ??
                                        0.0,
                                    commission:
                                        double.tryParse(
                                          _defaultVariant!['commission_value']
                                              .toString(),
                                        ) ??
                                        0.0,
                                    imageUrl:
                                        _product!['main_image_path'] != null
                                        ? ApiService.getImageUrl(
                                            _product!['main_image_path'],
                                          )
                                        : 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb',
                                    quantity: quantity,
                                    availableVariants:
                                        _product!['variants'] as List?,
                                  );
                                  CartService.instance.addToCart(item);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added to cart'.tr)),
                                  );
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Add to Cart'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _stock > 0 && !_submitting
                              ? _submitOrder
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: primaryColor.withValues(alpha: 0.4),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Buy Now'.tr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton(
    ThemeData theme,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      ),
    );
  }

  Widget _buildQtyButton(ThemeData theme, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
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
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
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
    TextEditingController? controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    BorderRadius? borderRadius,
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
}
