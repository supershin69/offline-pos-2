import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/categories/views/category_screen.dart';
import 'package:offline_pos/features/products/data/product_bloc.dart';
import 'package:offline_pos/features/products/views/add_product_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    // main.dart ရှိ Global ProductBloc ဆီသို့ Event ပေးပို့ခြင်း
    context.read<ProductBloc>().add(
          MonitorProductStarted(
            search: _searchController.text.trim(),
            categoryId: _selectedCategoryId,
          ),
        );
  }

  // ─── Navigate to AddProductScreen for new product ──────────────
  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (result == true && mounted) {
      _loadProducts();
    }
  }

  // ─── Navigate to AddProductScreen for editing ───────────────────
  Future<void> _navigateToEditProduct(ItemWithActiveStock product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(editProduct: product),
      ),
    );
    if (result == true && mounted) {
      _loadProducts();
    }
  }

  // ─── Open Category Screen and Filter ────────────────────────────
  void _openCategoryList() async {
    final selectedCatId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryScreen(),
      ),
    );

    if (selectedCatId != null && mounted) {
      setState(() => _selectedCategoryId = selectedCatId);
      _loadProducts();
    }
  }

  // ─── Delete product with confirmation ──────────────────────────
  Future<void> _deleteProduct(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<ProductBloc>().add(DeleteProductRequested(id: id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        title: const Text('Item List'),
        backgroundColor: const Color(0xFF5945CB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddProduct,
            tooltip: 'Add Product',
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _openCategoryList,
            tooltip: 'Manage Categories',
          ),
        ],
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductLoaded && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            // ─── Search bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Item',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF5945CB)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _loadProducts();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (value) => _loadProducts(),
              ),
            ),

            // ─── Item count ────────────────────────────────────────────
            BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                int count = 0;
                if (state is ProductLoaded) {
                  count = state.products.length;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$count Items',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      if (_selectedCategoryId != null)
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategoryId = null);
                            _loadProducts();
                          },
                          child: const Text(
                            'Clear Category Filter',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5945CB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 6),

            // ─── Filter chips ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Low Stock'),
                  _buildFilterChip('Near Exp'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ─── Product list ──────────────────────────────────────────
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ProductLoaded) {
                    if (state.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 8),
                            Text(state.error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Filter list on client side based on Filter Chip
                    var products = state.products;
                    if (_selectedFilter == 'Low Stock') {
                      products = products.where((p) {
                        final qty = p.activeStock?.quantity ?? 0;
                        return qty <= 5;
                      }).toList();
                    } else if (_selectedFilter == 'Near Exp') {
                      final now = DateTime.now();
                      products = products.where((p) {
                        final exp = p.activeStock?.stockInDate;
                        if (exp == null) return false;
                        final daysDifference = exp.difference(now).inDays;
                        return daysDifference <= 30 && daysDifference >= 0;
                      }).toList();
                    }

                    if (products.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap + to add items',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      itemCount: products.length,
                      itemBuilder: (ctx, index) {
                        final itemWithStock = products[index];
                        final item = itemWithStock.item;
                        final stock = itemWithStock.activeStock;

                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            // ─── Image thumbnail ──────────────
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildProductImage(item.photoPath, 50, 50),
                            ),
                            // ─── Name, price, stock ──────────────────
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  stock != null
                                      ? '${stock.sellPrice} Ks'
                                      : 'No price',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5945CB),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  stock != null
                                      ? 'Stock: ${stock.quantity}'
                                      : 'Out of stock',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: (stock?.quantity ?? 0) > 5
                                        ? Colors.grey.shade700
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            // ─── Edit & Delete buttons ──────
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _navigateToEditProduct(itemWithStock),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _deleteProduct(item.id, item.name),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return const Center(child: Text('Unknown state'));
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        backgroundColor: const Color(0xFF5945CB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ─── Helper: build filter chip widget ────────────────────────────
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: ChoiceChip(
          label: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = label;
            });
          },
          selectedColor: const Color(0xFF5945CB),
          backgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          showCheckmark: false,
        ),
      ),
    );
  }

  // ─── Helper: build a thumbnail image ─────────────────────────────
  Widget _buildProductImage(String path, double width, double height) {
    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey, size: 28),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        } else {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        }
      } catch (e) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      }
    }
  }
}