import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/cart_page.dart';
import '../screens/shipping_prices_page.dart';
import '../main.dart';
import '../l10n/app_translations.dart';
import '../services/api_service.dart';

class AppDrawer extends StatefulWidget {
  final Function(int) onNavigateTab;
  final int currentTab;

  const AppDrawer({
    super.key,
    required this.onNavigateTab,
    required this.currentTab,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, String?> _socialLinks = {};

  @override
  void initState() {
    super.initState();
    _loadSocialLinks();
  }

  Future<void> _loadSocialLinks() async {
    try {
      final data = await ApiService.instance.get('/app/settings');
      if (mounted) {
        setState(() {
          _socialLinks = {
            'facebook': data['social.facebook']?.toString(),
            'telegram': data['social.telegram']?.toString(),
            'whatsapp': data['social.whatsapp']?.toString(),
            'instagram': data['social.instagram']?.toString(),
            'tiktok': data['social.tiktok']?.toString(),
            'viber': data['social.viber']?.toString(),
            'phone': data['social.phone']?.toString(),
            'pdf': data['pdf_document_url']?.toString(),
          };
        });
      }
    } catch (_) {
    }
  }

  /// Build a properly-formed URI for each social link type
  String _buildLaunchUrl(String key, String value) {
    final trimmed = value.trim();
    switch (key) {
      case 'phone':
        if (trimmed.startsWith('tel:')) return trimmed;
        return 'tel:$trimmed';

      case 'whatsapp':
        if (trimmed.startsWith('http')) return trimmed;
        final wDigits = trimmed.replaceAll(RegExp(r'\D'), '');
        return 'https://wa.me/$wDigits';

      case 'viber':
        if (trimmed.startsWith('viber:')) return trimmed;
        if (trimmed.startsWith('http')) return trimmed;
        final vDigits = trimmed.replaceAll(RegExp(r'\D'), '');
        return 'viber://chat?number=%2B$vDigits';

      case 'telegram':
        if (trimmed.startsWith('http')) return trimmed;
        final username = trimmed.replaceFirst('@', '');
        return 'https://t.me/$username';

      default:
        return trimmed;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
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
            ),

            // ── Nav list ────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                children: [
                  _buildSectionTitle('MAIN MENU'.tr, theme),
                  const SizedBox(height: 8),
                  _buildNavItem(context, theme,
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard'.tr,
                      isSelected: widget.currentTab == 0,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateTab(0);
                      }),
                  _buildNavItem(context, theme,
                      icon: Icons.storefront_outlined,
                      label: 'Shop'.tr,
                      isSelected: widget.currentTab == 1,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateTab(1);
                      }),
                  _buildNavItem(context, theme,
                      icon: Icons.shopping_bag_outlined,
                      label: 'Orders'.tr,
                      isSelected: widget.currentTab == 2,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateTab(2);
                      }),
                  _buildNavItem(context, theme,
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Wallet'.tr,
                      isSelected: widget.currentTab == 3,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateTab(3);
                      }),
                  _buildNavItem(context, theme,
                      icon: Icons.person_outline,
                      label: 'Profile'.tr,
                      isSelected: widget.currentTab == 4,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateTab(4);
                      }),

                  const SizedBox(height: 24),
                  _buildSectionTitle('MORE'.tr, theme),
                  const SizedBox(height: 8),
                  _buildNavItem(context, theme,
                      icon: Icons.shopping_cart_outlined,
                      label: 'Cart'.tr,
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        if (ModalRoute.of(context)?.settings.name !=
                            'CartPage') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CartPage(),
                              settings:
                                  const RouteSettings(name: 'CartPage'),
                            ),
                          );
                        }
                      }),
                  _buildNavItem(context, theme,
                      icon: Icons.local_shipping_outlined,
                      label: 'Shipping Prices'.tr,
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShippingPricesPage(),
                          ),
                        );
                      }),
                  _buildNavItem(context, theme,
                      icon: Icons.description_outlined,
                      label: 'Office Numbers'.tr,
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        final rawPdf = _socialLinks['pdf']?.trim().isNotEmpty == true
                            ? _socialLinks['pdf']!
                            : 'https://afiliat.com/office-numbers.pdf';
                        _launchUrl(_buildLaunchUrl('pdf', rawPdf));
                      }),

                  const SizedBox(height: 24),
                  _buildSectionTitle('SETTINGS'.tr, theme),
                  const SizedBox(height: 8),

                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeModeNotifier,
                    builder: (context, currentThemeMode, _) {
                      final isDarkMode = currentThemeMode == ThemeMode.dark ||
                          (currentThemeMode == ThemeMode.system &&
                              MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark);
                      return SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        title: Text('Dark Mode'.tr,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface)),
                        secondary: Icon(
                          isDarkMode
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        value: isDarkMode,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (value) {
                          themeModeNotifier.value =
                              value ? ThemeMode.dark : ThemeMode.light;
                        },
                      );
                    },
                  ),

                  ValueListenableBuilder<Locale>(
                    valueListenable: localeNotifier,
                    builder: (context, currentLocale, _) {
                      final isArabic = currentLocale.languageCode == 'ar';
                      return SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        title: Text('العربية'.tr,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface)),
                        secondary: Icon(Icons.language,
                            color: theme.colorScheme.onSurfaceVariant),
                        value: isArabic,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (value) {
                          localeNotifier.value =
                              value ? const Locale('ar') : const Locale('fr');
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('HELP & SUPPORT'.tr, theme),
                  const SizedBox(height: 12),
                  _buildSupportSection(theme, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Help & Support Section ─────────────────────────────────────────────
  Widget _buildSupportSection(ThemeData theme, bool isDark) {
    // Primary support channels
    final Map<String, Map<String, dynamic>> primaryChannels = {
      'whatsapp': {
        'icon': FontAwesomeIcons.whatsapp,
        'color': const Color(0xFF25D366),
        'title': 'WhatsApp'.tr,
        'subtitle': 'Chat Support'.tr,
        'key': 'whatsapp',
      },
      'phone': {
        'icon': FontAwesomeIcons.phone,
        'color': const Color(0xFF0D9488), // Teal
        'title': 'Call Us'.tr,
        'subtitle': 'Direct Call'.tr,
        'key': 'phone',
      },
      'telegram': {
        'icon': FontAwesomeIcons.telegram,
        'color': const Color(0xFF26A5E4),
        'title': 'Telegram'.tr,
        'subtitle': 'Join Channel'.tr,
        'key': 'telegram',
      },
      'viber': {
        'icon': FontAwesomeIcons.viber,
        'color': const Color(0xFF7360F2),
        'title': 'Viber'.tr,
        'subtitle': 'Chat Support'.tr,
        'key': 'viber',
      },
    };

    // Secondary social channels
    final Map<String, Map<String, dynamic>> secondaryChannels = {
      'facebook': {
        'icon': FontAwesomeIcons.facebook,
        'color': const Color(0xFF1877F2),
        'label': 'Facebook',
      },
      'instagram': {
        'icon': FontAwesomeIcons.instagram,
        'color': const Color(0xFFE1306C),
        'label': 'Instagram',
      },
      'tiktok': {
        'icon': FontAwesomeIcons.tiktok,
        'color': isDark ? Colors.white70 : Colors.black87,
        'label': 'TikTok',
      },
    };

    // Fallbacks if backend DB settings are not configured/seeded
    final defaultValues = {
      'phone': '+213555123456',
      'whatsapp': '+213555123456',
      'telegram': 'afiliat_support',
      'pdf': 'https://afiliat.com/office-numbers.pdf',
      'facebook': 'https://facebook.com/afiliat',
      'instagram': 'https://instagram.com/afiliat',
      'tiktok': 'https://tiktok.com/@afiliat',
      'viber': '+213555123456',
    };

    String getVal(String key) {
      final val = _socialLinks[key];
      if (val != null && val.trim().isNotEmpty) {
        return val;
      }
      return defaultValues[key] ?? '';
    }

    final gridItems = primaryChannels.entries.map((entry) {
      final item = entry.value;
      final key = item['key'] as String;
      final rawValue = getVal(key);
      final color = item['color'] as Color;

      return Material(
        color: isDark ? theme.colorScheme.surface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (rawValue.isNotEmpty) {
              _launchUrl(_buildLaunchUrl(key, rawValue));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? theme.dividerColor.withOpacity(0.5)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(
                      item['icon'],
                      color: color,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    // Secondary buttons (shown only if configured in DB or fallback exists)
    final secondaryButtons = secondaryChannels.entries
        .where((entry) => _socialLinks[entry.key] != null && _socialLinks[entry.key]!.trim().isNotEmpty)
        .map((entry) {
      final key = entry.key;
      final item = entry.value;
      final rawValue = getVal(key);
      final color = item['color'] as Color;

      return GestureDetector(
        onTap: () {
          if (rawValue.isNotEmpty) {
            _launchUrl(_buildLaunchUrl(key, rawValue));
          }
        },
        child: Tooltip(
          message: item['label'] as String,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? theme.dividerColor.withOpacity(0.5)
                    : Colors.grey.shade200,
              ),
            ),
            child: Center(
              child: FaIcon(
                item['icon'],
                color: isDark ? color : color.withOpacity(0.85),
                size: 14,
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: gridItems,
          ),
        ),
        if (secondaryButtons.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Follow Us'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: secondaryButtons,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
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
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(
            icon,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
