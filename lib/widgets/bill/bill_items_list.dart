import 'package:flutter/material.dart';
import '../../models/bill_item.dart';

class BillItemsList extends StatelessWidget {
  final List<BillItem> items;
  final Function(int) onRemoveItem;
  final Function(int, BillItem) onUpdateItem;

  const BillItemsList({
    super.key,
    required this.items,
    required this.onRemoveItem,
    required this.onUpdateItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(item.productName),
            subtitle: Text('₹${item.price.toStringAsFixed(2)} x ${item.quantity}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(context, index, item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => onRemoveItem(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, int index, BillItem item) {
    final quantityController = TextEditingController(text: item.quantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${item.productName}'),
            Text('Price: ₹${item.price.toStringAsFixed(2)}'),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newQuantity = int.tryParse(quantityController.text);
              if (newQuantity != null && newQuantity > 0) {
                onUpdateItem(
                  index,
                  item.copyWith(quantity: newQuantity),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 