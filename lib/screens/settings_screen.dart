import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/supabase_provider.dart';
import '../services/logging_service.dart';
import 'log_viewer_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _categoryController = TextEditingController();
  final LoggingService _logger = LoggingService();
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await ref.read(supabaseServiceProvider).getCategories();
      setState(() {
        _categories = categories;
      });
      await _logger.debug('Loaded ${categories.length} categories');
    } catch (e, stackTrace) {
      await _logger.error('Failed to load categories', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.isEmpty) return;

    try {
      await ref.read(supabaseServiceProvider).createCategory({
        'name': _categoryController.text,
      });
      await _logger.info('Added new category: ${_categoryController.text}');
      _categoryController.clear();
      _loadData();
    } catch (e, stackTrace) {
      await _logger.error('Failed to add category', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding category: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    try {
      await ref.read(supabaseServiceProvider).deleteCategory(category['id']);
      await _logger.info('Deleted category: ${category['name']}');
      _loadData();
    } catch (e, stackTrace) {
      await _logger.error('Failed to delete category', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting category: $e')),
        );
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await ref.read(settingsProvider.notifier).updateSetting(key, value);
      await _logger.debug('Updated setting: $key -> $value');
    } catch (e, stackTrace) {
      await _logger.error('Failed to update setting: $key', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating setting: $e')),
        );
      }
    }
  }

  Future<void> _navigateToLogs() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LogViewerScreen(),
        ),
      );
      await _logger.debug('Navigated to log viewer');
    } catch (e, stackTrace) {
      await _logger.error('Failed to navigate to log viewer', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Printer Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Printer Type'),
            subtitle: Text(settings['printer_type'] ?? 'Not set'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Printer Type'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Bluetooth'),
                        onTap: () {
                          _updateSetting('printer_type', 'Bluetooth');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('WiFi'),
                        onTap: () {
                          _updateSetting('printer_type', 'WiFi');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Theme Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings['is_dark_mode'] ?? false,
            onChanged: (value) {
              _updateSetting('is_dark_mode', value);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Category',
                      hintText: 'Enter category name',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addCategory,
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return ListTile(
                title: Text(category['name']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteCategory(category),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Developer Tools',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('View Logs'),
            subtitle: const Text('View application logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToLogs,
          ),
        ],
      ),
    );
  }
} 