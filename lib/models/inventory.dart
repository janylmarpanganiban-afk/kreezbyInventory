// inventory model — the blueprint for a single inventory item
// every item in the app (raw materials and finished products) is an InventoryItem

class InventoryItem {
  final String id;        // unique identifier — used to match items in firestore
  String name;
  String category;        // either 'Raw Materials' or 'Finished Products'
  int quantity;           // current stock count
  String unit;            // e.g. 'kg', 'boxes', 'pcs'
  int reorderPoint;       // if quantity drops to or below this, item is "low stock"
  double price;           // selling price per unit
  String? description;    // optional notes about the item
  String? imagePath;      // can be an asset path, https url, or base64 string

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

  // computed property — returns true when quantity has hit or gone below reorderPoint
  // used everywhere to decide whether to show low stock warnings
  bool get isLowStock => quantity <= reorderPoint;

  // converts this object into a plain Map so firestore can save it
  // firestore only understands primitive types (strings, numbers, lists, maps)
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

  // factory constructor — builds an InventoryItem from a firestore document map
  // the ?? operators handle missing or null fields gracefully
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
