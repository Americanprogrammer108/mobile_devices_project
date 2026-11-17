import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_preferences.dart';

class NotificationPreferencesRepository {
  NotificationPreferencesRepository(this.firestore);

  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> _document(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications');
  }

  Stream<NotificationPreferences> watch(String uid) {
    return _document(uid).snapshots().map(
      (snapshot) => NotificationPreferences.fromMap(snapshot.data()),
    );
  }

  Future<void> save(String uid, NotificationPreferences preferences) async {
    await _document(uid).set(preferences.toMap(), SetOptions(merge: true));
  }
}
