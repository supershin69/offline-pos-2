import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/products/data/product_bloc.dart';
import 'package:offline_pos/features/products/models/item_with_quantity.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';
import 'package:path_provider/path_provider.dart';

// ───────────────────────────────────────────────────────────────
// ProductScreen (list + FAB to open AddProductPage)
// ───────────────────────────────────────────────────────────────
class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final ProductRepository _repository;
  late final ProductBloc _bloc;
  List<Category> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _repository = ProductRepository(AppDatabase());
    _bloc = ProductBloc(_repository)..add(MonitorProductStarted());
    _loadCategories();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await (_repository.db.select(_repository.db.categories)).get();
    setState(() => _categories = cats);
  }

  Future<void> _showAddCategoryDialog(VoidCallback onSaved) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await _repository.db
                    .into(_repository.db.categories)
                    .insert(CategoriesCompanion.insert(name: name));
                await _loadCategories();
                onSaved();
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5945CB),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(
    Category category,
    VoidCallback onDeleted,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await (_repository.db.delete(
        _repository.db.categories,
      )..where((tbl) => tbl.id.equals(category.id))).go();
      if (_selectedCategoryId == category.id) {
        setState(() => _selectedCategoryId = null);
      }
      await _loadCategories();
      onDeleted();
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductPage(repository: _repository, bloc: _bloc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: const Color(0xFF5945CB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state is ProductInitial)
            return const Center(child: CircularProgressIndicator());
          if (state is ProductLoaded) {
            final products = state.products;
            if (products.isEmpty) {
              return const Center(
                child: Text('No products found. Tap + to add one.'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (ctx, index) {
                final itemWithQty = products[index];
                final item = itemWithQty.item;
                final quantity = itemWithQty.quantity;
                final bool isLocalFile =
                    item.photoUrl.isNotEmpty &&
                    !item.photoUrl.startsWith('http');
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: isLocalFile
                          ? Image.file(
                              File(item.photoUrl),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            )
                          : Image.network(
                              item.photoUrl.isEmpty
                                  ? 'https://via.placeholder.com/150'
                                  : item.photoUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Buy: ${item.buyPrice} Ks · Sell: ${item.sellPrice} Ks · Qty: $quantity',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5945CB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$quantity variants',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5945CB),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Something went wrong'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        backgroundColor: const Color(0xFF5945CB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// AddProductPage – Full‑screen upload form with custom category dropdown + delete
// ───────────────────────────────────────────────────────────────
class AddProductPage extends StatefulWidget {
  final ProductRepository repository;
  final ProductBloc bloc;
  const AddProductPage({
    super.key,
    required this.repository,
    required this.bloc,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  DateTime? _expDate;
  DateTime? _alertDate;
  String? _selectedImagePath;
  String? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isCategoryListOpen = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await widget.repository.db
        .select(widget.repository.db.categories)
        .get();
    setState(() => _categories = cats);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${appDir.path}/products/$fileName');
      await savedFile.create(recursive: true);
      await File(image.path).copy(savedFile.path);
      setState(() => _selectedImagePath = savedFile.path);
    }
  }

  Future<void> _selectDate(bool isExp) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isExp)
          _expDate = picked;
        else
          _alertDate = picked;
      });
    }
  }

  // ─── Category CRUD inside the page ──────────────────────────────
  Future<void> _addCategory() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await widget.repository.db
                    .into(widget.repository.db.categories)
                    .insert(CategoriesCompanion.insert(name: name));
                await _loadCategories();
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5945CB),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await (widget.repository.db.delete(
        widget.repository.db.categories,
      )..where((tbl) => tbl.id.equals(category.id))).go();
      if (_selectedCategoryId == category.id) {
        setState(() => _selectedCategoryId = null);
      }
      await _loadCategories();
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
      _isCategoryListOpen = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final buyPrice = int.tryParse(_buyPriceController.text.trim());
    final sellPrice = int.tryParse(_sellPriceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    if (name.isEmpty ||
        buyPrice == null ||
        sellPrice == null ||
        _selectedCategoryId == null) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    final photoUrl = _selectedImagePath ?? '';
    final companion = ItemsCompanion.insert(
      categoryId: _selectedCategoryId!,
      name: name,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      photoUrl: photoUrl.isEmpty ? 'https://via.placeholder.com/150' : photoUrl,
    );

    widget.bloc.add(AddProductRequested(item: companion));
    _clearAll();
    _showSnackBar('Product added successfully');
    Navigator.pop(context);
  }

  // ─── Custom Category Dropdown with delete cross ──────────────────
  Widget _buildCategoryDropdown() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 8), // slight gap below the field
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      onSelected: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedCategoryId != null
                    ? _categories
                          .firstWhere(
                            (cat) => cat.id == _selectedCategoryId,
                            orElse: () => _categories.first,
                          )
                          .name
                    : 'Select Category',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedCategoryId != null
                      ? Colors.black
                      : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = [];

        // ─── Category items ──────────────────────────────────────────────
        for (var cat in _categories) {
          items.add(
            PopupMenuItem<String>(
              value: cat.id,
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Text(
                        cat.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  // Delete button 
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // close menu
                      _deleteCategory(cat);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ─── Divider ─────────────────────────────────────────────────────
        if (_categories.isNotEmpty) {
          items.add(const PopupMenuDivider());
        }

        // ─── Add new category ──────────────────────────────────────────
        items.add(
          PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.all(1),
            child: ListTile(
              leading: const Icon(Icons.add_box, color: Color(0xFF5945CB)),
              title: const Text(
                'Add New Category',
                style: TextStyle(
                  color: Color(0xFF5945CB),
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _addCategory();
              },
            ),
          ),
        );

        return items;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      isDense: true,
    );
    const labelStyle = TextStyle(fontSize: 14);
    const valueStyle = TextStyle(fontSize: 14);

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        title: const Text('Add Product'),
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
                // Image upload
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF5945CB).withOpacity(0.3),
                      ),
                      image: _selectedImagePath != null
                          ? DecorationImage(
                              image: FileImage(File(_selectedImagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImagePath == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Color(0xFF5945CB),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Upload Image',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),

                // Product ID (auto)
                TextFormField(
                  initialValue: '${DateTime.now().millisecondsSinceEpoch}',
                  readOnly: true,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Product ID',
                    labelStyle: labelStyle,
                  ),
                  style: valueStyle,
                ),
                const SizedBox(height: 10),

                // Product Name
                TextFormField(
                  controller: _nameController,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Product Name',
                    labelStyle: labelStyle,
                  ),
                  style: valueStyle,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 10),

                // Buy / Sell Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buyPriceController,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Buy Price',
                          labelStyle: labelStyle,
                        ),
                        style: valueStyle,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Required'
                            : (int.tryParse(v.trim()) != null
                                  ? null
                                  : 'Enter a number'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _sellPriceController,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Sell Price',
                          labelStyle: labelStyle,
                        ),
                        style: valueStyle,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Required'
                            : (int.tryParse(v.trim()) != null
                                  ? null
                                  : 'Enter a number'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Exp / Alert Date
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
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
                                  fontSize: 14,
                                  color: _expDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
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
                                  fontSize: 14,
                                  color: _alertDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ─── Custom Category Dropdown + Stock ──────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child:
                          _buildCategoryDropdown(), // custom dropdown with delete cross
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Stock',
                          labelStyle: labelStyle,
                        ),
                        style: valueStyle,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v != null &&
                              v.isNotEmpty &&
                              int.tryParse(v.trim()) == null) {
                            return 'Enter a number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 70),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text(
                          'Clear All',
                          style: TextStyle(fontSize: 14),
                        ),
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
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5945CB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Item',
                          style: TextStyle(fontSize: 14),
                        ),
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
