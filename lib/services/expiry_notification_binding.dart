import 'dart:async';

import 'notification_services.dart';
import 'package:flutter/foundation.dart';

class ExpiryNotificationBinding {
  ExpiryNotificationBinding(this._notifications);

  final NotificationService _notifications;
  StreamSubscription<List<PantryReminder>>? _subscription;

  // Prevent overlapping Firestore events from scheduling concurrently.
  Future<void> _queue = Future.value();

  Future<void> start(Stream<List<PantryReminder>> reminderStream) async {
    await stop(clearNotifications: false);

    _subscription = reminderStream.listen(
      _enqueueReconcile,
      onError: (Object error, StackTrace stackTrace) {
        // Replace with your logger if desired.
        debugPrint('Expiry notification listener error: $error');
      },
    );
  }

  void _enqueueReconcile(List<PantryReminder> reminders) {
    final snapshot = List<PantryReminder>.unmodifiable(reminders);
    debugPrint('Expiry binding received ${reminders.length} reminders');
    _queue = _queue
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Previous reconcile failed: $error');
        })
        .then((_) async {
          debugPrint('Starting notification reconciliation');

          try {
            await _notifications.reconcile(snapshot);
            await _notifications.debugPendingNotifications();
            debugPrint('Notification reconciliation completed');
          } catch (error, stackTrace) {
            debugPrint('Notification reconciliation failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          }
        });
  }

  Future<void> stop({bool clearNotifications = false}) async {
    await _subscription?.cancel();
    _subscription = null;

    if (clearNotifications) {
      _enqueueReconcile(const []);
    }

    await _queue;
  }
}
