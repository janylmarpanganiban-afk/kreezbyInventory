import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/orders_provider.dart';
import '../models/order.dart';
import '../widgets/product_image.dart';

class CreateOrderScreen extends StatefulWidget {
  final OrderModel? order;

  const CreateOrderScreen({super.key, this.order});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  // Map of inventory item ID -> quantity selected
  final Map<String, int> _selectedItems = {};
  // Map of inventory item ID -> price per unit (editable)
  final Map<String, TextEditingController> _priceControllers = {};
  // Map of inventory item ID -> whether the price field is editable
  final Map<String, bool> _isPriceEditable = {};

  bool get _isEditing => widget.order != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      for (var item in widget.order!.items) {
        _selectedItems[item.id] = item.quantity;
        _priceControllers[item.id] =
            TextEditingController(text: item.price.toStringAsFixed(0));
        _isPriceEditable[item.id] = false; // Not editable by default even in edit mode
      }
    }
  }

  @override
  void dispose() {
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Ensure a price controller exists for a given item, defaulting to its inventory price or 120 if it's a crinkle
  TextEditingController _priceControllerFor(InventoryItem item) {
    if (!_priceControllers.containsKey(item.id)) {
      double initialPrice = item.price > 0 ? item.price : (item.name.toLowerCase().contains('crinkle') ? 120.0 : 0.0);
      _priceControllers[item.id] =
          TextEditingController(text: initialPrice > 0 ? initialPrice.toStringAsFixed(0) : '');
      _isPriceEditable[item.id] = false;
    }
    return _priceControllers[item.id]!;
  }

  double _getItemPrice(String id) {
    return double.tryParse(_priceControllers[id]?.text ?? '') ?? 0.0;
  }

  double get _totalPrice {
    double total = 0;
    _selectedItems.forEach((id, qty) {
      total += qty * _getItemPrice(id);
    });
    return total;
  }

  Widget _buildImage(InventoryItem item) {
    return ProductImage(
      imagePath: item.imagePath,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
      fallback: const Icon(Icons.cookie, size: 50, color: Colors.brown),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();

    // Show only products (not Raw Materials)
    final products = inventoryProvider.items
        .where((item) => item.category.toLowerCase() != 'raw materials')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Order' : 'Create Order'),
      ),
      body: products.isEmpty
          ? const Center(child: Text('No products available in inventory.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = products[index];
                final qty = _selectedItems[item.id] ?? 0;
                final priceCtrl = _priceControllerFor(item);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: qty > 0
                        ? Border.all(
                            color: const Color(0xFF0056C6), width: 1.5)
                        : Border.all(color: Colors.transparent),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildImage(item),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                Text(
                                  item.category,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                                Text(
                                  '${item.quantity} ${item.unit} in stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: item.isLowStock
                                        ? Colors.red.shade600
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quantity stepper
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: qty > 0
                                    ? () {
                                        setState(() {
                                          _selectedItems[item.id] = qty - 1;
                                          if (_selectedItems[item.id] == 0) {
                                            _selectedItems.remove(item.id);
                                          }
                                        });
                                      }
                                    : null,
                              ),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '$qty',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    _selectedItems[item.id] = qty + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Price field — shown when item is selected
                      if (qty > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Price per unit (₱): ',
                              style: TextStyle(fontSize: 13),
                            ),
                            if (_isPriceEditable[item.id] == true)
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: priceCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      hintText: '0',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF0056C6), width: 1.5),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              Text(
                                _getItemPrice(item.id).toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _isPriceEditable[item.id] = true;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const Spacer(),
                            ],
                            if (_isPriceEditable[item.id] == true)
                              const SizedBox(width: 8),
                            Text(
                              '= ₱${(qty * _getItemPrice(item.id)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0056C6)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price',
                        style: TextStyle(color: Colors.grey)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₱${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF0056C6)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedItems.isEmpty
                    ? null
                    : () async {
                        final ordersProvider = context.read<OrdersProvider>();

                        // Build the OrderItem list using each item's editable price
                        final List<OrderItem> orderItems = [];
                        _selectedItems.forEach((id, qty) {
                          final inventoryItem = products
                              .firstWhere((element) => element.id == id);
                          orderItems.add(OrderItem(
                            id: inventoryItem.id,
                            name: inventoryItem.name,
                            quantity: qty,
                            price: _getItemPrice(id),
                            imagePath: inventoryItem.imagePath,
                          ));
                        });

                        if (_isEditing) {
                          final updatedOrder = widget.order!.copyWith(
                            totalPrice: _totalPrice,
                            items: orderItems,
                          );
                          await ordersProvider.updateOrder(updatedOrder);
                        } else {
                          await ordersProvider.addOrder(
                              orderItems, _totalPrice);
                          
                          // Deduct inventory for new order
                          for (var item in orderItems) {
                            try {
                              final inventoryItem = inventoryProvider.items
                                  .firstWhere((e) => e.id == item.id);
                              inventoryItem.quantity -= item.quantity;
                              await inventoryProvider.updateItem(inventoryItem);
                            } catch (e) {
                              // Item might not exist, skip
                            }
                          }
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(_isEditing
                                    ? 'Order updated successfully!'
                                    : 'Order created successfully!')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056C6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _isEditing ? 'Save Changes' : 'Submit Order',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
