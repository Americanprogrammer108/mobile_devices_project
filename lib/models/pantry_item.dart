
import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String unit;
  final DateTime? expirationDate;
  final DateTime? createdAt;

  PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expirationDate,
    this.createdAt,
  });

  factory PantryItem.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data()!;

    return PantryItem(
      id: document.id,
      name: data['name'] as String,
      category: data['category'] as String,
      quantity: (data['quantity'] as num).toInt(),
      unit: data['unit'] as String,
      expirationDate:
      (data['expirationDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expirationDate': expirationDate == null
          ? null
          : Timestamp.fromDate(expirationDate!),
    };
  }
}
