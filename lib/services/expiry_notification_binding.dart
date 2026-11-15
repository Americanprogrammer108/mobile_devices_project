import 'dart:async';

import 'package:flutter/foundation.dart';

import 'notification_services.dart';

class ExpiryNotificationBinding {
  ExpiryNotificationBinding(this._notifications);

  final NotificationService _notifications;

  StreamSubscription<List<PantryReminder>>? _subscription;

  // Serializes notification operations.
  Future<void> _queue = Future<void>.value();

  // Invalidates events from previous subscriptions.
  int _generation = 0;

  Future<void> start(Stream<List<PantryReminder>> reminderStream) async {
    await stop(clearNotifications: false);

    final generation = _generation;

    _subscription = reminderStream.listen(
      (reminders) {
        if (generation != _generation) return;

        _enqueueReconcile(reminders, generation);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (generation != _generation) return;

        debugPrint('Expiry notification listener error: $error');
      },
    );
  }

  void _enqueueReconcile(List<PantryReminder> reminders, int generation) {
    final snapshot = List<PantryReminder>.unmodifiable(reminders);

    debugPrint('Expiry binding received ${snapshot.length} reminders');

    _queue = _queue
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Previous reconcile failed: $error');
        })
        .then((_) async {
          // Ignore queued events from an obsolete subscription.
          if (generation != _generation) return;

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
    // Invalidate the previous subscription immediately.
    _generation++;

    final oldSubscription = _subscription;
    _subscription = null;

    await oldSubscription?.cancel();

    // Wait for already-running notification operations.
    await _queue;

    if (clearNotifications) {
      _enqueueReconcile(const <PantryReminder>[], _generation);

      await _queue;
    }
  }
}
