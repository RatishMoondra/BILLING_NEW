import 'package:flutter/material.dart';
import '../utils/formatter.dart';

class BillItemGrid extends StatefulWidget {
  final List<Map<String, dynamic>> billItems;
  final void Function(int index)? onDeleteItem;
  final void Function(int index)? onEditItemExternal;

  const BillItemGrid({
    Key? key,
    required this.billItems,
    this.onDeleteItem,
    this.onEditItemExternal,
  }) : super(key: key);

  @override
  State<BillItemGrid> createState() => _BillItemGridState();
}

class _BillItemGridState extends State<BillItemGrid> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<Map<String, dynamic>> get _sortedItems {
    if (_sortColumnIndex == null) return widget.billItems;

    List<Map<String, dynamic>> sorted = [...widget.billItems];
    String key;
    switch (_sortColumnIndex) {
      case 0:
        key = 'product_name';
        break;
      case 1:
        key = 'quantity';
        break;
      case 2:
        key = 'price';
        break;
      case 3:
        key = 'total';
        break;
      default:
        return widget.billItems;
    }

    sorted.sort((a, b) {
      final aVal = a[key];
      final bVal = b[key];
      if (aVal is num && bVal is num) {
        return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
      } else if (aVal is String && bVal is String) {
        return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
      }
      return 0;
    });

    return sorted;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        border: TableBorder.all(color: Colors.grey, width: 1),
        headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
        columns: [
          DataColumn(
            label: const Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold)),
            onSort: _onSort,
          ),
          DataColumn(
            label: const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
            onSort: _onSort,
          ),
          DataColumn(
            label: const Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
            onSort: _onSort,
          ),
          DataColumn(
            label: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
            onSort: _onSort,
          ),
          const DataColumn(
            label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        rows: List.generate(_sortedItems.length, (index) {
          final item = _sortedItems[index];

          // Find the real index in the original list
          final realIndex = widget.billItems.indexOf(item);

          return DataRow(
            cells: [
              DataCell(Text(item['product_name'] ?? '')),
              DataCell(Text(item['quantity'].toString())),
              DataCell(Text(Formatter.formatCurrency(item['price']))),
              DataCell(Text(Formatter.formatCurrency(item['total']))),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => widget.onEditItemExternal?.call(realIndex),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => widget.onDeleteItem?.call(realIndex),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
