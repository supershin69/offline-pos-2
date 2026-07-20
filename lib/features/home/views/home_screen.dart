import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/products/data/product_bloc.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';

// ─── Cart Item Model ─────────────────────────────────────────────────────────
class CartItem {
  final Item item;
  final int price;
  const CartItem(this.item, this.price);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryId = '';
  ItemSortType _sortBy = ItemSortType.nameAsc;

  late ProductBloc _bloc;
  late final ProductRepository _repository;

  // ─── Cart State ────────────────────────────────────────────────────────────
  final List<CartItem> _cart = [];
  final ValueNotifier<int> _cartCount = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // Using shared database connection
    _repository = ProductRepository(AppDatabase());
    _bloc = ProductBloc(_repository);
    _refreshProducts();
  }

  void _refreshProducts() {
    _bloc.add(
      MonitorProductStarted(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        categoryId: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
        sortBy: _sortBy,
      ),
    );
  }

  void _addToCart(Item item, int price) {
    _cart.add(CartItem(item, price));
    _cartCount.value = _cart.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showCart() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cart Items'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _cart.length,
            itemBuilder: (_, i) {
              final cartItem = _cart[i];
              return ListTile(
                title: Text(cartItem.item.name),
                trailing: Text('${cartItem.price} Ks'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _cart.clear();
              _cartCount.value = 0;
              Navigator.pop(ctx);
            },
            child: const Text('Clear Cart'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    _searchController.dispose();
    _cartCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF5945CB),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Welcome, Team 4',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_cart,
                          color: Color(0xFF5945CB),
                        ),
                        onPressed: _showCart,
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: ValueListenableBuilder<int>(
                          valueListenable: _cartCount,
                          builder: (_, count, __) {
                            if (count == 0) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Search Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (_) => _refreshProducts(),
              ),
            ),
            const SizedBox(height: 8),

            // ─── Category Chips ──────────────────────────────────────────────
            _buildCategoryChips(),
            const SizedBox(height: 8),

            // ─── Product Grid ────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refreshProducts(),
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
                              const Icon(Icons.error, size: 48, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(state.error!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshProducts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final products = state.products;

                      if (products.isEmpty) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            alignment: Alignment.center,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory, size: 64, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No products found',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: products.length,
                        itemBuilder: (ctx, index) {
                          final itemWithStock = products[index];
                          final item = itemWithStock.item;
                          final stock = itemWithStock.activeStock;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: _buildProductImage(item.photoPath),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      if (stock != null) ...[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${stock.sellPrice} Ks',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF5945CB),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Stock: ${stock.quantity}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '0 Ks',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              'No Stock',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      ElevatedButton(
                                        onPressed: (stock != null && stock.quantity > 0)
                                            ? () => _addToCart(item, stock.sellPrice)
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: (stock != null && stock.quantity > 0)
                                              ? const Color(0xFF5945CB)
                                              : Colors.grey,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(double.infinity, 30),
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text('Add', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }

                    return const Center(child: Text('Unknown state'));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category Chips ────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return StreamBuilder<List<Category>>(
      stream: _repository.db.select(_repository.db.categories).watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final categories = snapshot.data!;

        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildChip('All', ''),
              ...categories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _buildChip(cat.name, cat.id),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, String id) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = selected ? id : '';
            _refreshProducts();
          });
        },
        selectedColor: const Color(0xFF5945CB),
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  // ─── Product Image Helper ──────────────────────────────────────────────────
  Widget _buildProductImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          );
        } else {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported),
          );
        }
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported),
        );
      }
    }
  }
}