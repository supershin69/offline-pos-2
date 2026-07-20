import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/categories/views/category_screen.dart';
import 'package:offline_pos/features/products/data/product_bloc.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';
import 'package:offline_pos/features/products/views/add_product_screen.dart';
import 'dart:io';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  late ProductBloc _bloc;
  late final ProductRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = ProductRepository(AppDatabase());
    _bloc = ProductBloc(_repository);
    _bloc.add(MonitorProductStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Navigate to AddProductScreen for new product ──────────────
  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
  }

  // ─── Navigate to AddProductScreen for editing ───────────────────
  void _navigateToEditProduct(ItemWithActiveStock product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(editProduct: product)),
    );
  }

  void _openCategoryList() async {
    // Wait for the CategoryScreen to return a selected category ID
    final selectedCategoryId = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryScreen(), // Your existing screen
      ),
    );

    // If a category was chosen, filter the items
    if (selectedCategoryId != null) {
      _bloc.add(
        MonitorProductStarted(
          search: _searchController.text,
          categoryId: selectedCategoryId,
        ),
      );
    }
  }

  // ─── Delete product with confirmation ──────────────────────────
  Future<void> _deleteProduct(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
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
      _bloc.add(DeleteProductRequested(id: id));
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
            onPressed: _navigateToAddProduct ,
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _openCategoryList ,
            tooltip: 'Manage Categories',
          ),
        ],
      ),
      body: BlocListener<ProductBloc, ProductState>(
        bloc: _bloc,
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
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (value) {
                  _bloc.add(MonitorProductStarted(search: value));
                },
              ),
            ),
            // ─── Item count ────────────────────────────────────────────
            BlocBuilder<ProductBloc, ProductState>(
              bloc: _bloc,
              builder: (context, state) {
                int count = 0;
                if (state is ProductLoaded) {
                  count = state.products.length;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Text(
                        '$count Items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            // ─── Filter chips ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
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
            // ─── Product list (table layout with image) ──────────────
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                bloc: _bloc,
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
                              Icons.error,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 8),
                            Text(state.error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _bloc.add(MonitorProductStarted());
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final products = state.products;
                    if (products.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory, size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No products found'),
                            SizedBox(height: 8),
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
                        vertical: 8.0,
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
                            // ─── Image thumbnail (left) ──────────────
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildProductImage(item.photoPath, 50, 50),
                            ),
                            // ─── Name, price, stock (right) ──────────
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
                                    color: Color(0xFF5945CB),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  stock != null
                                      ? 'Stock${stock.quantity}'
                                      : 'Out of stock',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: stock != null
                                        ? Colors.grey
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            // ─── Edit & Delete buttons (right) ──────
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
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                ),
                                const SizedBox(width: 4),
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
                                    minWidth: 40,
                                    minHeight: 40,
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
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = label;
            });
          },
          selectedColor: const Color(0xFF5945CB),
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
        child: const Icon(Icons.image, color: Colors.grey, size: 30),
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
