import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';
import '../widgets/custom_bottom_nav.dart';
import 'orders_page.dart';
import 'profile_page.dart';
import 'shop_page.dart';
import 'wallet_page.dart';

final GlobalKey<ScaffoldState> mainShellScaffoldKey = GlobalKey<ScaffoldState>();

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ShopPage(),
    const OrdersPage(),
    const WalletPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: mainShellScaffoldKey,
      endDrawer: AppDrawer(
        currentTab: _currentIndex,
        onNavigateTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
