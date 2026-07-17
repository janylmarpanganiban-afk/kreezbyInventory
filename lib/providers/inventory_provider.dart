import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../services/database_service.dart';

export '../models/inventory.dart';

class InventoryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<InventoryItem> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';

  InventoryProvider() {
    fetchInventory();
  }

  bool get isLoading => _isLoading;

  List<InventoryItem> get items {
    if (_searchQuery.isEmpty) return _items;
    return _items
        .where(
          (item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<InventoryItem> get lowStockItems =>
      _items.where((item) => item.isLowStock).toList();

  List<InventoryItem> get dashboardAlertItems {
    final low = lowStockItems;
    if (low.isNotEmpty) return low;
    
    // If no low stock items, get the lowest stock items (up to 3)
    if (_items.isEmpty) return [];
    final sorted = List<InventoryItem>.from(_items)
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
    return sorted.take(3).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchInventory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _dbService.getInventory();
      
      // If inventory is empty, seed initial dummy data
      if (_items.isEmpty) {
        await _seedDummyData();
        _items = await _dbService.getInventory();
      }
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

    for (var item in dummyItems) {
      await _dbService.insertInventoryItem(item);
    }
  }

  Future<void> addItem(InventoryItem item) async {
    await _dbService.insertInventoryItem(item);
    _items.add(item);
    notifyListeners();
  }

  Future<void> updateItem(InventoryItem updatedItem) async {
    await _dbService.updateInventoryItem(updatedItem);
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    await _dbService.deleteInventoryItem(id);
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
