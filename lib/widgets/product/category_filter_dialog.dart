import 'package:flutter/material.dart';

class CategoryFilterDialog extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const CategoryFilterDialog({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Categories'),
              selected: selectedCategoryId == null,
              onTap: () {
                onCategorySelected(null);
                Navigator.pop(context);
              },
            ),
            ...categories.map((category) => ListTile(
              title: Text(category['name']),
              selected: selectedCategoryId == category['id'].toString(),
              onTap: () {
                onCategorySelected(category['id'].toString());
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
} 