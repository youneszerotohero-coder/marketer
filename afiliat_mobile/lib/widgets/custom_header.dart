import 'package:flutter/material.dart';
import '../screens/cart_page.dart';
import '../screens/main_shell.dart';
import '../l10n/app_translations.dart';
import '../services/cart_service.dart';
import '../models/cart_item_model.dart';

class CustomHeader extends StatelessWidget {
  final bool showBackButton;
  const CustomHeader({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        if (showBackButton) ...[
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
        ] else ...[
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFF97316),
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          'Marketer Pulse'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFFF97316),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const Spacer(),
        if (!showBackButton) ...[
          ValueListenableBuilder<List<CartItemModel>>(
            valueListenable: CartService.instance.cartNotifier,
            builder: (context, cartItems, _) {
              final int itemCount = cartItems.fold(0, (sum, item) => sum + item.quantity);
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF97316).withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
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
                      child: const Center(
                        child: Icon(
                          Icons.shopping_cart_rounded,
                          color: Color(0xFFF97316),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$itemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: theme.colorScheme.onSurface),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
            onPressed: () {
              mainShellScaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ],
    );
  }
}
