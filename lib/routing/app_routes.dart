// Open a screen from anywhere:
//    Navigator.pushNamed(context, AppRoutes.settings);
//    Navigator.pushNamed(context, AppRoutes.productDetails, arguments: barcode);

import 'package:flutter/material.dart';

import '../bottom_nav.dart';
import '../features/barcode_scanner/barcode_scanner_screen.dart';
import '../features/history/history_screen.dart';
import '../features/product_details/product_details_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRoutes {
  static const home = '/';
  static const productDetails = '/product-details';
  static const scanner = '/scanner';
  static const history = '/history';
  static const settings = '/settings';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const BottomNav(),
    productDetails: (_) => const ProductDetailsScreen(),
    scanner: (_) => const BarcodeScannerScreen(),
    history: (_) => const HistoryScreen(),
    settings: (_) => const SettingsScreen(),
  };
}


