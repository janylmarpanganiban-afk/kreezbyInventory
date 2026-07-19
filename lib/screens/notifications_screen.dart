import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final lowStockItems = inventoryProvider.lowStockItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          if (lowStockItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Low Stock Alerts',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ...lowStockItems.map((item) {
              return _buildNotificationTile(
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.red,
                title: 'Low Stock Alert',
                subtitle: '${item.name} is below the minimum stock level (${item.quantity} ${item.unit} left).',
                time: 'Just now',
              );
            }),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Other Notifications',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          _buildNotificationTile(
            icon: Icons.shopping_basket,
            iconColor: const Color(0xFF0056C6),
            title: 'New Order Received',
            subtitle: 'Shell Select placed a new order.',
            time: '9:15 AM',
          ),
          _buildNotificationTile(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: 'Order Completed',
            subtitle: 'Order from Citimart has been completed.',
            time: '8:45 AM',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ),
    );
  }
}
