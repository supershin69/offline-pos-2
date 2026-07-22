import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/products/data/product_bloc.dart';
import 'package:offline_pos/features/categories/data/category_bloc.dart';

// ─── Cart Item Model ─────────────────────────────────────────────────────────
class CartItem {
  final Item item;
  final int price;
  int quantity;
  final int maxStock;

  CartItem({
    required this.item,
    required this.price,
    this.quantity = 1,
    required this.maxStock,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryId = '';
  final ItemSortType _sortBy = ItemSortType.nameAsc;

  final List<CartItem> _cart = [];
  final ValueNotifier<int> _cartCount = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBloc>().add(MonitorProductStarted());
      context.read<CategoryBloc>().add(MonitorCategoriesStarted());
    });
  }

  void _refreshProducts() {
    context.read<ProductBloc>().add(
      MonitorProductStarted(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        categoryId: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
        sortBy: _sortBy,
      ),
    );
  }

  void _updateCartCount() {
    _cartCount.value = _cart.fold(0, (sum, item) => sum + item.quantity);
  }

  void _addToCart(Item item, int price, int maxStock) {
    final existingIndex = _cart.indexWhere((c) => c.item.id == item.id);

    if (existingIndex >= 0) {
      if (_cart[existingIndex].quantity < maxStock) {
        _cart[existingIndex].quantity++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Increased ${item.name} quantity to ${_cart[existingIndex].quantity}'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Text('Not enough stock! Only $maxStock available.'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      _cart.add(CartItem(
        item: item,
        price: price,
        maxStock: maxStock,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${item.name} added to cart'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
    _updateCartCount();
  }

  @override
  void dispose() {
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
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryChips(),
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
    );
  }

  // ─── UI COMPONENTS ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF5945CB),
            radius: 22,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
              Text(
                'Team 4 POS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5945CB),
                ),
              ),
            ],
          ),
          const Spacer(),
          ValueListenableBuilder<int>(
            valueListenable: _cartCount,
            builder: (context, count, child) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 28,
                    color: Color(0xFF5945CB),
                  ),
                ),
                onPressed: () {
                  if (_cart.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cart is empty')),
                    );
                  } else {
                    _showCartBottomSheet();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _refreshProducts(),
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF5945CB)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is! CategoryLoaded) return const SizedBox(height: 50);
        return SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final id = i == 0 ? '' : state.categories[i - 1].id;
              final name = i == 0 ? 'All' : state.categories[i - 1].name;
              final isSelected = _selectedCategoryId == id;
              return ChoiceChip(
                label: Text(name),
                selected: isSelected,
                selectedColor: const Color(0xFF5945CB),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                onSelected: (s) {
                  setState(() {
                    _selectedCategoryId = id;
                    _refreshProducts();
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is! ProductLoaded) return const SizedBox.shrink();

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: state.products.length,
          itemBuilder: (ctx, index) {
            final item = state.products[index].item;
            final stock = state.products[index].activeStock;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: _buildProductImage(item.photoPath),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${stock?.sellPrice ?? 0} Ks',
                              style: const TextStyle(
                                color: Color(0xFF5945CB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (stock != null && stock.quantity > 0)
                                ? () => _addToCart(
                                      item,
                                      stock.sellPrice,
                                      stock.quantity,
                                    )
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5945CB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── CART BOTTOM SHEET ─────────────────────────────────────────────────────
  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final totalAmount = _cart.fold<int>(
              0,
              (sum, item) => sum + (item.price * item.quantity),
            );

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Cart',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(
                            child: Text(
                              'Cart is empty',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (ctx, index) {
                              final cartItem = _cart[index];
                              return ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildProductImage(
                                      cartItem.item.photoPath,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cartItem.item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text('${cartItem.price} Ks'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          if (cartItem.quantity > 1) {
                                            cartItem.quantity--;
                                          } else {
                                            _cart.removeAt(index);
                                          }
                                        });
                                        _updateCartCount();
                                      },
                                    ),
                                    Text(
                                      '${cartItem.quantity}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        color:
                                            cartItem.quantity < cartItem.maxStock
                                                ? Colors.green
                                                : Colors.grey,
                                      ),
                                      onPressed:
                                          cartItem.quantity < cartItem.maxStock
                                              ? () {
                                                  setModalState(() {
                                                    cartItem.quantity++;
                                                  });
                                                  _updateCartCount();
                                                }
                                              : null,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -4),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '$totalAmount Ks',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5945CB),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _cart.isEmpty
                                ? null
                                : () {
                                    // Checkout logic here
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5945CB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Checkout',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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