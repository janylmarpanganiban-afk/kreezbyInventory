import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/database_service.dart';


class OrdersProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  List<OrderModel> get completedOrders => _orders.where((o) => o.status == 'Completed').toList();
  List<OrderModel> get pendingOrders => _orders.where((o) => o.status == 'Pending').toList();
  List<OrderModel> get cancelledOrders => _orders.where((o) => o.status == 'Cancelled').toList();

  OrdersProvider() {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _dbService.getOrders();
      if (_orders.isEmpty) {
        await _seedDummyData();
        _orders = await _dbService.getOrders();
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _seedDummyData() async {
    // Seed with initial dummy orders to match the UI screenshot
    final dummyOrders = [
      OrderModel(
        id: 'dummy1',
        orderNumber: '#ORD-2025-00125',
        date: DateTime(2025, 5, 12),
        totalPrice: 1250,
        status: 'Completed',
        items: [
          OrderItem(id: 'i1', name: 'Ube Crinkles', quantity: 3, price: 100, imagePath: 'assets/ube crinkles.jpg'),
          OrderItem(id: 'i2', name: 'Red Velvet Crinkles', quantity: 3, price: 100, imagePath: 'assets/red velvet crinkles.jpg'),
          OrderItem(id: 'i3', name: 'Lemon Crinkles', quantity: 3, price: 150, imagePath: 'assets/lemon crinkles.jpg'),
          OrderItem(id: 'i4', name: 'Chocolate Crinkles', quantity: 3, price: 66.6, imagePath: 'assets/chocolate crinkles.jpg'),
        ],
      ),
      OrderModel(
        id: 'dummy2',
        orderNumber: '#ORD-2025-00124',
        date: DateTime(2025, 5, 10),
        totalPrice: 950,
        status: 'Completed',
        items: [
          OrderItem(id: 'i5', name: 'Melon Crinkles', quantity: 2, price: 120, imagePath: 'assets/melon crinkles.jpg'),
          OrderItem(id: 'i6', name: 'Lemon Crinkles', quantity: 2, price: 150, imagePath: 'assets/lemon crinkles.jpg'),
          OrderItem(id: 'i7', name: 'Strawberry Crinkles', quantity: 2, price: 100, imagePath: 'assets/strawberry crinkles.jpg'),
          OrderItem(id: 'i8', name: 'Chocolate Crinkles', quantity: 2, price: 105, imagePath: 'assets/chocolate crinkles.jpg'),
        ],
      ),
      OrderModel(
        id: 'dummy3',
        orderNumber: '#ORD-2025-00123',
        date: DateTime(2025, 5, 8),
        totalPrice: 630,
        status: 'Pending',
        items: [
          OrderItem(id: 'i9', name: 'Choco Cashew Crinkles', quantity: 1, price: 130, imagePath: 'assets/choco cashew crinkles.jpg'),
          OrderItem(id: 'i10', name: 'Choco Almond Crinkles', quantity: 2, price: 150, imagePath: 'assets/choco almond crinkles.jpg'),
          OrderItem(id: 'i11', name: 'Red Velvet Crinkles', quantity: 2, price: 100, imagePath: 'assets/red velvet crinkles.jpg'),
        ],
      ),
    ];

    for (var o in dummyOrders) {
      await _dbService.insertOrder(o);
    }
  }

  Future<void> addOrder(List<OrderItem> items, double totalPrice) async {
    // We don't have the uuid package yet, so we'll just use DateTime milliseconds for unique IDs.
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newOrder = OrderModel(
      id: id,
      orderNumber: '#ORD-2025-${id.substring(id.length - 5)}', // generate a short pseudo-order number
      date: DateTime.now(),
      totalPrice: totalPrice,
      status: 'Pending',
      items: items,
    );

    await _dbService.insertOrder(newOrder);
    _orders.insert(0, newOrder);
    notifyListeners();
  }

  Future<void> updateOrderStatus(String id, String newStatus) async {
    await _dbService.updateOrderStatus(id, newStatus);
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  Future<void> updateOrder(OrderModel updatedOrder) async {
    await _dbService.insertOrder(updatedOrder); // using insertOrder because set() overrides the whole doc
    final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
      notifyListeners();
    }
  }

  Future<void> deleteOrder(String id) async {
    await _dbService.deleteOrder(id);
    _orders.removeWhere((o) => o.id == id);
    notifyListeners();
  }
}
