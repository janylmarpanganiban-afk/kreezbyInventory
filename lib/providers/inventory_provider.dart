import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../services/database_service.dart';

// re-exports InventoryItem so other files can import just this provider
export '../models/inventory.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INVENTORY PROVIDER
// manages the state of all inventory items in the app
// any screen that needs inventory data listens to this via context.watch<InventoryProvider>()
// uses ChangeNotifier so widgets rebuild automatically when data changes
// ─────────────────────────────────────────────────────────────────────────────
class InventoryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // the internal list of items — screens get this through the getters below
  List<InventoryItem> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // auto-fetches inventory from firestore when this provider is first created
  InventoryProvider() {
    fetchInventory();
  }

  // exposes loading state so screens can show a spinner while data is loading
  bool get isLoading => _isLoading;

  // returns filtered items based on the current search query
  // if no search query, returns all items
  List<InventoryItem> get items {
    if (_searchQuery.isEmpty) return _items;
    return _items
        .where(
          (item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  // returns only items whose quantity has dropped to or below their reorderPoint
  // used for the red notification badge and low stock alert section
  List<InventoryItem> get lowStockItems =>
      _items.where((item) => item.isLowStock).toList();

  // used on the dashboard to show alerts
  // if there are low stock items — show those
  // if no low stock — show the 3 items with lowest quantity as a preview
  List<InventoryItem> get dashboardAlertItems {
    final low = lowStockItems;
    if (low.isNotEmpty) return low;

    // if inventory is empty, nothing to show
    if (_items.isEmpty) return [];
    final sorted = List<InventoryItem>.from(_items)
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
    return sorted.take(3).toList(); // only show top 3 lowest
  }

  // updates the search filter and rebuilds listening widgets
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ─── FIREBASE PULL (READ) ────────────────────────────────────────────────
  // fetches all inventory items from firestore
  // if the collection is empty (first launch), seeds dummy data
  Future<void> fetchInventory() async {
    _isLoading = true;
    notifyListeners(); // tells widgets: "hey, i'm loading, show a spinner"

    try {
      _items = await _dbService.getInventory(); // firebase pull

      // first time running the app? seed some sample items
      if (_items.isEmpty) {
        await _seedDummyData();
        _items = await _dbService.getInventory(); // pull again after seeding
      }
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // tells widgets: "i'm done, refresh yourselves"
    }
  }

  // seeds initial dummy data if firestore inventory is empty on first launch
  // these are the crinkle products and raw materials for kreezby
  Future<void> _seedDummyData() async {
    final dummyItems = [
      InventoryItem(id: '1', name: 'Flour', category: 'Raw Materials', quantity: 20, unit: 'kg', reorderPoint: 5, imagePath: 'assets/flour.jpg'),
      InventoryItem(id: '2', name: 'Sugar', category: 'Raw Materials', quantity: 15, unit: 'kg', reorderPoint: 5, imagePath: 'assets/sugar.jpg'),
      InventoryItem(id: '3', name: 'Cocoa', category: 'Raw Materials', quantity: 12, unit: 'kg', reorderPoint: 5, imagePath: 'assets/cocoa.jpg'),
      InventoryItem(id: '4', name: 'Yeast', category: 'Raw Materials', quantity: 5, unit: 'kg', reorderPoint: 2, imagePath: 'assets/yeast.jpg'),
      InventoryItem(id: '5', name: 'Choco Almond Crinkles', category: 'Finished Products', quantity: 15, unit: 'boxes', reorderPoint: 5, imagePath: 'assets/choco almond crinkles.jpg'),
      InventoryItem(id: '6', name: 'Choco Butternut Crinkles', category: 'Finished Products', quantity: 10, unit: 'boxes', reorderPoint: 5, imagePath: 'assets/choco butternut crinkles.jpg'),
      InventoryItem(id: '7', name: 'Choco Cashew Crinkles', category: 'Finished Products', quantity: 12, unit: 'boxes', reorderPoint: 5, imagePath: 'assets/choco cashew crinkles.jpg'),
      InventoryItem(id: '8', name: 'Chocolate Crinkles', category: 'Finished Products', quantity: 25, unit: 'boxes', reorderPoint: 5, imagePath: 'assets/chocolate crinkles.jpg'),
      InventoryItem(id: '9', name: 'Lemon Crinkles', category: 'Finished Products', quantity: 8, unit: 'boxes', reorderPoint: 5, imagePath: 'assets/lemon crinkles.jpg'),
      InventoryItem(id: '10', name: 'Melon Crinkles', category: 'Finished Products', quantity: 14, unit: 'boxes', reorderPoint: 5, imagePath: 'assets/melon crinkles.jpg'),
      InventoryItem(id: '11', name: 'Red Velvet Crinkles', category: 'Finished Products', quantity: 20, unit: 'boxes', reorderPoint: 5, imagePath: 'assets/red velvet crinkles.jpg'),
      InventoryItem(id: '12', name: 'Strawberry Crinkles', category: 'Finished Products', quantity: 18, unit: 'boxes', reorderPoint: 5, imagePath: 'assets/strawberry crinkles.jpg'),
      InventoryItem(id: '13', name: 'Ube Crinkles', category: 'Finished Products', quantity: 30, unit: 'boxes', reorderPoint: 5, imagePath: 'assets/ube crinkles.jpg'),
    ];

    // push each item to firestore one by one
    for (var item in dummyItems) {
      await _dbService.insertInventoryItem(item); // firebase push
    }
  }

  // ─── CRUD: CREATE ────────────────────────────────────────────────────────
  // adds a new item — pushes to firestore then adds to local list
  // notifyListeners() makes all watching screens rebuild with the new item
  Future<void> addItem(InventoryItem item) async {
    await _dbService.insertInventoryItem(item); // firebase push
    _items.add(item);
    notifyListeners();
  }

  // ─── CRUD: UPDATE ────────────────────────────────────────────────────────
  // updates an existing item by matching id
  // updates firestore first, then replaces the item in the local list
  Future<void> updateItem(InventoryItem updatedItem) async {
    await _dbService.updateInventoryItem(updatedItem); // firebase push
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem; // replace old item in memory
      notifyListeners();
    }
  }

  // ─── CRUD: DELETE ────────────────────────────────────────────────────────
  // removes an item from firestore and from the local list
  // removeWhere loops and removes any item matching the given id
  Future<void> deleteItem(String id) async {
    await _dbService.deleteInventoryItem(id); // firebase push (delete)
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
