import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../models/order.dart';
import '../widgets/product_image.dart';
import 'inventory_screen.dart';
import 'item_form_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final ordersProvider = context.watch<OrdersProvider>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0056C6),
            title: const Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout_outlined, color: Colors.white),
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                    },
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
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
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                Text(
                  isAdmin ? 'Hi, Owner! 👋' : 'Hi, Staff! 👋',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Here's what's happening today.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.inventory_2,
                        label: 'Total Items',
                        value: isAdmin ? '${provider.items.fold<int>(0, (sum, i) => sum + i.quantity)}' : '${provider.items.length}',
                        color: const Color(0xFF0056C6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.warning_amber_rounded,
                        label: 'Low Stock',
                        value: '${provider.lowStockItems.length}',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                if (provider.dashboardAlertItems.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(provider.lowStockItems.isEmpty ? 'Lowest Stock Items' : 'Low Stock Alert'),
                      TextButton(onPressed: (){}, child: const Text('See all', style: TextStyle(color: Color(0xFF0056C6)))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...provider.dashboardAlertItems.map(
                    (item) => _buildAlertCard(item, isAdmin),
                  ),
                  const SizedBox(height: 24),
                ],
                if (ordersProvider.orders.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Recent Orders'),
                      TextButton(onPressed: (){}, child: const Text('See all', style: TextStyle(color: Color(0xFF0056C6)))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...ordersProvider.orders.take(3).map((order) => _buildOrderCard(order)),
                  const SizedBox(height: 24),
                ],
                _buildSectionTitle('Quick Actions'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (isAdmin) ...[
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.add_box_outlined,
                          label: 'Add Item',
                          color: const Color(0xFF0056C6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ItemFormScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.list_alt_outlined,
                        label: 'View Inventory',
                        color: const Color(0xFF0056C6),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InventoryScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildInventoryList(provider),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(InventoryItem item, bool isAdmin) {
    final isLow = item.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLow ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLow ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ProductImage(
            imagePath: item.imagePath,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8),
            fallback: Icon(Icons.inventory_2, color: isLow ? Colors.red : const Color(0xFF0056C6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  isAdmin
                      ? '${item.quantity} ${item.unit} left${isLow ? ' (min: ${item.reorderPoint} ${item.unit})' : ''}'
                      : (isLow ? 'Stock is running critically low' : 'Lowest stock item'),
                  style: TextStyle(
                      fontSize: 12, color: isLow ? Colors.red.shade700 : Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isLow) const Icon(Icons.error, color: Colors.red, size: 20),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ProductImage(
            imagePath: firstItem?.imagePath,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8),
            fallback: const Icon(Icons.shopping_bag, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  dateFormat.format(order.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: order.status == 'Completed' ? Colors.green.shade50 : (order.status == 'Cancelled' ? Colors.red.shade50 : Colors.orange.shade50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: order.status == 'Completed' ? Colors.green.shade700 : (order.status == 'Cancelled' ? Colors.red.shade700 : Colors.orange.shade700),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList(InventoryProvider provider) {
    if (provider.items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Products & Raw Materials'),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return Column(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ProductImage(
                      imagePath: item.imagePath,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(16),
                      fallback: const Icon(Icons.inventory_2, color: Color(0xFF0056C6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 75,
                    child: Text(
                      item.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
