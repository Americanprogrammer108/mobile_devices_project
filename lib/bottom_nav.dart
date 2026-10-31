import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'features/pantry/pantry_screen.dart';
import 'features/shopping_list/shopping_list_screen.dart';
import 'features/product_search/product_search_screen.dart';
import 'routing/app_routes.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentTab = 0;

  final _tabs = const [
    HomeScreen(),
    PantryScreen(),
    ShoppingListScreen(),
    ProductSearchScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 4) {
      _openMoreMenu();
    } else {
      setState(() {
        _currentTab = index;
      });
    }
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, AppRoutes.history);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentTab, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            label: 'Pantry',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'List',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
