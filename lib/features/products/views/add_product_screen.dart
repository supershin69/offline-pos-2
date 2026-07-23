import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/categories/views/category_screen.dart';
import 'package:offline_pos/features/products/data/product_bloc.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';

class AddProductScreen extends StatefulWidget {
  final ItemWithActiveStock? editProduct;
  const AddProductScreen({super.key, this.editProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  // States
  String? _selectedImagePath;
  String? _selectedCategoryId;
  List<Category> _categories = [];
  DateTime? _expDate;
  DateTime? _alertDate;
  bool _isSaving = false;
  bool _isEditing = false;

  late final ProductRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<ProductRepository>();
    _loadCategories();

    // ─── Edit mode: pre‑fill fields ────────────────────────────────
    if (widget.editProduct != null) {
      _isEditing = true;
      final product = widget.editProduct!;
      _nameController.text = product.item.name;
      _selectedCategoryId = product.item.categoryId;
      _selectedImagePath = product.item.photoPath;
      if (product.activeStock != null) {
        _buyPriceController.text = product.activeStock!.buyPrice.toString();
        _sellPriceController.text = product.activeStock!.sellPrice.toString();
        _stockController.text = product.activeStock!.quantity.toString();
        _expDate = product.activeStock!.stockInDate;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _repository.db.select(_repository.db.categories).get();
      if (mounted) {
        setState(() => _categories = cats);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load categories', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  Future<void> _selectDate(bool isExp) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isExp) {
          _expDate = picked;
        } else {
          _alertDate = picked;
        }
      });
    }
  }

  void _clearAll() {
    setState(() {
      _nameController.clear();
      _buyPriceController.clear();
      _sellPriceController.clear();
      _stockController.clear();
      _selectedImagePath = null;
      _selectedCategoryId = null;
      _expDate = null;
      _alertDate = null;
    });
  }

  Future<void> _navigateToCategoryScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryScreen()),
    );
    _loadCategories();
  }

  // ─── Save / Update Logic ──────────────────────────────────────────
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      _showSnackBar('Please select a category', isError: true);
      return;
    }

    final name = _nameController.text.trim();
    final buyPrice = int.tryParse(_buyPriceController.text.trim()) ?? 0;
    final sellPrice = int.tryParse(_sellPriceController.text.trim()) ?? 0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    setState(() => _isSaving = true);

    try {
      // 💡 Image File အမှန်တကယ် ရှိ၊ မရှိ စစ်ဆေးခြင်း
      File? imageFile;
      if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
        final checkFile = File(_selectedImagePath!);
        if (checkFile.existsSync()) {
          imageFile = checkFile;
        } else {
          debugPrint('Warning: Image path does not exist on disk: $_selectedImagePath');
        }
      }

      if (_isEditing) {
        // ─── 1. Update Existing Product ──────────────────────────────
        final itemCompanion = ItemsCompanion(
          id: drift.Value(widget.editProduct!.item.id),
          categoryId: drift.Value(_selectedCategoryId!),
          name: drift.Value(name),
          photoPath: drift.Value(_selectedImagePath ?? ''),
          updatedAt: drift.Value(DateTime.now()),
        );

        await _repository.updateProduct(
          widget.editProduct!.item.id,
          itemCompanion,
          imageFile, // Safe ဖြစ်သွားသည့် imageFile ပို့ပေးမည်
        );

        // Update Stock Batch
        final batch = StockBatchesCompanion.insert(
          itemId: widget.editProduct!.item.id,
          quantity: stock,
          buyPrice: buyPrice,
          sellPrice: sellPrice,
          stockInDate: drift.Value(_expDate ?? DateTime.now()),
        );
        await _repository.restockItems([batch]);

        if (mounted) {
          _showSnackBar('Product updated successfully!');
        }
      } else {
        // ─── 2. Add New Product Safe Pattern ─────────────────────────
        final companion = ItemsCompanion.insert(
          categoryId: _selectedCategoryId!,
          name: name,
          photoPath: _selectedImagePath ?? '',
        );

        final insertedItem = await _repository.db.into(_repository.db.items).insertReturning(companion);

        final batch = StockBatchesCompanion.insert(
          itemId: insertedItem.id,
          quantity: stock,
          buyPrice: buyPrice,
          sellPrice: sellPrice,
          stockInDate: drift.Value(_expDate ?? DateTime.now()),
        );
        await _repository.restockItems([batch]);

        if (mounted) {
          _showSnackBar('Product added successfully!');
        }
      }

      if (mounted) {
        context.read<ProductBloc>().add(MonitorProductStarted());
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildField({
    required String label,
    required Widget field,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      isDense: true,
    );

    // 💡 Category list ထဲမှာ selected id ရှိ မရှိ စစ်ဆေးထားခြင်း
    final bool isCategoryValid = _categories.any((cat) => cat.id == _selectedCategoryId);

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: const Color(0xFF5945CB),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Image Upload ────────────────────────────────────
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF5945CB).withOpacity(0.3),
                      ),
                      image: _selectedImagePath != null &&
                              _selectedImagePath!.isNotEmpty &&
                              File(_selectedImagePath!).existsSync()
                          ? DecorationImage(
                              image: FileImage(File(_selectedImagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImagePath == null ||
                            _selectedImagePath!.isEmpty ||
                            !File(_selectedImagePath!).existsSync()
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 36, color: Color(0xFF5945CB)),
                              SizedBox(height: 6),
                              Text('Upload Image', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Product Name ────────────────────────────────────
                _buildField(
                  label: 'Product Name',
                  isRequired: true,
                  field: TextFormField(
                    controller: _nameController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Enter product name',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Buy Price + Sell Price ───────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Buy Price',
                        isRequired: true,
                        field: TextFormField(
                          controller: _buyPriceController,
                          decoration: inputDecoration.copyWith(
                            hintText: '0',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        label: 'Sell Price',
                        isRequired: true,
                        field: TextFormField(
                          controller: _sellPriceController,
                          decoration: inputDecoration.copyWith(
                            hintText: '0',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ─── EXP Date + Alert Date ────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'EXP Date',
                        isRequired: false,
                        field: GestureDetector(
                          onTap: () => _selectDate(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _expDate != null
                                      ? '${_expDate!.day}/${_expDate!.month}/${_expDate!.year}'
                                      : 'DD/MM/YYYY',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _expDate != null ? Colors.black : Colors.grey,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF5945CB)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        label: 'Alert Date',
                        isRequired: false,
                        field: GestureDetector(
                          onTap: () => _selectDate(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _alertDate != null
                                      ? '${_alertDate!.day}/${_alertDate!.month}/${_alertDate!.year}'
                                      : 'DD/MM/YYYY',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _alertDate != null ? Colors.black : Colors.grey,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF5945CB)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ─── Category ────────────────────────────────────────
                _buildField(
                  label: 'Category',
                  isRequired: true,
                  field: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: inputDecoration.copyWith(
                            hintText: 'Select Category',
                          ),
                          value: isCategoryValid ? _selectedCategoryId : null,
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedCategoryId = value),
                          validator: (v) => v == null ? 'Select a category' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Color(0xFF5945CB)),
                        onPressed: _navigateToCategoryScreen,
                        tooltip: 'Manage Categories',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Stock ───────────────────────────────────────────
                _buildField(
                  label: 'Stock Quantity',
                  isRequired: true,
                  field: TextFormField(
                    controller: _stockController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Enter stock quantity',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Action Buttons ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5945CB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isEditing ? 'Update Item' : 'Save Item'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}