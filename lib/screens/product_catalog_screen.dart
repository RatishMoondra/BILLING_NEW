import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/supabase_provider.dart';
import '../providers/category_provider.dart';
import '../services/logging_service.dart';
import 'product_form_screen.dart';


class ProductCatalogScreen extends ConsumerStatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  ConsumerState<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends ConsumerState<ProductCatalogScreen> {
  List<Map<String, dynamic>> _products = [];
  String _searchQuery = '';
  String? _selectedCategoryId;
  final LoggingService _logger = LoggingService();

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

  List<Map<String, dynamic>> get filteredProducts {
    return _products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }

  void _showCategoryFilter() {
    final categories = ref.watch(categoryProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Categories'),
                selected: _selectedCategoryId == null,
                onTap: () {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ...categories.map((category) => ListTile(
                title: Text(category['name']),
                selected: _selectedCategoryId == category['id'].toString(),
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category['id'].toString();
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showCategoryFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: 'Search products...',
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text('No products found. Add some products to get started.'),
                  )
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductListItem(
                        product: product,
                        onDelete: () async {
                          try {
                            final supabaseService = ref.read(supabaseServiceProvider);
                            await supabaseService.deleteProduct(product['id']);
                            await _logger.info('Deleted product: ${product['name']}');
                            if (mounted) {
                              _loadProducts();
                            }
                          } catch (e, stackTrace) {
                            await _logger.error('Failed to delete product: ${product['name']}', e, stackTrace);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error deleting product: $e')),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductFormScreen(),
              ),
            );
            _loadProducts();
          } catch (e, stackTrace) {
            await _logger.error('Failed to navigate to product form', e, stackTrace);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

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
            onPressed: (_) async {
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
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) {
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
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        leading: product['image_url'] != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(product['image_url']),
                onBackgroundImageError: (_, __) async {
                  await _logger.warning('Failed to load product image: ${product['image_url']}');
                },
              )
            : CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.inventory, color: Colors.white),
              ),
        title: Text(product['name']),
        subtitle: Text('₹${double.parse(product['price'].toString()).toStringAsFixed(2)}'),
        onTap: () async {
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
        },
      ),
    );
  }
}
