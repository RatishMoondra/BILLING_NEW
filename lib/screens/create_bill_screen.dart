import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/supabase_provider.dart';
import '../widgets/bill_item_grid.dart';
import '../utils/formatter.dart';
import '../config/env_config.dart';
import '../services/logging_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/add_item.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({super.key});

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}


class _CreateBillScreenState extends ConsumerState<CreateBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _amountController = TextEditingController();

  final List<Map<String, dynamic>> _items = [];
  double _totalAmount = 0;

  String? _selectedProductId;
  int _quantity = 1;
  List<Map<String, dynamic>> _products = [];

  final LoggingService _logger = LoggingService();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = '';
  int? _editingIndex;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _speech = stt.SpeechToText();
  }

  // Optional: if you need to access amount as a double
  double get _enteredAmount {
    return double.tryParse(_amountController.text) ?? 0;
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

  @override
  void dispose() {
    _customerNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    _totalAmount = _items.fold(0, (sum, item) => sum + (item['total'] as double));
  }

    void _addItem() {
      if (_selectedProductId == null) return;

      try {
        final product = _products.firstWhere(
          (p) => p['id'].toString() == _selectedProductId,
          orElse: () => throw Exception('Product not found'),
        );

        final price = double.parse(product['price'].toString());
        final enteredAmount = _enteredAmount;

        // Use entered amount if user provided it, else calculate
        final total = (enteredAmount > 0)
            ? enteredAmount
            : (_quantity * price);

        setState(() {
          _items.add({
            'product_id': product['id'],
            'quantity': _quantity,
            'price': price,
            'total': total,
            'product_name': product['name'],
          });

          // Reset form fields
          _selectedProductId = null;
          _quantity = 1;
          _amountController.clear();
          _calculateTotal();
        });

        _logger.debug('Added item to bill: ${product['name']}');
      } catch (e, stackTrace) {
        _logger.error('Failed to add item to bill', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding item: $e')),
          );
        }
      }
    }


  void _resetItemInputs() {
    _selectedProductId = null;
    _quantity = 1;
    // Reset any other related fields like price, total, etc.
  }


  // void _onEditItem(index, field, newValue) {
  //   setState(() {
  //     if (field == 'quantity') {
  //       _items[index]['quantity'] = int.parse(newValue.toString());
  //     } else if (field == 'price') {
  //       _items[index]['price'] = double.parse(newValue.toString());
  //     } else {
  //       _items[index][field] = newValue;
  //     }
  //     _items[index]['total'] = _items[index]['quantity'] * _items[index]['price'];
  //     _calculateTotal();
  //   });
  // }

  void _removeItem(int index) {
    try {
      setState(() {
        _items.removeAt(index);
        _calculateTotal();
      });
      _logger.debug('Removed item from bill at index: $index');
    } catch (e, stackTrace) {
      _logger.error('Failed to remove item from bill', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  Future<void> _saveBill() async {
    if (_formKey.currentState!.validate() && _items.isNotEmpty) {
      final supabaseService = ref.read(supabaseServiceProvider);
      
      try {
        // Create the bill
        final billData = {
          'customer_name': _customerNameController.text,
          'total_amount': _totalAmount,
        };
        
        final bill = await supabaseService.createBill(billData);
        await _logger.info('Created new bill: ${bill['id']}');
        
        // Add all items
        for (var item in _items) {
          await supabaseService.createBillItem({
            'bill_id': bill['id'],
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            'price': item['price'],
          });
          await _logger.debug('Added bill item: ${item['product_name']}');
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e, stackTrace) {
        await _logger.error('Failed to save bill', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving bill: $e')),
          );
        }
      }
    }
  }

  Future<void> _printBill() async {
    final pdf = pw.Document();
    final companyName = EnvConfig.companyName;
    final companyAddress = EnvConfig.companyAddress;
    final companyPhone = EnvConfig.companyPhone;
    final companyEmail = EnvConfig.companyEmail;
    final companyWebsite = EnvConfig.companyWebsite;
    final companyGstNumber = EnvConfig.companyGstNumber;
    final companyPanNumber = EnvConfig.companyPanNumber;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text(
                companyName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(companyAddress),
            pw.Text('Phone: $companyPhone'),
            pw.Text('Email: $companyEmail'),
            if (companyWebsite.isNotEmpty) pw.Text('Website: $companyWebsite'),
            if (companyGstNumber.isNotEmpty) pw.Text('GST: $companyGstNumber'),
            if (companyPanNumber.isNotEmpty) pw.Text('PAN: $companyPanNumber'),
            pw.SizedBox(height: 20),
            pw.Text(
              'Bill',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Customer: ${_customerNameController.text}'),
            pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Item'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Quantity'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Price'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Total'),
                    ),
                  ],
                ),
                ..._items.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(item['product_name']),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(item['quantity'].toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(Formatter.formatCurrency(item['price'])),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(Formatter.formatCurrency(item['total'])),
                    ),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  Formatter.formatCurrency(_totalAmount),
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Bill_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  void _shareViaWhatsApp() {
    final billDetails = '''Bill Details:
                          Customer: ${_customerNameController.text}
                          Date: ${DateTime.now().toString().split(' ')[0]}
                          Total: ${Formatter.formatCurrency(_totalAmount)}''';
  //phone number should come form the Mobile Number TExt box
    final phone = _customerNameController.text.replaceAll(RegExp(r'[^\d]'), '');
    final url = "https://wa.me/+91$phone?text=${Uri.encodeComponent(billDetails)}";
    launchUrl(Uri.parse(url)).then((success) {
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp. Make sure it is installed.')),
        );
      }
    });
  }


  Future<void> _shareBill() async {
    final String billText = '''
Bill Details:
Customer: ${_customerNameController.text}
Date: ${DateTime.now().toString().split(' ')[0]}

Items:
${_items.map((item) => '''
${item['product_name']}
Quantity: ${item['quantity']}
Price: ${Formatter.formatCurrency(item['price'])}
Total: ${Formatter.formatCurrency(item['total'])}
''').join('\n')}

Total Amount: ${Formatter.formatCurrency(_totalAmount)}
''';

    await Share.share(billText);
  }

  void _matchProductWithVoice(String voiceInput) {
    final match = _products.firstWhere(
      (product) => product['name'].toString().toLowerCase() == voiceInput.toLowerCase(),
      orElse: () => {},
    );

    if (match.isNotEmpty) {
      setState(() {
        _selectedProductId = match['id'].toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selected: ${match['name']}")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Product not found: $voiceInput")),
      );
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceInput = result.recognizedWords;
            _matchProductWithVoice(_voiceInput);
          });
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }


  String _getProductNameById(String productId) {
    final product = _products.firstWhere(
      (p) => p['id'].toString() == productId,
      orElse: () => {'name': 'Unknown'}, // Fallback in case product is not found
    );
    return product['name'] as String;
  }

  double _getProductPriceById(String productId) {
    final product = _products.firstWhere(
      (p) => p['id'].toString() == productId,
      orElse: () => {'price': 0.0},
    );
    return (product['price'] as num).toDouble();
  }


  
