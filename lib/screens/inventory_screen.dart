import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_image.dart';
import 'item_form_screen.dart';
import 'notifications_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    final categories = ['All', ...{...provider.items.map((i) => i.category)}];

    final filteredItems = provider.items.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              if (provider.lowStockItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(provider),
          _buildSearchAndFilter(categories),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'No items found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) =>
                        _buildItemCard(context, filteredItems[index], provider, isAdmin),
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ItemFormScreen()),
              ),
              backgroundColor: const Color(0xFF0056C6),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Item',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildSummaryBar(InventoryProvider provider) {
    return Container(
      color: const Color(0xFF0056C6),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _summaryChip(
            icon: Icons.inventory_2,
            label: '${provider.items.length} Items',
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          _summaryChip(
            icon: Icons.warning_amber_rounded,
            label: '${provider.lowStockItems.length} Low Stock',
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF0056C6)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = categories[i];
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF0056C6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    InventoryItem item,
    InventoryProvider provider,
    bool isAdmin,
  ) {
    final isLow = item.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isLow
            ? Border.all(color: Colors.red.shade200, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: isLow ? Colors.red.shade50 : const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: item.imagePath != null && item.imagePath!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductImage(
                        imagePath: item.imagePath,
                        fit: BoxFit.cover,
                        fallback: Icon(
                          Icons.inventory_2,
                          color: isLow ? Colors.red : const Color(0xFF0056C6),
                        ),
                      ),
                      if (isLow)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          alignment: Alignment.center,
                          child: const Text(
                            'LOW\nSTOCK',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : Icon(
                  Icons.inventory_2,
                  color: isLow ? Colors.red : const Color(0xFF0056C6),
                ),
        ),
        title: Row(
          children: [
            Text(item.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.category,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                isAdmin
                    ? '${item.quantity} ${item.unit} left'
                    : (isLow ? 'Low Stock' : 'In Stock'),
                style: TextStyle(
                  color: isLow ? Colors.red.shade700 : (isAdmin ? Colors.black87 : Colors.green.shade700),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.price > 0)
                Text(
                  '₱${item.price.toStringAsFixed(2)} per ${item.unit}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
            ],
          ),
        ),
        trailing: isAdmin ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemFormScreen(item: item),
                    ),
                  );
                } else if (value == 'reorder') {
                  _showReorderDialog(context, provider, item);
                } else if (value == 'delete') {
                  _confirmDelete(context, provider, item);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'reorder', child: Text('Reorder')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ) : null,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    InventoryProvider provider,
    InventoryItem item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteItem(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReorderDialog(
    BuildContext context,
    InventoryProvider provider,
    InventoryItem item,
  ) {
    final qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reorder ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current quantity: ${item.quantity} ${item.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to add',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final addedQty = int.tryParse(qtyController.text) ?? 0;
              if (addedQty > 0) {
                final updatedItem = InventoryItem(
                  id: item.id,
                  name: item.name,
                  category: item.category,
                  quantity: item.quantity + addedQty,
                  unit: item.unit,
                  reorderPoint: item.reorderPoint,
                  price: item.price,
                  description: item.description,
                  imagePath: item.imagePath,
                );
                provider.updateItem(updatedItem);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reordered $addedQty ${item.unit} of ${item.name}')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056C6)),
            child: const Text('Reorder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
