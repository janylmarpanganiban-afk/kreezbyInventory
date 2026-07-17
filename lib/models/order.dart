import 'dart:convert';

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? imagePath;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imagePath': imagePath,
    };
  }

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

class OrderModel {
  final String id;
  final String orderNumber;
  final DateTime date;
  final double totalPrice;
  final String status; // 'Pending', 'Completed', 'Cancelled'
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.totalPrice,
    required this.status,
    required this.items,
  });

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'date': date.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status,
      'items': items.map((x) => x.toMap()).toList(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      date: DateTime.parse(map['date']),
      totalPrice: map['totalPrice']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pending',
      items: List<OrderItem>.from(map['items']?.map((x) => OrderItem.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory OrderModel.fromJson(String source) => OrderModel.fromMap(json.decode(source));
}
