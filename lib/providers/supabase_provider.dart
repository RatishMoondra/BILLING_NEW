import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// // Products
// final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
//   final supabaseService = ref.watch(supabaseServiceProvider);
//   return await supabaseService.getProducts();
// });

// // Bills
// final billsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
//   final supabaseService = ref.watch(supabaseServiceProvider);
//   return await supabaseService.getBills();
// });

// // Settings
// final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
//   final supabaseService = ref.watch(supabaseServiceProvider);
//   return await supabaseService.getSettings();
// }); 