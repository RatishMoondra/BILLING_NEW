import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bill.dart';
import '../../services/supabase_service.dart';
import '../../services/logging_service.dart';

final billHistoryProvider = StateNotifierProvider<BillHistoryNotifier, BillHistoryState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return BillHistoryNotifier(supabaseService);
});

class BillHistoryState {
  final List<Bill> bills;
  final bool isLoading;
  final String? error;
  final DateTime? startDate;
  final DateTime? endDate;

  BillHistoryState({
    this.bills = const [],
    this.isLoading = false,
    this.error,
    this.startDate,
    this.endDate,
  });

  BillHistoryState copyWith({
    List<Bill>? bills,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BillHistoryState(
      bills: bills ?? this.bills,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  List<Bill> get filteredBills {
    return bills.where((bill) {
      if (startDate != null && bill.createdAt.isBefore(startDate!)) return false;
      if (endDate != null && bill.createdAt.isAfter(endDate!)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

class BillHistoryNotifier extends StateNotifier<BillHistoryState> {
  final SupabaseService _supabaseService;
  final LoggingService _logger = LoggingService();

  BillHistoryNotifier(this._supabaseService) : super(BillHistoryState());

  Future<void> loadBills() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bills = await _supabaseService.getBills();
      state = state.copyWith(
        bills: bills,
        isLoading: false,
      );
      await _logger.debug('Loaded ${bills.length} bills');
    } catch (e, stackTrace) {
      await _logger.error('Failed to load bills', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load bills: $e',
      );
    }
  }

  void updateDateRange({DateTime? startDate, DateTime? endDate}) {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<bool> deleteBill(String billId) async {
    try {
      await _supabaseService.deleteBill(billId);
      final updatedBills = List<Bill>.from(state.bills)
        ..removeWhere((bill) => bill.id == billId);
      state = state.copyWith(bills: updatedBills);
      await _logger.info('Deleted bill: $billId');
      return true;
    } catch (e, stackTrace) {
      await _logger.error('Failed to delete bill: $billId', e, stackTrace);
      state = state.copyWith(error: 'Failed to delete bill: $e');
      return false;
    }
  }
} 