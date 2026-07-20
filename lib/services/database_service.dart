import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../models/inventory.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATABASE SERVICE
// this is the single place where all firebase firestore calls happen
// think of it as the "bridge" between the app and the cloud database
// it's a singleton — meaning only ONE instance exists across the whole app
// ─────────────────────────────────────────────────────────────────────────────
class DatabaseService {
  // singleton setup — prevents creating multiple instances
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // the main firestore instance — this is how we talk to firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // USERS & ROLES
  // ---------------------------------------------------------------------------

  // FIREBASE PUSH: creates a new user document in the 'users' collection
  // called right after signup to save role and display name
  // path: users/{uid}
  Future<void> createUserDocument(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  // FIREBASE PULL: reads a single user document by uid
  // used in auth_provider to check if user is admin or staff
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // ---------------------------------------------------------------------------
  // ORDERS
  // these are the CRUD operations for the 'orders' firestore collection
  // ---------------------------------------------------------------------------

  // FIREBASE PUSH (CREATE / UPDATE): saves an order to firestore
  // uses .set() which completely overwrites the document if it already exists
  // this is also used for updating since set() replaces the whole doc
  Future<void> insertOrder(OrderModel order) async {
    await _firestore
        .collection('orders')
        .doc(order.id)
        .set(order.toMap()); // toMap() converts the dart object to a plain map for firestore
  }

  // FIREBASE PULL (READ): fetches all orders from firestore, sorted newest first
  // returns a list of OrderModel objects converted from firestore documents
  Future<List<OrderModel>> getOrders() async {
    final querySnapshot = await _firestore
        .collection('orders')
        .orderBy('date', descending: true) // newest orders show up first
        .get();

    // each doc in querySnapshot is converted back to an OrderModel using fromMap()
    return querySnapshot.docs.map((doc) {
      return OrderModel.fromMap(doc.data());
    }).toList();
  }

  // FIREBASE PUSH (UPDATE): only updates the 'status' field of an order
  // cheaper than rewriting the whole document — just touches the one field
  Future<void> updateOrderStatus(String id, String newStatus) async {
    await _firestore
        .collection('orders')
        .doc(id)
        .update({'status': newStatus}); // update() is partial — only changes specified fields
  }

  // FIREBASE PUSH (DELETE): permanently removes an order from firestore
  Future<void> deleteOrder(String id) async {
    await _firestore.collection('orders').doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // INVENTORY
  // these are the CRUD operations for the 'inventory' firestore collection
  // ---------------------------------------------------------------------------

  // FIREBASE PUSH (CREATE / UPDATE): saves an inventory item to firestore
  // same as insertOrder — uses .set() to overwrite the whole document
  Future<void> insertInventoryItem(InventoryItem item) async {
    await _firestore
        .collection('inventory')
        .doc(item.id)
        .set(item.toMap()); // toMap() converts InventoryItem to a plain map
  }

  // FIREBASE PULL (READ): fetches all inventory items from firestore
  // no sorting here — items come in the order firestore returns them
  Future<List<InventoryItem>> getInventory() async {
    final querySnapshot = await _firestore.collection('inventory').get();

    // each document snapshot is converted back to an InventoryItem using fromMap()
    return querySnapshot.docs.map((doc) {
      return InventoryItem.fromMap(doc.data());
    }).toList();
  }

  // FIREBASE PUSH (UPDATE): partially updates an inventory item
  // uses .update() which only changes the provided fields
  Future<void> updateInventoryItem(InventoryItem item) async {
    await _firestore
        .collection('inventory')
        .doc(item.id)
        .update(item.toMap()); // update() here sends all fields but only overwrites existing doc
  }

  // FIREBASE PUSH (DELETE): permanently removes an inventory item from firestore
  Future<void> deleteInventoryItem(String id) async {
    await _firestore.collection('inventory').doc(id).delete();
  }
}
