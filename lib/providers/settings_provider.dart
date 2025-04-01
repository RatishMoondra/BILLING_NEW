import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../services/logging_service.dart';
import 'supabase_provider.dart';

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final SupabaseService _supabaseService;
  final LoggingService _logger = LoggingService();

  SettingsNotifier(this._supabaseService) : super({}) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final settings = await _supabaseService.getSettings();
      state = settings;
      await _logger.logInfo('Settings loaded successfully');
    } catch (e) {
      await _logger.logError('Error loading settings', e);
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    try {
      await _supabaseService.updateSetting(key, value);
      state = {...state, key: value};
      await _logger.logInfo('Setting updated successfully: $key -> $value');
    } catch (e) {
      await _logger.logError('Error updating setting', e);
    }
  }

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    try {
      await _supabaseService.updateSettings(newSettings);
      state = {...state, ...newSettings};
      await _logger.logInfo('Settings updated successfully');
    } catch (e) {
      await _logger.logError('Error updating settings', e);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return SettingsNotifier(supabaseService);
}); 