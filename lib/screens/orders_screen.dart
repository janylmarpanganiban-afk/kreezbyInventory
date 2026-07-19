import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../widgets/product_image.dart';
import 'package:intl/intl.dart';
import 'create_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Orders'),
            Tab(text: 'Completed'),
            Tab(text: 'Pending'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(provider.orders, context, provider),
                _buildOrderList(provider.completedOrders, context, provider),
                _buildOrderList(provider.pendingOrders, context, provider, isPendingTab: true),
                _buildOrderList(provider.cancelledOrders, context, provider),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
          );
        },
        backgroundColor: const Color(0xFF0056C6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, BuildContext context, OrdersProvider provider, {bool isPendingTab = false}) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders found',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, context, provider, isPendingTab);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, BuildContext context, OrdersProvider provider, bool isPendingTab) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    int totalItemsCount = order.items.fold(0, (sum, item) => sum + item.quantity);
    
    // Status colors
    Color statusColor;
    if (order.status == 'Completed') {
      statusColor = Colors.green;
    } else if (order.status == 'Pending') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order # and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  Text(
                    dateFormat.format(order.date),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateOrderScreen(order: order),
                          ),
                        );
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Order'),
                            content: const Text('Are you sure you want to delete this order?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.deleteOrder(order.id);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Body: Images, Price, Status
          Row(
            children: [
              // Images and item count
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: order.items.length,
                        itemBuilder: (context, imgIndex) {
                          final item = order.items[imgIndex];
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 40,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.shade200,
                            ),
                            child: ProductImage(
                              imagePath: item.imagePath,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(4),
                              fallback: const Icon(Icons.cookie, size: 20),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalItemsCount Items',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Expanded(
                flex: 1,
                child: Center(
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                  ),
                ),
              ),
              // Price and Status
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'P${order.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: statusColor),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Action Buttons for Pending Tab
          if (isPendingTab && order.status == 'Pending') ...[
            const SizedBox(height: 16),
            const Divider(),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => provider.updateOrderStatus(order.id, 'Cancelled'),
                  child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () => provider.updateOrderStatus(order.id, 'Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Complete Order'),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
