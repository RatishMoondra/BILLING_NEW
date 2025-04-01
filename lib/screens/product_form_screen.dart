import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../providers/supabase_provider.dart';
import '../config/env_config.dart';
import '../services/logging_service.dart';


class ProductFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? product;

  const ProductFormScreen({
    super.key,
    this.product,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String? _imageUrl;
  File? _selectedImage;
  final LoggingService _logger = LoggingService();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'];
      _priceController.text = widget.product!['price'].toString();
      _imageUrl = widget.product!['image_url'];
    }
  }



  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!EnvConfig.enableImageUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload is disabled')),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: EnvConfig.thumbnailSize.toDouble(),
        maxHeight: EnvConfig.thumbnailSize.toDouble(),
        imageQuality: EnvConfig.imageQuality,
      );

      if (image != null) {
        final fileSize = await File(image.path).length();
        if (fileSize > EnvConfig.maxImageSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image size must be less than ${EnvConfig.maxImageSize ~/ 1024}KB'),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadImage();
        await _logger.debug('Image picked successfully: ${image.path}');
      }
    } catch (e, stackTrace) {
      await _logger.error('Failed to pick image', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(_selectedImage!.path)}';
      final filePath = 'product_images/$fileName';

      // Upload image to Supabase storage
      await supabaseService.uploadFile(
        filePath: filePath,
        file: _selectedImage!,
      );

      // Get the public URL
      final imageUrl = await supabaseService.getPublicUrl(filePath);

      setState(() {
        _imageUrl = imageUrl;
      });
      await _logger.info('Image uploaded successfully: $filePath');
    } catch (e, stackTrace) {
      await _logger.error('Failed to upload image', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final supabaseService = ref.read(supabaseServiceProvider);
      final productData = {
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'image_url': _imageUrl,
      };

      try {
        if (widget.product != null) {
          await supabaseService.updateProduct(widget.product!['id'], productData);
          await _logger.info('Updated product: ${widget.product!['id']}');
        } else {
          final newProduct = await supabaseService.createProduct(productData);
          await _logger.info('Created new product: ${newProduct['id']}');
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e, stackTrace) {
        await _logger.error('Failed to save product', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving product: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: _imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageUrl == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 64,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'Enter product name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                hintText: 'Enter product price',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProduct,
              child: Text(widget.product == null ? 'Add Product' : 'Update Product'),
            ),
          ],
        ),
      ),
    );
  }
}
