import 'package:flutter/material.dart';

import '../screens/cart_page.dart';
import '../screens/shipping_prices_page.dart';
import '../main.dart';
import '../l10n/app_translations.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) onNavigateTab;
  final int currentTab;

  const AppDrawer({
    super.key,
    required this.onNavigateTab,
    required this.currentTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Afiliat',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                children: [
                  _buildSectionTitle('MAIN MENU'.tr, theme),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    context,
                    theme,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard'.tr,
                    isSelected: currentTab == 0,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(0);
                    },
                  ),
                  _buildNavItem(
                    context,
                    theme,
                    icon: Icons.storefront_outlined,
                    label: 'Shop'.tr,
                    isSelected: currentTab == 1,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(1);
                    },
                  ),
                  _buildNavItem(
                    context,
                    theme,
                    icon: Icons.shopping_bag_outlined,
                    label: 'Orders'.tr,
                    isSelected: currentTab == 2,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(2);
                    },
                  ),
                  _buildNavItem(
                    context,
                    theme,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet'.tr,
                    isSelected: currentTab == 3,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(3);
                    },
                  ),
                  _buildNavItem(
                    context,
                    theme,
                    icon: Icons.person_outline,
                    label: 'Profile'.tr,
                    isSelected: currentTab == 4,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateTab(4);
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('MORE'.tr, theme),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    context,
                    theme,
                    icon: Icons.shopping_cart_outlined,
                    label: 'Cart'.tr,
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      if (ModalRoute.of(context)?.settings.name != 'CartPage') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CartPage(),
                            settings: const RouteSettings(name: 'CartPage'),
                          ),
                        );
                      }
                    },
                  ),
                  _buildNavItem(
                    context,
                    theme,
                    icon: Icons.local_shipping_outlined,
                    label: 'Shipping Prices'.tr,
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShippingPricesPage(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('SETTINGS'.tr, theme),
                  const SizedBox(height: 8),
                  
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeModeNotifier,
                    builder: (context, currentThemeMode, _) {
                      final isDarkMode = currentThemeMode == ThemeMode.dark || 
                          (currentThemeMode == ThemeMode.system && 
                           MediaQuery.of(context).platformBrightness == Brightness.dark);
                      return SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          'Dark Mode'.tr,
                          style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        ),
                        secondary: Icon(
                          isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        value: isDarkMode,
                        activeThumbColor: theme.colorScheme.primary,
                        onChanged: (value) {
                          themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                        },
                      );
                    },
                  ),
                  
                  ValueListenableBuilder<Locale>(
                    valueListenable: localeNotifier,
                    builder: (context, currentLocale, _) {
                      final isArabic = currentLocale.languageCode == 'ar';
                      return SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          'العربية'.tr,
                          style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        ),
                        secondary: Icon(
                          Icons.language,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        value: isArabic,
                        activeThumbColor: theme.colorScheme.primary,
                        onChanged: (value) {
                          localeNotifier.value = value ? const Locale('ar') : const Locale('en');
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
