import 'package:flutter/material.dart';
import '../l10n/app_translations.dart';

class ShippingPricesPage extends StatelessWidget {
  const ShippingPricesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mock data for Wilayas (States) and their shipping prices
    final List<Map<String, dynamic>> shippingRates = [
      {'id': '01', 'name': 'Adrar', 'home': 1200, 'desk': 800},
      {'id': '02', 'name': 'Chlef', 'home': 600, 'desk': 400},
      {'id': '06', 'name': 'Béjaïa', 'home': 700, 'desk': 450},
      {'id': '09', 'name': 'Blida', 'home': 450, 'desk': 250},
      {'id': '15', 'name': 'Tizi Ouzou', 'home': 650, 'desk': 400},
      {'id': '16', 'name': 'Alger', 'home': 400, 'desk': 200},
      {'id': '23', 'name': 'Annaba', 'home': 800, 'desk': 550},
      {'id': '25', 'name': 'Constantine', 'home': 750, 'desk': 500},
      {'id': '31', 'name': 'Oran', 'home': 600, 'desk': 400},
      {'id': '35', 'name': 'Boumerdès', 'home': 450, 'desk': 250},
      {'id': '39', 'name': 'El Oued', 'home': 1100, 'desk': 750},
      {'id': '47', 'name': 'Ghardaïa', 'home': 1000, 'desk': 700},
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Shipping Prices'.tr,
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Delivery rates vary by state. Choose between Home Delivery or Stop Desk pickup.'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: shippingRates.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final state = shippingRates[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                state['id'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              state['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPriceRow(
                          context,
                          theme,
                          icon: Icons.home_outlined,
                          title: 'Home Delivery'.tr,
                          price: '${state['home']} DZD',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        _buildPriceRow(
                          context,
                          theme,
                          icon: Icons.storefront_outlined,
                          title: 'Desk Delivery'.tr,
                          price: '${state['desk']} DZD',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, ThemeData theme, {required IconData icon, required String title, required String price}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          price,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
