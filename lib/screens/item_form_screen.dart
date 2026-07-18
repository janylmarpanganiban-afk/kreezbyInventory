import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/product_image.dart';

class ItemFormScreen extends StatefulWidget {
  final InventoryItem? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _reorderPointController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  Uint8List? _pickedImageBytes;
  String? _currentImagePath; // existing imagePath (asset or network URL)
  bool _isUploading = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _quantityController =
        TextEditingController(text: item?.quantity.toString() ?? '');
    _unitController = TextEditingController(text: item?.unit ?? '');
    _reorderPointController =
        TextEditingController(text: item?.reorderPoint.toString() ?? '');
    _priceController =
        TextEditingController(text: item?.price != null && item!.price > 0 ? item.price.toString() : '');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _currentImagePath = item?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _reorderPointController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
    });
  }

  Future<String?> _uploadImage(String itemId) async {
    if (_pickedImageBytes == null) return _currentImagePath;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('inventory_images/$itemId.jpg');
      final uploadTask = await ref.putData(
        _pickedImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Firebase Storage upload failed: $e. Using base64 fallback.');
      final base64Str = base64Encode(_pickedImageBytes!);
      return 'data:image/jpeg;base64,$base64Str';
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<InventoryProvider>();
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final itemId = widget.item?.id ?? now;

    setState(() => _isUploading = true);

    try {
      final uploadedImagePath = await _uploadImage(itemId).timeout(const Duration(seconds: 15));

      final newItem = InventoryItem(
        id: itemId,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        unit: _unitController.text.trim(),
        reorderPoint: int.parse(_reorderPointController.text.trim()),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imagePath: uploadedImagePath,
      );

      if (_isEditing) {
        await provider.updateItem(newItem).timeout(const Duration(seconds: 10));
      } else {
        await provider.addItem(newItem).timeout(const Duration(seconds: 10));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error saving item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save item. Please check your connection or Firebase rules. Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0056C6)),
                  SizedBox(height: 16),
                  Text('Saving item...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Image Picker ─────────────────────────────────────────
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF0056C6).withValues(alpha: 0.4),
                            width: 1.5,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _pickedImageBytes != null
                              // Newly picked image (bytes)
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      _pickedImageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Tap to change',
                                          style: TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : _currentImagePath != null && _currentImagePath!.isNotEmpty
                                  // Existing image from storage, base64, or asset
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ProductImage(
                                          imagePath: _currentImagePath,
                                          fit: BoxFit.cover,
                                          fallback: const Icon(
                                            Icons.image_not_supported,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Tap to change',
                                              style: TextStyle(color: Colors.white, fontSize: 11),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  // No image yet — placeholder
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 48,
                                          color: const Color(0xFF0056C6).withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to add a product photo',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Basic Info ───────────────────────────────────────────
                    _buildCard(
                      children: [
                        _buildField(
                          controller: _nameController,
                          label: 'Item Name',
                          icon: Icons.label_outline,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter item name' : null,
                        ),
                        _buildField(
                          controller: _categoryController,
                          label: 'Category',
                          icon: Icons.category_outlined,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter category' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Stock & Pricing ──────────────────────────────────────
                    _buildCard(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildField(
                                controller: _quantityController,
                                label: 'Quantity',
                                icon: Icons.numbers,
                                keyboardType: TextInputType.number,
                                validator: (v) => _validateInt(v, 'Quantity'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                controller: _unitController,
                                label: 'Unit',
                                icon: Icons.straighten,
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Enter unit' : null,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _reorderPointController,
                                label: 'Reorder Point',
                                icon: Icons.warning_amber_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) => _validateInt(v, 'Reorder Point'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                controller: _priceController,
                                label: 'Price (₱)',
                                icon: Icons.attach_money,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter price';
                                  if (double.tryParse(v) == null) return 'Invalid price';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Description ──────────────────────────────────────────
                    _buildCard(
                      children: [
                        _buildField(
                          controller: _descriptionController,
                          label: 'Description (Optional)',
                          icon: Icons.description_outlined,
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Save Button ──────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0056C6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text(_isEditing ? 'Save Changes' : 'Add Item'),
                      ),
                    ),

                    // ── Delete Button (edit only) ────────────────────────────
                    if (_isEditing) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            context
                                .read<InventoryProvider>()
                                .deleteItem(widget.item!.id);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Delete Item'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
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
        children: children
            .expand((w) => [w, const SizedBox(height: 12)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0056C6)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0056C6), width: 1.5),
        ),
      ),
    );
  }

  String? _validateInt(String? v, String fieldName) {
    if (v == null || v.isEmpty) return 'Enter $fieldName';
    if (int.tryParse(v) == null) return 'Enter a valid whole number';
    return null;
  }
}
