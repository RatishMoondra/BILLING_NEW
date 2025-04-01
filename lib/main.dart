import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/dashboard_screen.dart';
import 'screens/product_catalog_screen.dart';
import 'screens/create_bill_screen.dart';
import 'screens/bill_history_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/constants.dart';
import 'services/supabase_service.dart';
import 'services/logging_service.dart';
import 'config/env_config.dart';

void main() async {
  final logger = LoggingService();
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await logger.info('App initialization started');

    // Load environment variables
    await dotenv.load(fileName: ".env");
    await logger.info('Environment variables loaded');

    // Initialize Supabase
    await SupabaseService.initialize();
    await logger.info('Supabase initialized');

    runApp(
      const ProviderScope(
        child: BillingApp(),
      ),
    );
  } catch (e, stackTrace) {
    await logger.critical('Failed to initialize app', e, stackTrace);
    rethrow;
  }
}

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EnvConfig.appName,
      theme: AppConstants.lightTheme,
      darkTheme: AppConstants.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/catalog': (context) => const ProductCatalogScreen(),
        '/billing': (context) => const CreateBillScreen(),
        '/history': (context) => const BillHistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
