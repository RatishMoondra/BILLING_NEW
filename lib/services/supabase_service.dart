import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../config/env_config.dart';
import 'logging_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  final LoggingService _logger = LoggingService();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() {
    _client = Supabase.instance.client;
  }

  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
      await LoggingService().info('Supabase initialized successfully');
    } catch (e, stackTrace) {
      await LoggingService().critical('Failed to initialize Supabase', e, stackTrace);
      rethrow;
    }
  }

  // File Storage
  Future<void> uploadFile({
    required String filePath,
    required File file,
  }) async {
    try {
      await _client.storage
          .from('product-images')
          .upload(filePath, file);
      await _logger.info('File uploaded successfully: $filePath');
    } catch (e, stackTrace) {
      await _logger.error('Failed to upload file: $filePath', e, stackTrace);
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<String> getPublicUrl(String filePath) async {
    try {
      final url = _client.storage
          .from('product-images')
          .getPublicUrl(filePath);
      await _logger.debug('Got public URL for file: $filePath');
      return url;
    } catch (e, stackTrace) {
      await _logger.error('Failed to get public URL for file: $filePath', e, stackTrace);
      throw Exception('Failed to get public URL: $e');
    }
  }

  // Products
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .order('created_at', ascending: false);
      await _logger.debug('Retrieved ${response.length} products');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      await _logger.error('Failed to get products', e, stackTrace);
      throw Exception('Failed to get products: $e');
    }
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', id)
          .single();
      await _logger.debug('Retrieved product: $id');
      return response;
    } catch (e, stackTrace) {
      await _logger.error('Failed to get product: $id', e, stackTrace);
      throw Exception('Failed to get product: $e');
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product) async {
    try {
      final response = await _client
          .from('products')
          .insert(product)
          .select()
          .single();
      await _logger.info('Created new product: ${response['id']}');
      return response;
    } catch (e, stackTrace) {
      await _logger.error('Failed to create product', e, stackTrace);
      throw Exception('Failed to create product: $e');
    }
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> product) async {
    try {
      final response = await _client
          .from('products')
          .update(product)
          .eq('id', id)
          .select()
          .single();
      await _logger.info('Updated product: $id');
      return response;
    } catch (e, stackTrace) {
      await _logger.error('Failed to update product: $id', e, stackTrace);
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _client
          .from('products')
          .delete()
          .eq('id', id);
      await _logger.info('Deleted product: $id');
    } catch (e, stackTrace) {
      await _logger.error('Failed to delete product: $id', e, stackTrace);
      throw Exception('Failed to delete product: $e');
    }
  }

  // Categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('name', ascending: true);
      await _logger.debug('Retrieved ${response.length} categories');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      await _logger.error('Failed to get categories', e, stackTrace);
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> category) async {
    try {
      final response = await _client
          .from('categories')
          .insert(category)
          .select()
          .single();
      await _logger.info('Created new category: ${response['id']}');
      return response;
    } catch (e, stackTrace) {
      await _logger.error('Failed to create category', e, stackTrace);
      throw Exception('Failed to create category: $e');
    }
  }

  Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> category) async {
    try {
      final response = await _client
          .from('categories')
          .update(category)
          .eq('id', id)
          .select()
          .single();
      await _logger.info('Updated category: $id');
      return response;
    } catch (e, stackTrace) {
      await _logger.error('Failed to update category: $id', e, stackTrace);
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _client
          .from('categories')
          .delete()
          .eq('id', id);
      await _logger.info('Deleted category: $id');
    } catch (e, stackTrace) {
      await _logger.error('Failed to delete category: $id', e, stackTrace);
      throw Exception('Failed to delete category: $e');
    }
  }

  // Bills
  Future<List<Map<String, dynamic>>> getBills() async {
    try {
      final response = await _client
          .from('bills')
          .select()
          .order('created_at', ascending: false);
      await _logger.debug('Retrieved ${response.length} bills');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      await _logger.error('Failed to get bills', e, stackTrace);
      throw Exception('Failed to get bills: $e');
    }
  }

  Future<Map<String, dynamic>> getBill(String id) async {
    try {
      final response = await _client
          .from('bills')
          .select()
          .eq('id', id)
          .single();
      await _logger.debug('Retrieved bill: $id');
      return response;
    } catch (e, stackTrace) {
      await _logger.error('Failed to get bill: $id', e, stackTrace);
      throw Exception('Failed to get bill: $e');
    }
  }

  Future<Map<String, dynamic>> createBill(Map<String, dynamic> bill) async {
    try {
      final response = await _client
          .from('bills')
          .insert(bill)
          .select()
          .single();
      await _logger.info('Created new bill: ${response['id']}');
      return response;
    } catch (e, stackTrace) {
      await _logger.error('Failed to create bill', e, stackTrace);
      throw Exception('Failed to create bill: $e');
    }
  }

  Future<Map<String, dynamic>> updateBill(String id, Map<String, dynamic> bill) async {
    try {
      final response = await _client
          .from('bills')
          .update(bill)
          .eq('id', id)
          .select()
          .single();
      await _logger.info('Updated bill: $id');
      return response;
    } catch (e, stackTrace) {
      await _logger.error('Failed to update bill: $id', e, stackTrace);
      throw Exception('Failed to update bill: $e');
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      await _client
          .from('bills')
          .delete()
          .eq('id', id);
      await _logger.info('Deleted bill: $id');
    } catch (e, stackTrace) {
      await _logger.error('Failed to delete bill: $id', e, stackTrace);
      throw Exception('Failed to delete bill: $e');
    }
  }

  // Bill Items
  Future<List<Map<String, dynamic>>> getBillItems(String billId) async {
    try {
      final response = await _client
          .from('bill_items')
          .select('id, quantity, price, product_id, products(name)')
          .eq('bill_id', billId);
      print('RATISH MOONDRA:: getBillItems :: $response');
      await _logger.debug('Retrieved items for bill: $billId');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      await _logger.error('Failed to get bill items for bill: $billId', e, stackTrace);
      throw Exception('Failed to get bill items: $e');
    }
  }

  Future<Map<String, dynamic>> createBillItem(Map<String, dynamic> billItem) async {
    try {
      final response = await _client
          .from('bill_items')
          .insert(billItem)
          .select()
          .single();
      await _logger.info('Created new bill item: ${response['id']}');
      return response;
    } catch (e, stackTrace) {
      await _logger.error('Failed to create bill item', e, stackTrace);
      throw Exception('Failed to create bill item: $e');
    }
  }

  Future<void> deleteBillItem(String id) async {
    try {
      await _client
          .from('bill_items')
          .delete()
          .eq('id', id);
      await _logger.info('Deleted bill item: $id');
    } catch (e, stackTrace) {
      await _logger.error('Failed to delete bill item: $id', e, stackTrace);
      throw Exception('Failed to delete bill item: $e');
    }
  }

  // Settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _client
          .from('settings')
          .select()
          .single();
      await _logger.debug('Retrieved settings');
      return response;
    } catch (e, stackTrace) {
      await _logger.error('Failed to load settings', e, stackTrace);
      throw Exception('Failed to load settings: $e');
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    try {
      await _client
          .from('settings')
          .update({key: value})
          .eq('id', 1);
      await _logger.info('Updated setting: $key -> $value');
    } catch (e, stackTrace) {
      await _logger.error('Failed to update setting: $key', e, stackTrace);
      throw Exception('Failed to update setting: $e');
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      await _client
          .from('settings')
          .update(settings)
          .eq('id', 1);
      await _logger.info('Updated settings');
    } catch (e, stackTrace) {
      await _logger.error('Failed to update settings', e, stackTrace);
      throw Exception('Failed to update settings: $e');
    }
  }
} 