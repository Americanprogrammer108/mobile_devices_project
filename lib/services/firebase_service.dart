
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pantry_item.dart';

class FirestoreService {
  final CollectionReference<Map<String, dynamic>> _pantry =
  FirebaseFirestore.instance.collection('pantry_items');

  // Read all pantry items in real time.
  Stream<List<PantryItem>> getPantryItems() {
    return _pantry.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => PantryItem.fromFirestore(doc))
          .toList(),
    );
  }

  // Add a new pantry item.
  Future<void> addPantryItem(PantryItem item) async {
    await _pantry.add({
      ...item.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing pantry item.
  Future<void> updatePantryItem(PantryItem item) async {
    await _pantry.doc(item.id).update(item.toFirestore());
  }

  // Delete a pantry item.
  Future<void> deletePantryItem(String id) async {
    await _pantry.doc(id).delete();
  }
}
