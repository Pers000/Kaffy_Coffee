class Sale {
  final int? id;
  final String productName;
  final int quantity;
  final double totalPrice;
  final DateTime date;
  final String cashierRole;

  Sale({
    this.id,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.date,
    required this.cashierRole,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_name': productName,
        'quantity': quantity,
        'total_price': totalPrice,
        'date': date.toIso8601String(),
        'cashier_role': cashierRole,
      };

  factory Sale.fromMap(Map<String, dynamic> map) => Sale(
        id: map['id'],
        productName: map['product_name'],
        quantity: map['quantity'],
        totalPrice: map['total_price'].toDouble(),
        date: DateTime.parse(map['date']),
        cashierRole: map['cashier_role'],
      );
}
