import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../models/inventory.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // USERS & ROLES
  // ---------------------------------------------------------------------------

  Future<void> createUserDocument(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // ---------------------------------------------------------------------------
  // ORDERS
  // ---------------------------------------------------------------------------
  
  Future<void> insertOrder(OrderModel order) async {
    await _firestore
        .collection('orders')
        .doc(order.id)
        .set(order.toMap());
  }

  Future<List<OrderModel>> getOrders() async {
    final querySnapshot = await _firestore
        .collection('orders')
        .orderBy('date', descending: true)
        .get();
        
    return querySnapshot.docs.map((doc) {
      return OrderModel.fromMap(doc.data());
    }).toList();
  }

  Future<void> updateOrderStatus(String id, String newStatus) async {
    await _firestore
        .collection('orders')
        .doc(id)
        .update({'status': newStatus});
  }

  Future<void> deleteOrder(String id) async {
    await _firestore.collection('orders').doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // INVENTORY
  // ---------------------------------------------------------------------------

  Future<void> insertInventoryItem(InventoryItem item) async {
    await _firestore
        .collection('inventory')
        .doc(item.id)
        .set(item.toMap());
  }

  Future<List<InventoryItem>> getInventory() async {
    final querySnapshot = await _firestore.collection('inventory').get();
    
    return querySnapshot.docs.map((doc) {
      return InventoryItem.fromMap(doc.data());
    }).toList();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await _firestore
        .collection('inventory')
        .doc(item.id)
        .update(item.toMap());
  }

  Future<void> deleteInventoryItem(String id) async {
    await _firestore.collection('inventory').doc(id).delete();
  }
}
