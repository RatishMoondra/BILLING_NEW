import 'package:flutter/material.dart';

class CustomerInfoForm extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final Function(String) onNameChanged;
  final Function(String) onPhoneChanged;

  const CustomerInfoForm({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.onNameChanged,
    required this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Customer Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
              ),
              onChanged: onNameChanged,
              controller: TextEditingController(text: customerName),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Customer Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: onPhoneChanged,
              controller: TextEditingController(text: customerPhone),
            ),
          ],
        ),
      ),
    );
  }
} 