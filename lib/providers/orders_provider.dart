import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/database_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ORDERS PROVIDER
// manages the state of all orders in the app
// works the same way as InventoryProvider — listens via context.watch<OrdersProvider>()
// auto-fetches orders from firestore when first created
// ─────────────────────────────────────────────────────────────────────────────
class OrdersProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // internal list of all orders
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  // exposes the full list and loading state to widgets
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  // filtered getters — used by the tabbar in orders_screen.dart
  // each tab reads from one of these instead of filtering itself
  List<OrderModel> get completedOrders => _orders.where((o) => o.status == 'Completed').toList();
  List<OrderModel> get pendingOrders => _orders.where((o) => o.status == 'Pending').toList();
  List<OrderModel> get cancelledOrders => _orders.where((o) => o.status == 'Cancelled').toList();

  // auto-fetches orders on startup
  OrdersProvider() {
    fetchOrders();
  }

  // ─── FIREBASE PULL (READ) ────────────────────────────────────────────────
  // fetches all orders from firestore
  // if empty (first launch), seeds dummy data
  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners(); // start spinner

    try {
      _orders = await _dbService.getOrders(); // firebase pull
      if (_orders.isEmpty) {
        await _seedDummyData();
        _orders = await _dbService.getOrders(); // pull again after seeding
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // stop spinner, rebuild widgets
    }
  }

  // seeds initial dummy orders so the app doesn't look empty on first run
  Future<void> _seedDummyData() async {
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

    // push each dummy order to firestore
    for (var o in dummyOrders) {
      await _dbService.insertOrder(o); // firebase push
    }
  }

  // ─── CRUD: CREATE ────────────────────────────────────────────────────────
  // creates a new order with a generated id and order number
  // uses milliseconds since epoch as the id (simple way to get a unique number)
  // pushes to firestore then inserts at the top of the local list (newest first)
  Future<void> addOrder(List<OrderItem> items, double totalPrice) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newOrder = OrderModel(
      id: id,
      // generates a short order number using the last 5 digits of the timestamp
      orderNumber: '#ORD-2025-${id.substring(id.length - 5)}',
      date: DateTime.now(),
      totalPrice: totalPrice,
      status: 'Pending', // new orders always start as pending
      items: items,
    );

    await _dbService.insertOrder(newOrder); // firebase push
    _orders.insert(0, newOrder); // insert at front so it shows first
    notifyListeners();
  }

  // ─── CRUD: UPDATE (status only) ─────────────────────────────────────────
  // only changes the status field of an order (Pending → Completed or Cancelled)
  // calls updateOrderStatus in database_service which uses firestore .update()
  Future<void> updateOrderStatus(String id, String newStatus) async {
    await _dbService.updateOrderStatus(id, newStatus); // firebase push (partial update)
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      // copyWith creates a new object with just the status changed
      _orders[index] = _orders[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  // ─── CRUD: UPDATE (full order) ───────────────────────────────────────────
  // replaces the whole order document in firestore
  // used when editing order items or price from create_order_screen.dart
  // uses insertOrder (set) because it's easier to just overwrite the whole doc
  Future<void> updateOrder(OrderModel updatedOrder) async {
    await _dbService.insertOrder(updatedOrder); // firebase push — set() overwrites the whole doc
    final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
      notifyListeners();
    }
  }

  // ─── CRUD: DELETE ────────────────────────────────────────────────────────
  // removes order from firestore and from local list
  Future<void> deleteOrder(String id) async {
    await _dbService.deleteOrder(id); // firebase push (delete)
    _orders.removeWhere((o) => o.id == id);
    notifyListeners();
  }
}
