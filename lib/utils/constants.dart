import 'package:flutter/material.dart';

class AppConstants {
  // Database
  static const String dbName = 'billing.db';
  static const String tableCategories = 'categories';
  static const String tableProducts = 'products';
  static const String tableBills = 'bills';
  static const String tableBillItems = 'bill_items';

  // Theme
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );

  // Validation
  static const phoneNumberLength = 10;
  static const minQuantity = 1;
  static const minPrice = 0.01;

  // Image
  static const maxImageSize = 1024 * 1024; // 1MB
  static const imageQuality = 80;
  static const thumbnailSize = 200;
}
