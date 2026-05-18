import 'package:flutter/material.dart';
import '../screens/cart_page.dart';
import '../screens/main_shell.dart';
import '../l10n/app_translations.dart';

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
        ],
        const CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
        ),
        const SizedBox(width: 12),
        Text(
          'Marketer Pulse'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFFF97316),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.onSurface),
          onPressed: () {
            // Only navigate to cart if we are not already on it
            if (ModalRoute.of(context)?.settings.name != 'CartPage') {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage(), settings: const RouteSettings(name: 'CartPage')),
              );
            }
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
    );
  }
}
