import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/supabase_provider.dart';
import '../services/logging_service.dart';
import '../utils/formatter.dart';
import '../config/env_config.dart';

class BillHistoryScreen extends ConsumerStatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  ConsumerState<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends ConsumerState<BillHistoryScreen> {
  final _searchController = TextEditingController();
  final LoggingService _logger = LoggingService();
  List<ScanResult> _devices = [];
  ScanResult? _selectedPrinter;
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  List<Map<String, dynamic>> _bills = [];
  List<Map<String, dynamic>> _filteredBills = [];
  String? _searchQuery;
  Set<String> _selectedBillIds = {};

  @override
  void initState() {
    super.initState();
    _loadBills();
    _startScanningDevices();
  }

  Future<void> _startScanningDevices() async {
    try {
      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      
      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) async {
        setState(() {
          _devices = results;
        });
        await _logger.debug('Found ${results.length} devices');
      });
    } catch (e, stackTrace) {
      await _logger.error('Failed to scan devices', e, stackTrace);
    }
  }

  Future<void> _printBill(Map<String, dynamic> bill) async {
    if (_selectedPrinter == null) {
      await _showPrinterSelectionDialog();
      if (_selectedPrinter == null) return;
    }

    try {
      setState(() => _isLoading = true);
      
      // Connect to the printer
      await _selectedPrinter!.device.connect();
      
      // Get the characteristic for writing data
      final services = await _selectedPrinter!.device.discoverServices();
      final characteristic = services
          .expand((s) => s.characteristics)
          .firstWhere((c) => c.properties.write);

      // Prepare the receipt data
      final receiptData = StringBuffer();
      
      // Header
      receiptData.writeln('BILL RECEIPT');
      receiptData.writeln('Date: ${bill['created_at']}');
      receiptData.writeln('Bill No: ${bill['id']}');
      receiptData.writeln('--------------------------------');
      
      // Items
      List<dynamic> items = bill['items'] ?? [];
      for (var item in items) {
        receiptData.writeln(item['product_name']);
        receiptData.writeln('Qty: ${item['quantity']} x ${item['price']}');
        receiptData.writeln('Total: ${item['quantity'] * item['price']}');
      }
      
      receiptData.writeln('--------------------------------');
      receiptData.writeln('Total Amount: ${bill['total_amount']}');
      receiptData.writeln('Thank you for your business!');
      receiptData.writeln('\n\n\n'); // Feed paper
      
      // Convert to bytes and write to printer
      final bytes = receiptData.toString().codeUnits;
      await characteristic.write(bytes);
      
      // Disconnect
      await _selectedPrinter!.device.disconnect();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill printed successfully')),
        );
      }
    } catch (e, stackTrace) {
      await _logger.error('Failed to print bill', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing bill: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPrinterSelectionDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Printer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return ListTile(
                title: Text(device.device.name.isEmpty ? 'Unknown Device' : device.device.name),
                subtitle: Text(device.device.id.id),
                onTap: () {
                  setState(() => _selectedPrinter = device);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _startScanningDevices,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBills() async {
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final bills = await supabaseService.getBills();
      setState(() {
        _bills = bills;
        _filteredBills = bills;
      });
      await _logger.debug('Loaded ${bills.length} bills');
    } catch (e, stackTrace) {
      await _logger.error('Failed to load bills', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bills: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredBills = _bills.where((bill) {
        final matchesSearch = _searchController.text.isEmpty ||
            bill['customer_name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
            bill['id'].toString().contains(_searchController.text);

        final matchesDateRange = (_startDate == null || DateTime.parse(bill['created_at']).isAfter(_startDate!)) &&
            (_endDate == null || DateTime.parse(bill['created_at']).isBefore(_endDate!));

        final amount = double.parse(bill['total_amount'].toString());
        final matchesAmountRange = (_minAmount == null || amount >= _minAmount!) &&
            (_maxAmount == null || amount <= _maxAmount!);

        return matchesSearch && matchesDateRange && matchesAmountRange;
      }).toList();
    });
  }

  void _showAmountRangePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Amount Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum Amount',
                prefixText: '₹',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _minAmount = double.tryParse(value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum Amount',
                prefixText: '₹',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _maxAmount = double.tryParse(value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _minAmount = null;
                _maxAmount = null;
              });
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showBillDetails(Map<String, dynamic> bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bill #${bill['id'].toString().substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${bill['customer_name'] ?? 'N/A'}'),
              Text('Date: ${Formatter.formatDate(DateTime.parse(bill['created_at']))}'),
              Text('Total Amount: ${Formatter.formatCurrency(double.parse(bill['total_amount'].toString()))}'),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: ref.read(supabaseServiceProvider).getBillItems(bill['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    _logger.error('Failed to load bill items for bill: ${bill['id']}', snapshot.error);
                    return Text('Error: ${snapshot.error}');
                  }
                  final items = snapshot.data ?? [];
                  return Column(
                    children: items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${item['products']?['name']} x ${item['quantity']} - ${Formatter.formatCurrency(double.parse(item['price'].toString()))}',
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedBills() async {
    if (_selectedBillIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Bills'),
        content: Text('Are you sure you want to delete ${_selectedBillIds.length} selected bill(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final supabaseService = ref.read(supabaseServiceProvider);
        for (final billId in _selectedBillIds) {
          await supabaseService.deleteBill(billId);
          await _logger.info('Deleted bill: $billId');
        }
        setState(() {
          _selectedBillIds.clear();
        });
        _loadBills();
      } catch (e, stackTrace) {
        await _logger.error('Failed to delete selected bills', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting bills: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
        actions: [
          if (_selectedBillIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedBills,
              tooltip: 'Delete Selected Bills',
            ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _devices.isEmpty ? _startScanningDevices : null,
            tooltip: 'Connect Printer',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Filter Bills'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Date Range'),
                        subtitle: Text(
                          _startDate != null && _endDate != null
                              ? '${Formatter.formatDate(_startDate!)} - ${Formatter.formatDate(_endDate!)}'
                              : 'Select date range',
                        ),
                        onTap: () async {
                          try {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (range != null) {
                              setState(() {
                                _startDate = range.start;
                                _endDate = range.end;
                              });
                              _applyFilters();
                              await _logger.debug('Applied date range filter: ${Formatter.formatDate(range.start)} - ${Formatter.formatDate(range.end)}');
                            }
                          } catch (e, stackTrace) {
                            await _logger.error('Failed to select date range', e, stackTrace);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error selecting date range: $e')),
                              );
                            }
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('Amount Range'),
                        subtitle: Text(
                          _minAmount != null && _maxAmount != null
                              ? '${Formatter.formatCurrency(_minAmount!)} - ${Formatter.formatCurrency(_maxAmount!)}'
                              : 'Select amount range',
                        ),
                        onTap: _showAmountRangePicker,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _minAmount = null;
                          _maxAmount = null;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                        _logger.debug('Cleared all filters');
                      },
                      child: const Text('Clear All'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    hintText: 'Search bills...',
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(
                        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                        end: _endDate ?? DateTime.now(),
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredBills.isEmpty
                ? const Center(
                    child: Text('No bills found.'),
                  )
                : ListView.builder(
                    itemCount: _filteredBills.length,
                    itemBuilder: (context, index) {
                      final bill = _filteredBills[index];
                      final isSelected = _selectedBillIds.contains(bill['id'].toString());
                      return ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedBillIds.add(bill['id'].toString());
                              } else {
                                _selectedBillIds.remove(bill['id'].toString());
                              }
                            });
                          },
                        ),
                        title: Text('Bill #${bill['id'].toString().substring(0, 8)}'),
                        subtitle: Text(
                          '${bill['customer_name'] ?? 'N/A'} - ${Formatter.formatDate(DateTime.parse(bill['created_at']))}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatter.formatCurrency(double.parse(bill['total_amount'].toString())),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.print),
                              onPressed: _isLoading ? null : () => _printBill(bill),
                              tooltip: 'Print Bill',
                            ),
                          ],
                        ),
                        onTap: () => _showBillDetails(bill),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 