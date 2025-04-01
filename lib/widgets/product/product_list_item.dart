import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../services/logging_service.dart';
import '../product/product_form_screen.dart';

class ProductListItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDelete;
  final LoggingService _logger = LoggingService();

  ProductListItem({
    super.key,
    required this.product,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _navigateToEdit(context),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => _showDeleteConfirmation(context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        leading: _buildProductImage(context),
        title: Text(product['name']),
        subtitle: Text('₹${double.parse(product['price'].toString()).toStringAsFixed(2)}'),
        onTap: () => _navigateToEdit(context),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    if (product['image_url'] != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(product['image_url']),
        onBackgroundImageError: (_, __) async {
          await _logger.warning('Failed to load product image: ${product['image_url']}');
        },
      );
    }
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.inventory, color: Colors.white),
    );
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductFormScreen(product: product),
        ),
      );
      await _logger.debug('Navigated to edit product: ${product['name']}');
    } catch (e, stackTrace) {
      await _logger.error('Failed to navigate to edit product: ${product['name']}', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 