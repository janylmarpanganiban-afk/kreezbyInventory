class InventoryItem {
  final String id;
  String name;
  String category; // 'Raw Materials' or 'Finished Products'
  int quantity;
  String unit;
  int reorderPoint;
  double price;
  String? description;
  String? imagePath;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.reorderPoint,
    this.price = 0.0,
    this.description,
    this.imagePath,
  });

  bool get isLowStock => quantity <= reorderPoint;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'reorderPoint': reorderPoint,
      'price': price,
      'description': description,
      'imagePath': imagePath,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      unit: map['unit'] ?? '',
      reorderPoint: map['reorderPoint']?.toInt() ?? 0,
      price: map['price']?.toDouble() ?? 0.0,
      description: map['description'],
      imagePath: map['imagePath'],
    );
  }
}
