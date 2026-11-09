import 'package:flutter/material.dart';

import '../../models/pantry_item.dart';
import '../../theme/app_theme.dart';
import '../../utils/expiry_utils.dart';

import '../../widgets/add_item_btn.dart';
import '../../widgets/expiry_badge.dart';

import '../pantry/pantry_actions.dart';
import '../pantry/pantry_data_source.dart';
import '../pantry/pantry_screen.dart';

/**
 * The home screen that shows a pantry overview, the items expiring (soonest first), and
 * an Add Item button.
 */
///
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //Live count of items on the shopping list and live pantry items
  final _items = pantryDataSource.watchItems();
  final _shoppingCount = pantryDataSource.watchShoppingListCount();

  // opens the full Pantry screen
  void _openFullPantry() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const PantryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(title: const Text('Smart Pantry')),
      body: StreamBuilder<List<PantryItem>>(
        stream: _items,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Couldn't load your pantry."));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          final soon = expiringSooon(items);

          return ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Card(
                color: AppColors.bannerWhite,
                surfaceTintColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pantry Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<int>(
                        stream: _shoppingCount,
                        builder: (context, shopping) => Row(
                          children: [
                            _stat(
                              Icons.inventory_2,
                              AppColors.fontGreen,
                              items.length,
                              'Items',
                            ),
                            _stat(
                              Icons.notification_important,
                              AppColors.iconRed,
                              soon.length,
                              'Expiring Soon',
                            ),
                            _stat(
                              Icons.shopping_cart,
                              AppColors.iconBlue,
                              shopping.data,
                              'In Shopping List',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Text(
                    'Expiring Soon',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _openFullPantry,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.fontGreen,
                    ),
                    child: const Text('See All'),
                  ),
                ],
              ),

              if (soon.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Nothing is expiring soon')),
                )
              else
                Card(
                  color: AppColors.bannerWhite,
                  surfaceTintColor: Colors.transparent,
                  child: Column(
                    children: [
                      for (final item in soon.take(8))
                        ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            expiresLabel(daysUntilExpiry(item)!),
                            style: TextStyle(
                              color: expiresColor(daysUntilExpiry(item)!),
                            ),
                          ),
                          trailing: ExpiryBadge(days: daysUntilExpiry(item)!),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              AddItemBtn(onPressed: () => addPantryItem(context)),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(IconData icon, Color color, int? value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          Text(
            value?.toString() ?? '-',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
