class Ingredient {
  final int? id;
  final String name;
  final String unit;
  final double quantity;
  final double pricePerUnit;
  final String category;

  Ingredient({
    this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.pricePerUnit,
    required this.category,
  });

  double get totalCost => quantity * pricePerUnit;
  bool get isLowStock => quantity < 100;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'unit': unit,
        'quantity': quantity,
        'pricePerUnit': pricePerUnit,
        'category': category,
      };

  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient(
        id: map['id'],
        name: map['name'],
        unit: map['unit'],
        quantity: map['quantity'].toDouble(),
        pricePerUnit: map['pricePerUnit'].toDouble(),
        category: map['category'],
      );
}
