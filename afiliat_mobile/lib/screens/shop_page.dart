import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import 'product_details.dart';
import '../widgets/product_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  bool _loadingCategories = true;
  bool _loadingProducts = true;
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  
  RangeValues _priceRange = const RangeValues(0, 50000);
  String _selectedSort = 'Popular';
  Set<int> _selectedCategoryIds = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await ApiService.instance.get('/categories');
      if (mounted) {
        setState(() {
          final List<dynamic> catList = data is List ? data : (data['data'] ?? []);
          _categories = [
            {'id': null, 'name': 'All'.tr, 'image_url': 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?auto=format&fit=crop&w=200&q=80'},
            ...catList.map((c) => {
              'id': c['id'],
              'name': c['name'],
              'image_url': c['image_url'] ?? 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=200&q=80'
            })
          ];
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadProducts({int? categoryId}) async {
    setState(() => _loadingProducts = true);
    try {
      final queryParams = <String, dynamic>{};
      
      final currentCatId = categoryId ?? (_categories.isNotEmpty ? _categories[_selectedCategoryIndex]['id'] : null);
      final Set<int> allCatIds = Set.from(_selectedCategoryIds);
      if (currentCatId != null) {
        final parsedId = int.tryParse(currentCatId.toString());
        if (parsedId != null) allCatIds.add(parsedId);
      }
      
      if (allCatIds.isNotEmpty) {
        queryParams['category_id'] = allCatIds.join(',');
      }
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }
      if (_priceRange.start > 0) queryParams['min_price'] = _priceRange.start.round().toString();
      if (_priceRange.end < 50000) queryParams['max_price'] = _priceRange.end.round().toString();
      
      if (_selectedSort == 'Newest') queryParams['sort'] = 'newest';
      else if (_selectedSort == 'Price: Low to High') queryParams['sort'] = 'price_asc';
      else if (_selectedSort == 'Price: High to Low') queryParams['sort'] = 'price_desc';

      final data = await ApiService.instance.get('/products', query: queryParams);
      if (mounted) {
        setState(() {
          _products = data['data'] ?? [];
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    _loadProducts(categoryId: _categories[index]['id']);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(),
              const SizedBox(height: 24),
              _buildSearchAndFilter(context, theme),
              const SizedBox(height: 20),
              if (_loadingCategories)
                const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
              else
                _buildCategories(theme),
              const SizedBox(height: 20),
              Expanded(
                child: _loadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                        ? Center(child: Text('No products found.'.tr))
                        : _buildProductGrid(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search for products, brands...'.tr,
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFFB923C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () async {
              final availableCats = _categories.where((c) => c['id'] != null).toList();
              final result = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FilterBottomSheet(
                  initialPriceRange: _priceRange,
                  initialSort: _selectedSort,
                  initialCategories: _selectedCategoryIds,
                  availableCategories: availableCats,
                ),
              );
              
              if (result != null) {
                setState(() {
                  _priceRange = result['priceRange'];
                  _selectedSort = result['sort'];
                  _selectedCategoryIds = result['categories'];
                });
                _loadProducts();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(ThemeData theme) {
    if (_categories.isEmpty) return const SizedBox();

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          final category = _categories[index];
          return GestureDetector(
            onTap: () => _onCategorySelected(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: const Color(0xFFF97316), width: 3)
                        : Border.all(color: Colors.transparent, width: 3),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF97316).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(category['image_url'] ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: isSelected
                          ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.2),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] ?? '',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFF97316) : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.55,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        // The structure of product from backend:
        // id, name, description, brand, category, variants, main_image_path
        final brandName = product['brand'] != null ? product['brand']['name'] : '';
        final title = product['name'] ?? '';
        final imageUrl = product['main_image_path'] != null ? ApiService.getImageUrl(product['main_image_path']) : 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?auto=format&fit=crop&w=300&q=80';
        
        // Find a default variant
        final variants = product['variants'] as List? ?? [];
        final defaultVariant = variants.isNotEmpty ? variants.first : null;
        
        final price = defaultVariant != null ? double.tryParse(defaultVariant['sale_price'].toString()) ?? 0.0 : 0.0;
        final commission = defaultVariant != null ? double.tryParse(defaultVariant['commission_value'].toString()) ?? 0.0 : 0.0;
        final stock = defaultVariant != null ? int.tryParse(defaultVariant['stock'].toString()) ?? 0 : 0;

        return ProductCard(
          brand: brandName,
          rating: '4.5', // Placeholder, API might not have it
          title: title,
          price: 'DZD $price',
          stockText: stock > 0 ? 'In Stock'.tr : 'Out of Stock'.tr,
          inStock: stock > 0,
          commission: '+ DZD $commission',
          imageUrl: imageUrl,
          onTap: () {
            // We pass the full product object via ProductDetails arguments, or fetch it by ID.
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetails(
              productId: product['id'],
            )));
          },
          onAddToCart: () {
            if (defaultVariant == null || stock <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Product is out of stock'.tr)),
              );
              return;
            }
            final item = CartItemModel(
              id: defaultVariant['id'].toString(),
              brand: brandName,
              title: title,
              variantSku: defaultVariant['sku'] ?? '',
              price: price,
              commission: commission,
              imageUrl: imageUrl,
              quantity: 1,
              availableVariants: variants,
            );
            CartService.instance.addToCart(item);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${'Added to cart'.tr}: $title')),
            );
          },
        );
      },
    );
  }
}
