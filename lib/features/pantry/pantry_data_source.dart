import 'dart:async';
import '../../models/pantry_item.dart';

abstract class PantryDataSource {
  Stream<List<PantryItem>> watchItems();
  Stream<int> watchShoppingListCount();

  Future<void> addItem(PantryItem item);
  Future<void> updateItem(PantryItem item);
  Future<void> deleteItem(String id);
}

// Switch this to the real data source once backend is done
PantryDataSource pantryDataSource = SamplePantryDataSource();

class SamplePantryDataSource implements PantryDataSource {
  SamplePantryDataSource() : _items = _sampleItems();

  List<PantryItem> _items;
  int _nextId = 1000;
  final _changes = StreamController<List<PantryItem>>.broadcast();

  @override
  Stream<List<PantryItem>> watchItems() {
    return Stream.multi((listener) {
      listener.add(_items);
      final subscription = _changes.stream.listen(listener.add);
      listener.onCancel = subscription.cancel;
    });
  }

  @override
  Stream<int> watchShoppingListCount() => Stream.value(5);

  @override
  Future<void> addItem(PantryItem item) async {
    _publish([
      ..._items,
      PantryItem(
        id: '${_nextId++}',
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        unit: item.unit,
        expirationDate: item.expirationDate,
        createdAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<void> updateItem(PantryItem item) async {
    _publish([
      for (final existing in _items) existing.id == item.id ? item : existing,
    ]);
  }

  @override
  Future<void> deleteItem(String id) async {
    _publish(_items.where((item) => item.id != id).toList());
  }

  void _publish(List<PantryItem> items) {
    _items = items;
    _changes.add(items);
  }

  static List<PantryItem> _sampleItems() {
    final now = DateTime.now();
    var nextId = 0;

    PantryItem sample(
      String name, 
      String category,
      int quantity,
      String unit,
      int daysLeft,
    ) {
      return PantryItem(
        id: 'sample-${nextId++}', 
        name: name, 
        category: category, 
        quantity: quantity, 
        unit: unit, 
        expirationDate: DateTime(now.year, now.month, now.day + daysLeft),
      );
    }

    return [
      sample('Milk', 'Dairy', 1, 'L', 1),
      sample('Eggs', 'Dairy', 12, 'pack', 8),
      sample('Cheddar Cheese', 'Dairy', 200, 'g', 15),
      sample('Bell Pepper', 'Produce', 3, 'pieces', 3),
      sample('Lettuce', 'Produce', 1, 'head', 6),
      sample('Yogurt', 'Dairy', 500, 'g', 4),
      sample('Butter', 'Dairy', 454, 'g', 30),
      sample('Apples', 'Produce', 6, 'pieces', 12),
      sample('Carrots', 'Produce', 1, 'kg', 14),
      sample('Bananas', 'Produce', 5, 'pieces', 7),
      sample('Chicken Breast', 'Meat & Seafood', 1, 'kg', 9),
      sample('Ground Beef', 'Meat & Seafood', 500, 'g', 10),
      sample('Salmon', 'Meat & Seafood', 2, 'fillets', 11),
      sample('Frozen Peas', 'Frozen', 750, 'g', 120),
      sample('Ice Cream', 'Frozen', 1, 'tub', 90),
      sample('Orange Juice', 'Beverages', 1, 'L', 13),
      sample('Coffee', 'Beverages', 340, 'g', 180),
      sample('Whole Wheat Bread', 'Bakery', 1, 'loaf', 6),
      sample('Bagels', 'Bakery', 6, 'pack', 8),
      sample('White Rice', 'Pantry Staples', 2, 'kg', 365),
      sample('Spaghetti', 'Pantry Staples', 900, 'g', 300),
      sample('Flour', 'Pantry Staples', 2, 'kg', 200),
      sample('Tomato Sauce', 'Pantry Staples', 680, 'mL', 240),
      sample('Olive Oil', 'Other', 500, 'mL', 400),
    ];
  }
}

