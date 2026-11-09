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
  runApp(const MyApp());
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
        AppRoutes.productDetails: (_) => const ProductDetailsScreen(),
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
        return user == null ? const SignInScreen() : BottomNav(user: user);
      },
    );
  }
}
/*








*/

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
