import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_devices_project/routing/app_routes.dart';
import 'package:mobile_devices_project/screens/sign_in.dart';
import 'package:mobile_devices_project/services/expiry_notification_binding.dart';
import 'package:mobile_devices_project/services/notification_services.dart';
import 'package:mobile_devices_project/theme/app_theme.dart';
import 'bottom_nav.dart';
import 'firebase_options.dart';
import 'dart:async';

import 'package:mobile_devices_project/services/expiry_reminder_time.dart';
import 'package:mobile_devices_project/services/notification_preferences.dart';
import 'package:mobile_devices_project/services/notification_preferences_repository.dart';

import 'package:openfoodfacts/openfoodfacts.dart' as off;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  off.OpenFoodAPIConfiguration.userAgent = off.UserAgent(
    name: 'MyFoodApp',
    url: 'https://myfoodapp.example.com', // or an email contact
  );
  off.OpenFoodAPIConfiguration.globalLanguages = [
    off.OpenFoodFactsLanguage.ENGLISH,
  ];
  off.OpenFoodAPIConfiguration.globalCountry = off.OpenFoodFactsCountry.USA;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await startAppServices();
  runApp(const SmartPantryApp());
}

Stream<List<PantryReminder>> watchPantryReminders(String uid) {
  late final StreamController<List<PantryReminder>> controller;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? itemsSubscription;
  StreamSubscription<NotificationPreferences>? preferencesSubscription;

  QuerySnapshot<Map<String, dynamic>>? latestItems;
  NotificationPreferences? latestPreferences;

  void emitReminders() {
    if (controller.isClosed ||
        latestItems == null ||
        latestPreferences == null) {
      return;
    }

    final preferences = latestPreferences!;

    if (!preferences.expirationWarnings) {
      controller.add(const <PantryReminder>[]);
      return;
    }

    final reminders = <PantryReminder>[];

    for (final document in latestItems!.docs) {
      final data = document.data();
      final expirationDate = data['expirationDate'];

      if (expirationDate is! Timestamp) continue;

      final remindAt = calculateExpiryReminder(
        expirationDate.toDate(),
        daysBefore: preferences.daysBeforeExpiry,
      );

      if (remindAt == null) continue;

      reminders.add(
        PantryReminder(
          id: document.id,
          name: data['name'] as String? ?? 'Unnamed item',
          remindAt: remindAt,
        ),
      );
    }

    controller.add(reminders);
  }

  controller = StreamController<List<PantryReminder>>(
    onListen: () {
      final firestore = FirebaseFirestore.instance;

      itemsSubscription = firestore
          .collection('users')
          .doc(uid)
          .collection('items')
          .snapshots()
          .listen((snapshot) {
            latestItems = snapshot;
            emitReminders();
          }, onError: controller.addError);

      final repository = NotificationPreferencesRepository(firestore);

      preferencesSubscription = repository.watch(uid).listen((preferences) {
        latestPreferences = preferences;
        emitReminders();
      }, onError: controller.addError);
    },
    onCancel: () async {
      await itemsSubscription?.cancel();
      await preferencesSubscription?.cancel();
    },
  );

  return controller.stream;
}

late final NotificationService notificationService;
late final ExpiryNotificationBinding notificationBinding;

Future<void> _authQueue = Future<void>.value();
int _authGeneration = 0;

Future<void> startAppServices() async {
  notificationService = await NotificationService.create();

  notificationBinding = ExpiryNotificationBinding(notificationService);

  FirebaseAuth.instance.authStateChanges().listen((user) {
    final generation = ++_authGeneration;
    final uid = user?.uid;

    _authQueue = _authQueue
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Previous auth transition failed: $error');
        })
        .then((_) async {
          // Ignore an outdated authentication event.
          if (generation != _authGeneration) return;

          debugPrint(
            'Processing notification auth transition: '
            '${uid == null ? "signed out" : "signed in"}',
          );

          // Stop the old Firestore listeners and clear reminders.
          await notificationBinding.stop(clearNotifications: true);

          // A newer authentication event may have arrived.
          if (generation != _authGeneration) return;

          if (uid == null) {
            debugPrint('Notification auth transition: signed out');
            return;
          }

          // Confirm this is still the authenticated account.
          if (FirebaseAuth.instance.currentUser?.uid != uid) {
            return;
          }

          await notificationBinding.start(watchPantryReminders(uid));

          debugPrint('Notification auth transition: listener started');
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Notification auth transition failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        });
  });
}

class SmartPantryApp extends StatelessWidget {
  const SmartPantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Pantry',
      theme: AppTheme.light,
      home: const AuthGate(),
      // Keep the skeleton routes for settings/history/product detail/etc.
      // Its '/' route is deliberately omitted: AuthGate owns the app entry.
      routes: {...AppRoutes.routes}..remove('/'),
    );
  }
}

//Need a couple components
//Firebase authentication service, which is used for user login
//Firebase SDK, which is used to interact with the firebase when logged in
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        return user == null ? const SignInScreen() : const BottomNav();
      },
    );
  }
}
