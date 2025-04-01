import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Company Information
  static String get companyName => dotenv.env['COMPANY_NAME'] ?? 'Your Company Name';
  static String get companyAddress => dotenv.env['COMPANY_ADDRESS'] ?? 'Your Company Address';
  static String get companyPhone => dotenv.env['COMPANY_PHONE'] ?? 'Your Company Phone';
  static String get companyEmail => dotenv.env['COMPANY_EMAIL'] ?? 'your@email.com';
  static String get companyWebsite => dotenv.env['COMPANY_WEBSITE'] ?? 'www.yourcompany.com';
  static String get companyGstNumber => dotenv.env['COMPANY_GST_NUMBER'] ?? '';
  static String get companyPanNumber => dotenv.env['COMPANY_PAN_NUMBER'] ?? '';

  // Developer Information
  static String get developerEmail => dotenv.env['DEVELOPER_EMAIL'] ?? 'developer@example.com';

  // App Settings
  static String get appName => dotenv.env['APP_NAME'] ?? 'Billing App';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get defaultCurrency => dotenv.env['DEFAULT_CURRENCY'] ?? 'INR';
  static String get defaultCurrencySymbol => dotenv.env['DEFAULT_CURRENCY_SYMBOL'] ?? '₹';
  static String get defaultDateFormat => dotenv.env['DEFAULT_DATE_FORMAT'] ?? 'dd/MM/yyyy';
  static String get defaultTimeFormat => dotenv.env['DEFAULT_TIME_FORMAT'] ?? 'HH:mm';

  // Storage Settings
  static int get maxImageSize => int.tryParse(dotenv.env['MAX_IMAGE_SIZE'] ?? '1048576') ?? 1048576;
  static int get imageQuality => int.tryParse(dotenv.env['IMAGE_QUALITY'] ?? '80') ?? 80;
  static int get thumbnailSize => int.tryParse(dotenv.env['THUMBNAIL_SIZE'] ?? '200') ?? 200;

  // API Settings
  static int get apiTimeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;
  static int get maxRetryAttempts => int.tryParse(dotenv.env['MAX_RETRY_ATTEMPTS'] ?? '3') ?? 3;

  // Feature Flags
  static bool get enableWhatsappSharing => dotenv.env['ENABLE_WHATSAPP_SHARING']?.toLowerCase() == 'true';
  static bool get enablePrinting => dotenv.env['ENABLE_PRINTING']?.toLowerCase() == 'true';
  static bool get enableImageUpload => dotenv.env['ENABLE_IMAGE_UPLOAD']?.toLowerCase() == 'true';
  static bool get enableOfflineMode => dotenv.env['ENABLE_OFFLINE_MODE']?.toLowerCase() == 'true';
} 