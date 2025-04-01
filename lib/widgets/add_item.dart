import 'package:flutter/material.dart';
import '../widgets/quantity_stepper.dart';

class AddItemsWidget extends StatefulWidget {
  final String? selectedProductId;
  final List<Map<String, dynamic>> products;
  final int quantity;
  final bool isListening;
  final bool isEditing;
  final VoidCallback? onMicTap;
  final ValueChanged<String?> onProductChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback? onAdd;
  final VoidCallback? onSaveEdit;
  final double? amount;
  final TextEditingController amountController;

  const AddItemsWidget({
    Key? key,
    required this.selectedProductId,
    required this.products,
    required this.quantity,
    required this.onAmountChanged,
    required this.isListening,
    required this.isEditing,
    this.onMicTap,
    required this.onProductChanged,
    required this.onQuantityChanged,
    this.onAdd,
    this.onSaveEdit,
    required this.amount,
    required this.amountController,
  }) : super(key: key);

  @override
  State<AddItemsWidget> createState() => _AddItemsWidgetState();
}

class _AddItemsWidgetState extends State<AddItemsWidget> {
  double? _unitPrice;

  @override
  void initState() {
    super.initState();
    _updateUnitPriceAndAmount();
  }

  @override
  void didUpdateWidget(covariant AddItemsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedProductId != oldWidget.selectedProductId ||
        widget.quantity != oldWidget.quantity) {
      _updateUnitPriceAndAmount();
    }
  }

  void _updateUnitPriceAndAmount() {
  final product = widget.products.firstWhere(
    (p) => p['id'].toString() == widget.selectedProductId,
    orElse: () => <String, dynamic>{},
  );

  final priceRaw = product['price'];
  if (priceRaw == null) {
    _unitPrice = null;
    return;
  }

  _unitPrice = double.tryParse(priceRaw.toString());
  if (_unitPrice == null) return;

  final autoAmount = (_unitPrice! * widget.quantity).toStringAsFixed(2);
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    widget.amountController.text = autoAmount;
    widget.onAmountChanged(autoAmount);
  
  });
}


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(2.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 100,
              maxHeight: constraints.maxHeight * 0.9,
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.isEditing ? 'Edit Item' : 'Add Items',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: widget.selectedProductId,
                            decoration: const InputDecoration(
                              labelText: 'Select Product',
                              border: OutlineInputBorder(),
                            ),
                            items: widget.products.map((product) {
                              return DropdownMenuItem(
                                value: product['id'].toString(),
                                child: Text(product['name'],
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              widget.onProductChanged(value);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _updateUnitPriceAndAmount();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            icon: Icon(widget.isListening
                                ? Icons.mic
                                : Icons.mic_none),
                            tooltip: 'Speak Product Name',
                            onPressed: widget.onMicTap,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_unitPrice != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Unit Price: ₹${_unitPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: QuantityStepper(
                            quantity: widget.quantity,
                            onChanged: (value) {
                              widget.onQuantityChanged(value);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _updateUnitPriceAndAmount();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: widget.amountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: widget.onAmountChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: widget.isEditing
                              ? widget.onSaveEdit
                              : widget.onAdd,
                          icon: Icon(widget.isEditing ? Icons.save : Icons.add),
                          label: Text(widget.isEditing ? 'Save' : 'Add New'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
