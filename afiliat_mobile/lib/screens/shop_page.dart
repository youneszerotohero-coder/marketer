import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import 'product_details.dart';
import '../widgets/product_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../l10n/app_translations.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

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
              _buildCategories(theme),
              const SizedBox(height: 20),
              Expanded(
                child: _buildProductGrid(context),
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
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FilterBottomSheet(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(ThemeData theme) {
    final categories = [
      {
        'name': 'All'.tr,
        'image': 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?auto=format&fit=crop&w=200&q=80',
      },
      {
        'name': 'Electronics'.tr,
        'image': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=200&q=80',
      },
      {
        'name': 'Fashion'.tr,
        'image': 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=200&q=80',
      },
      {
        'name': 'Home'.tr,
        'image': 'https://images.unsplash.com/photo-1556020685-e631950279c2?auto=format&fit=crop&w=200&q=80',
      },
      {
        'name': 'Beauty'.tr,
        'image': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=200&q=80',
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return GestureDetector(
            onTap: () {},
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
                          image: NetworkImage(categories[index]['image']!),
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
                  categories[index]['name']!,
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
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.55, // Adjusted to fit the new card design better on small screens
      children: [
        ProductCard(
          brand: 'SONY',
          rating: '4.8',
          title: 'WH-1000XM4 Wireless...',
          price: 'DZD 4,500',
          stockText: 'In Stock'.tr,
          inStock: true,
          commission: '+ DZD 450',
          imageUrl: 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?auto=format&fit=crop&w=300&q=80',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDetails(
              title: 'WH-1000XM4 Wireless...',
              price: 'DZD 4,500',
              commission: '+ DZD 450',
              imageUrl: 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?auto=format&fit=crop&w=300&q=80',
            )));
          },
          onAddToCart: () {},
        ),
        ProductCard(
          brand: 'GARMIN',
          rating: '4.5',
          title: 'Venu 2 Fitness Smartwatch',
          price: 'DZD 12,900',
          stockText: 'In Stock'.tr,
          inStock: true,
          commission: '+ DZD 820',
          imageUrl: 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?auto=format&fit=crop&w=300&q=80',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDetails(
              title: 'Venu 2 Fitness Smartwatch',
              price: 'DZD 12,900',
              commission: '+ DZD 820',
              imageUrl: 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?auto=format&fit=crop&w=300&q=80',
            )));
          },
          onAddToCart: () {},
        ),
        ProductCard(
          brand: 'NIKE',
          rating: '4.9',
          title: 'Air Max Pro Running Gear',
          price: 'DZD 6,200',
          stockText: 'Low Stock'.tr,
          inStock: false,
          commission: '+ DZD 250',
          imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=300&q=80',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDetails(
              title: 'Air Max Pro Running Gear',
              price: 'DZD 6,200',
              commission: '+ DZD 250',
              imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=300&q=80',
            )));
          },
          onAddToCart: () {},
        ),
        ProductCard(
          brand: 'HERITAGE',
          rating: '4.7',
          title: 'Handcrafted Leather Bag',
          price: 'DZD 8,700',
          stockText: 'In Stock'.tr,
          inStock: true,
          commission: '+ DZD 550',
          imageUrl: 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=300&q=80',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDetails(
              title: 'Handcrafted Leather Bag',
              price: 'DZD 8,700',
              commission: '+ DZD 550',
              imageUrl: 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=300&q=80',
            )));
          },
          onAddToCart: () {},
        ),
      ],
    );
  }
}
