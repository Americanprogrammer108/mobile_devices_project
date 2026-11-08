import 'package:flutter/material.dart';
import 'package:mobile_devices_project/widgets/add_item_btn.dart';

import '../../models/pantry_item.dart';
import '../../theme/app_theme.dart';
import '../../utils/expiry_utils.dart';

import '../../widgets/expiry_badge.dart';

import 'pantry_data_source.dart';
import 'pantry_actions.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _items = pantryDataSource.watchItems();
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Pantry')),
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
          final filters = [
            'All',
            ...{for (final i in items) i.category},
          ];
          final shown =
              items
                  .where((i) => _filter == 'All' || i.category == _filter)
                  .toList()
                ..sort(compareByExpiry);

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    for (final f in filters)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: f == _filter,
                          onSelected: (_) => setState(() {
                            _filter = f;
                          }),
                          shape: const StadiumBorder(),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? const Center(child: Text('No items yet. Tap Add Item.'))
                    : ListView.separated(
                        itemCount: shown.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = shown[index];
                          final days = daysUntilExpiry(item);
                          final date = item.expirationDate;
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              '${quantityLabel(item)}\n'
                              '${date == null ? 'No expiration date' : 'Exp: ${formatDate(date)}'}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (days != null) ExpiryBadge(days: days),
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      editPantryItem(context, item),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.iconRed,
                                  ),
                                  onPressed: () =>
                                      deletePantryItem(context, item),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: AddItemBtn(onPressed: () => addPantryItem(context)),
      ),
    );
  }
}
