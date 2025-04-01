import 'package:flutter/material.dart';
import '../../models/bill_item.dart';

class AddItemWidget extends StatelessWidget {
  final Function(BillItem) onAddItem;
  final List<Map<String, dynamic>> products;

  const AddItemWidget({
    super.key,
    required this.onAddItem,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: const InputDecoration(
                labelText: 'Select Product',
                border: OutlineInputBorder(),
              ),
              items: products.map((product) {
                return DropdownMenuItem(
                  value: product,
                  child: Text(product['name']),
                );
              }).toList(),
              onChanged: (product) {
                if (product != null) {
                  _showQuantityDialog(context, product);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, Map<String, dynamic> product) {
    final quantityController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${product['name']}'),
            Text('Price: ₹${product['price']}'),
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
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                onAddItem(
                  BillItem(
                    productId: product['id'].toString(),
                    productName: product['name'],
                    price: double.parse(product['price'].toString()),
                    quantity: quantity,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 