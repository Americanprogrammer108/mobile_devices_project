import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;

// import 'package:mobile_devices_project/screens/pantry_screen.dart';
// import 'package:mobile_devices_project/screens/product_lookup_page.dart';
// import 'package:mobile_devices_project/screens/sign_in.dart';
import 'firebase_options.dart';
import 'routing/app_routes.dart';
import 'theme/app_theme.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  off.OpenFoodAPIConfiguration.userAgent = off.UserAgent(
    name: 'MyFoodApp',
    url: 'https://myfoodapp.example.com', // or an email contact
  );
  off.OpenFoodAPIConfiguration.globalLanguages = [off.OpenFoodFactsLanguage.ENGLISH];
  off.OpenFoodAPIConfiguration.globalCountry = off.OpenFoodFactsCountry.USA;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartPantryApp());
}

class SmartPantryApp extends StatelessWidget {
  const SmartPantryApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Pantry',
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
