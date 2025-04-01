import 'bill_item.dart';

class Bill {
  final String? id;
  final String customerName;
  final String customerPhone;
  final List<BillItem> items;
  final double totalAmount;
  final DateTime createdAt;

  Bill({
    this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      items: (json['items'] as List)
          .map((item) => BillItem.fromJson(item))
          .toList(),
      totalAmount: json['total_amount'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Bill copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    List<BillItem>? items,
    double? totalAmount,
    DateTime? createdAt,
  }) {
    return Bill(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 