//   void _saveEditedItem() {
//   if (_editingIndex != null && _selectedProductId != null && _quantity >= 1) {
//     final price = _getProductPriceById(_selectedProductId!);
//     final enteredAmount = _enteredAmount;

//     final double total = (enteredAmount > 0)
//         ? enteredAmount
//         : (_quantity * price);

//     setState(() {
//       _items[_editingIndex!] = {
//         'product_id': _selectedProductId,
//         'product_name': _getProductNameById(_selectedProductId!),
//         'quantity': _quantity,
//         'price': price,
//         'total': total,
//       };
//       _isEditing = false;
//       _editingIndex = null;
//       _amountController.clear();  // Clear entered amount
//       _resetItemInputs();
//     });
//   }
// }

void _saveEditedItem() {
  if (_editingIndex != null && _selectedProductId != null && _quantity >= 1) {
    final price = _getProductPriceById(_selectedProductId!);

    // Read from amountController (always reflects UI's latest value)
    final enteredText = _amountController.text.trim();
    final double? enteredAmount = double.tryParse(enteredText);

    final double total = (enteredAmount != null && enteredAmount >= 0)
        ? enteredAmount
        : (_quantity * price);

    setState(() {
      _items[_editingIndex!] = {
        'product_id': _selectedProductId,
        'product_name': _getProductNameById(_selectedProductId!),
        'quantity': _quantity,
        'price': price,
        'total': total,
      };
      _isEditing = false;
      _editingIndex = null;
      _amountController.clear(); // <-- Clear UI field
      _resetItemInputs();
      _calculateTotal(); 
    });
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bill'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printBill,
            tooltip: 'Print Bill',
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
            onPressed: _shareViaWhatsApp,
            tooltip: 'Share via WhatsApp',
          ),
        ],

      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please a valid Enter Mobile Number';
                    }
                    if (value.length != 10) {
                      return 'Please enter a valid 10 digit mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                AddItemsWidget(
                  isEditing: _isEditing,
                  selectedProductId: _selectedProductId,
                  products: _products,
                  quantity: _quantity,
                  isListening: _isListening,
                  onMicTap: _isListening ? _stopListening : _startListening,
                  onProductChanged: (value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedProductId = value;
                      });
                    });
                  },
                  onQuantityChanged: (value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _quantity = value;
                    });
                    });
                  },
                  amount: _enteredAmount,
                  amountController: _amountController,
                  onAmountChanged: (value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _amountController.text = value;
                    });
                    });
                  },
                  onAdd: _selectedProductId != null ? _addItem : () {},
                  onSaveEdit: _selectedProductId != null ? _saveEditedItem : () {},
                ),

                const SizedBox(height: 16),
                if (_items.isNotEmpty) ...[
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Bill Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          BillItemGrid(
                            billItems: _items,
                            onDeleteItem: _removeItem,
                            onEditItemExternal: (index) {
                              final item = _items[index];
                              setState(() {
                                _selectedProductId = item['product_id'];
                                _quantity = item['quantity'];
                                _isEditing = true;
                                _editingIndex = index;

                                final amount = item['total']?.toStringAsFixed(2) ?? '';
                                _amountController.text = amount;

                              });
                            },
                          ),
                          
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                  Text(
                                'Total Amount:',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                Formatter.formatCurrency(_totalAmount),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveBill,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: const Text(
                      'Save Bill',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


} 