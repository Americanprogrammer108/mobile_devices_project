
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  CollectionReference<Map<String, dynamic>> get items {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('items');
  }

  // final CollectionReference<Map<String, dynamic>> _pantry =
  // FirebaseFirestore.instance.collection('pantry_items');
  //
  // CollectionReference<Map<String, dynamic>> get items {
  //   final user = FirebaseAuth.instance.currentUser;
  //
  //   if (user == null) {
  //     throw StateError('User must be signed in.');
  //   }
  //
  //   return FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(user.uid)
  //       .collection('items');
  // }
  //
  // // Read all pantry items in real time.
  // Stream<List<PantryItem>> getPantryItems() {
  //   return _pantry.snapshots().map(
  //         (snapshot) => snapshot.docs
  //         .map((doc) => PantryItem.fromFirestore(doc))
  //         .toList(),
  //   );
  // }
  //
  // // Add a new pantry item.
  // Future<void> addPantryItem(PantryItem item) async {
  //   await _pantry.add({
  //     ...item.toFirestore(),
  //     'createdAt': FieldValue.serverTimestamp(),
  //   });
  // }
  //
  // // Update an existing pantry item.
  // Future<void> updatePantryItem(PantryItem item) async {
  //   await _pantry.doc(item.id).update(item.toFirestore());
  // }
  //
  // // Delete a pantry item.
  // Future<void> deletePantryItem(String id) async {
  //   await _pantry.doc(id).delete();
  // }
}
