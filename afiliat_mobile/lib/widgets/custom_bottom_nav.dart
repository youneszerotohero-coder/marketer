import 'package:flutter/material.dart';
import '../l10n/app_translations.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.storefront_outlined),
          activeIcon: const Icon(Icons.storefront),
          label: 'Shop'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_bag_outlined),
          activeIcon: const Icon(Icons.shopping_bag),
          label: 'Orders'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          activeIcon: const Icon(Icons.account_balance_wallet),
          label: 'Wallet'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: 'Profile'.tr,
        ),
      ],
    );
  }
}

class _ActiveIcon extends StatelessWidget {
  final IconData icon;

  const _ActiveIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
