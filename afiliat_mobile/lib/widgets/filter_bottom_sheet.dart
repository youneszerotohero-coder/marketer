import 'package:flutter/material.dart';
import '../l10n/app_translations.dart';

class FilterBottomSheet extends StatefulWidget {
  final RangeValues initialPriceRange;
  final String initialSort;
  final Set<int> initialCategories;
  final List<dynamic> availableCategories;

  const FilterBottomSheet({
    super.key,
    required this.initialPriceRange,
    required this.initialSort,
    required this.initialCategories,
    required this.availableCategories,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  late String _selectedSort;
  final List<String> _sortOptions = ['Popular', 'Newest', 'Price: Low to High', 'Price: High to Low'];
  late Set<int> _selectedCategoryIds;

  @override
  void initState() {
    super.initState();
    _priceRange = widget.initialPriceRange;
    _selectedSort = widget.initialSort;
    _selectedCategoryIds = Set.from(widget.initialCategories);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _priceRange = const RangeValues(0, 50000);
                    _selectedSort = 'Popular';
                    _selectedCategoryIds.clear();
                  });
                },
                child: Text(
                  'Reset'.tr,
                  style: const TextStyle(
                    color: Color(0xFFF97316),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Price Range
          Text(
            'Price Range (DZD)'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_priceRange.start.round()}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              Text('${_priceRange.end.round()}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFF97316),
              inactiveTrackColor: Colors.orange.withValues(alpha: 0.1),
              thumbColor: const Color(0xFFF97316),
              overlayColor: const Color(0xFFF97316).withValues(alpha: 0.2),
              trackHeight: 6,
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 0,
              max: 50000,
              divisions: 100,
              onChanged: (RangeValues values) {
                setState(() {
                  _priceRange = values;
                });
              },
            ),
          ),
          const SizedBox(height: 24),

          // Sort By
          Text(
            'Sort By'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _sortOptions.map((option) {
              final isSelected = _selectedSort == option;
              return ChoiceChip(
                label: Text(option.tr),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) _selectedSort = option;
                  });
                },
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                selectedColor: const Color(0xFFF97316).withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFFF97316) : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFF97316) : Colors.transparent,
                  ),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Categories
          Text(
            'Categories'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.availableCategories.map((cat) {
              final catId = int.tryParse(cat['id'].toString()) ?? 0;
              final isSelected = _selectedCategoryIds.contains(catId);
              return FilterChip(
                label: Text(cat['name']?.toString() ?? ''),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategoryIds.add(catId);
                    } else {
                      _selectedCategoryIds.remove(catId);
                    }
                  });
                },
                backgroundColor: theme.colorScheme.surfaceContainer,
                selectedColor: const Color(0xFFF97316),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFF97316) : theme.colorScheme.outlineVariant,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'priceRange': _priceRange,
                  'sort': _selectedSort,
                  'categories': _selectedCategoryIds,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0xFFF97316).withValues(alpha: 0.4),
              ),
              child: Text(
                'Apply Filters'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16), // Padding for bottom safe area
        ],
      ),
    );
  }
}
