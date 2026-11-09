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
import 'features/barcode_scanner/barcode_scanner_screen.dart';
import 'features/history/history_screen.dart';
import 'features/product_details/product_details_screen.dart';
import 'features/settings/settings_screen.dart';
import 'firebase_options.dart';

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
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('items')
      .snapshots()
      .map((snapshot) {
        final reminders = <PantryReminder>[];

        for (final document in snapshot.docs) {
          final data = document.data();
          final remindAt = data['remindAt'];

          if (remindAt is! Timestamp) continue;

          reminders.add(
            PantryReminder(
              id: document.id,
              name: data['name'] as String? ?? 'Unnamed item',
              remindAt: remindAt.toDate(),
            ),
          );
        }

        return reminders;
      })
      .handleError((Object error) {
        debugPrint('Firestore reminder stream ERROR: $error');
      });
}

late final NotificationService notificationService;
late final ExpiryNotificationBinding notificationBinding;

Future<void> startAppServices() async {
  notificationService = await NotificationService.create();

  notificationBinding = ExpiryNotificationBinding(notificationService);

  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user == null) {
      await notificationBinding.stop(clearNotifications: true);
      return;
    }

    await notificationBinding.start(watchPantryReminders(user.uid));
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
      routes: {
        AppRoutes.productDetails: (context) {
          final barcode = ModalRoute.of(context)!.settings.arguments as String;
          return ProductDetailsScreen(barcode: barcode);
        },
        AppRoutes.scanner: (_) => const BarcodeScannerScreen(),
        AppRoutes.history: (_) => const HistoryScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
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
