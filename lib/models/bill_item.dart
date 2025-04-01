class BillItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  BillItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      productId: json['product_id'],
      productName: json['product_name'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
    );
  }

  BillItem copyWith({
    String? productId,
    String? productName,
    double? price,
    int? quantity,
  }) {
    return BillItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
} 