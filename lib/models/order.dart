import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// ORDER MODELS
// two classes here: OrderItem (a single product line) and OrderModel (the full order)
// ─────────────────────────────────────────────────────────────────────────────

// represents one product inside an order
// e.g. "3x Ube Crinkles at ₱100 each"
class OrderItem {
  final String id;          // matches the inventory item id
  final String name;
  final int quantity;       // how many units were ordered
  final double price;       // price per unit at the time of order
  final String? imagePath;  // copied from inventory for display purposes

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.imagePath,
  });

  // converts to Map so firestore can save it
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imagePath': imagePath,
    };
  }

  // builds an OrderItem from a firestore Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      price: map['price']?.toDouble() ?? 0.0,
      imagePath: map['imagePath'],
    );
  }

  String toJson() => json.encode(toMap());

  factory OrderItem.fromJson(String source) => OrderItem.fromMap(json.decode(source));
}

// represents a full order — contains multiple OrderItems
// status can be 'Pending', 'Completed', or 'Cancelled'
class OrderModel {
  final String id;            // unique order id — generated from timestamp in orders_provider
  final String orderNumber;   // human-readable label like '#ORD-2025-12345'
  final DateTime date;        // when the order was placed
  final double totalPrice;    // sum of all item prices * quantities
  final String status;        // 'Pending', 'Completed', or 'Cancelled'
  final List<OrderItem> items; // the list of products in this order

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.totalPrice,
    required this.status,
    required this.items,
  });

  // creates a copy of this order but with some fields changed
  // useful when only updating status — keeps everything else the same
  OrderModel copyWith({
    String? id,
    String? orderNumber,
    DateTime? date,
    double? totalPrice,
    String? status,
    List<OrderItem>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      date: date ?? this.date,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }

  // converts to a Map for firestore — date is stored as ISO 8601 string
  // items list is also converted to a list of maps (firestore supports nested arrays)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'date': date.toIso8601String(), // firestore can't store DateTime directly
      'totalPrice': totalPrice,
      'status': status,
      'items': items.map((x) => x.toMap()).toList(), // each OrderItem becomes a map
    };
  }

  // builds an OrderModel from a firestore document
  // DateTime.parse() converts the stored ISO string back to a DateTime object
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      date: DateTime.parse(map['date']),
      totalPrice: map['totalPrice']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pending',
      // map over the 'items' array and convert each one back to an OrderItem
      items: List<OrderItem>.from(map['items']?.map((x) => OrderItem.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory OrderModel.fromJson(String source) => OrderModel.fromMap(json.decode(source));
}
