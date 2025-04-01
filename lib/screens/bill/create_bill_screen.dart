import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bill/bill_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/bill/add_item_widget.dart';
import '../../widgets/bill/bill_items_list.dart';
import '../../widgets/bill/bill_summary.dart';
import '../../widgets/bill/customer_info_form.dart';
import '../../services/logging_service.dart';

class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({super.key});

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<CreateBillScreen> {
  final LoggingService _logger = LoggingService();
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final products = await supabaseService.getProducts();
      setState(() {
        _products = products;
      });
      await _logger.debug('Loaded ${products.length} products');
    } catch (e, stackTrace) {
      await _logger.error('Failed to load products', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billState = ref.watch(billProvider);
    final billNotifier = ref.read(billProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              billNotifier.clearBill();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bill cleared')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CustomerInfoForm(
              customerName: billState.customerName,
              customerPhone: billState.customerPhone,
              onNameChanged: (name) => billNotifier.updateCustomerInfo(name: name),
              onPhoneChanged: (phone) => billNotifier.updateCustomerInfo(phone: phone),
            ),
            AddItemWidget(
              products: _products,
              onAddItem: billNotifier.addItem,
            ),
            if (billState.items.isNotEmpty) ...[
              BillItemsList(
                items: billState.items,
                onRemoveItem: billNotifier.removeItem,
                onUpdateItem: billNotifier.updateItem,
              ),
              BillSummary(
                totalAmount: billState.totalAmount,
                isLoading: billState.isLoading,
                onSave: () async {
                  final success = await billNotifier.saveBill();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bill saved successfully')),
                    );
                    Navigator.pop(context);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(billState.error ?? 'Failed to save bill')),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
} 