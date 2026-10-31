import 'package:flutter/material.dart';

import 'routing/app_routes.dart';
import 'theme/app_theme.dart';

void main() {
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