import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bill.dart';
import '../../models/bill_item.dart';
import '../../services/supabase_service.dart';

final billProvider = StateNotifierProvider<BillNotifier, BillState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return BillNotifier(supabaseService);
});

class BillState {
  final List<BillItem> items;
  final String customerName;
  final String customerPhone;
  final double totalAmount;
  final bool isLoading;
  final String? error;

  BillState({
    this.items = const [],
    this.customerName = '',
    this.customerPhone = '',
    this.totalAmount = 0.0,
    this.isLoading = false,
    this.error,
  });

  BillState copyWith({
    List<BillItem>? items,
    String? customerName,
    String? customerPhone,
    double? totalAmount,
    bool? isLoading,
    String? error,
  }) {
    return BillState(
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalAmount: totalAmount ?? this.totalAmount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BillNotifier extends StateNotifier<BillState> {
  final SupabaseService _supabaseService;

  BillNotifier(this._supabaseService) : super(BillState());

  void addItem(BillItem item) {
    final updatedItems = [...state.items, item];
    final totalAmount = _calculateTotal(updatedItems);
    state = state.copyWith(
      items: updatedItems,
      totalAmount: totalAmount,
    );
  }

  void removeItem(int index) {
    final updatedItems = List<BillItem>.from(state.items)..removeAt(index);
    final totalAmount = _calculateTotal(updatedItems);
    state = state.copyWith(
      items: updatedItems,
      totalAmount: totalAmount,
    );
  }

  void updateItem(int index, BillItem item) {
    final updatedItems = List<BillItem>.from(state.items);
    updatedItems[index] = item;
    final totalAmount = _calculateTotal(updatedItems);
    state = state.copyWith(
      items: updatedItems,
      totalAmount: totalAmount,
    );
  }

  void updateCustomerInfo({String? name, String? phone}) {
    state = state.copyWith(
      customerName: name ?? state.customerName,
      customerPhone: phone ?? state.customerPhone,
    );
  }

  double _calculateTotal(List<BillItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<bool> saveBill() async {
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Please add at least one item');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final bill = Bill(
        customerName: state.customerName,
        customerPhone: state.customerPhone,
        items: state.items,
        totalAmount: state.totalAmount,
      );

      await _supabaseService.createBill(bill);
      state = BillState(); // Reset state after successful save
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save bill: $e',
      );
      return false;
    }
  }

  void clearBill() {
    state = BillState();
  }
} 