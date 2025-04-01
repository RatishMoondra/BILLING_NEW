import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../services/logging_service.dart';
import 'supabase_provider.dart';

class CategoryNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final SupabaseService _supabaseService;
  final LoggingService _logger = LoggingService();

  CategoryNotifier(this._supabaseService) : super([]) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _supabaseService.getCategories();
      state = categories;
      await _logger.logInfo('Categories loaded successfully');
    } catch (e) {
      await _logger.logError('Error loading categories', e);
    }
  }

  Future<void> addCategory(String name) async {
    try {
      await _supabaseService.createCategory({
        'name': name,
      });
      await loadCategories();
      await _logger.logInfo('Category added successfully: $name');
    } catch (e) {
      await _logger.logError('Error adding category', e);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _supabaseService.deleteCategory(id);
      await loadCategories();
      await _logger.logInfo('Category deleted successfully: $id');
    } catch (e) {
      await _logger.logError('Error deleting category', e);
    }
  }

  Future<void> updateCategory(String id, String name) async {
    try {
      await _supabaseService.updateCategory(id, {
        'name': name,
      });
      await loadCategories();
      await _logger.logInfo('Category updated successfully: $id -> $name');
    } catch (e) {
      await _logger.logError('Error updating category', e);
    }
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Map<String, dynamic>>>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return CategoryNotifier(supabaseService);
}); 