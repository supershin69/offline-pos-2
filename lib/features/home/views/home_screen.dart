import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/categories/data/category_bloc.dart';
import 'package:offline_pos/features/products/data/product_bloc.dart';
import 'cart_screen.dart'; // CartScreen သို့ Path လမ်းကြောင်း မှန်အောင် ချိန်ပေးပါ

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategoryId = 'All';

  final ValueNotifier<int> _cartCount = ValueNotifier<int>(0);
  final List<Map<String, dynamic>> _cartItems = [];

  // Scroll Controller for category chips
  final ScrollController _scrollController = ScrollController();
  bool _isAtStart = true;
  bool _isAtEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    _cartCount.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    setState(() {
      _isAtStart = _scrollController.offset <= 0;
      _isAtEnd =
          _scrollController.offset >=
          _scrollController.position.maxScrollExtent - 1;
    });
  }

  void _scrollLeft() {
    if (_isAtStart) return;
    _scrollController.animateTo(
      _scrollController.offset - 120,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    if (_isAtEnd) return;
    _scrollController.animateTo(
      _scrollController.offset + 120,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // 💡 Add To Cart Logic (ပါပြီးသား ပစ္စည်းဆိုလျှင် quantity တိုးမည်)
  void _addToCart(ItemWithActiveStock product) {
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => (item['product'] as ItemWithActiveStock).item.id == product.item.id,
      );

      if (index >= 0) {
        _cartItems[index]['quantity'] = (_cartItems[index]['quantity'] as int) + 1;
      } else {
        _cartItems.add({
          'product': product,
          'quantity': 1,
        });
      }

      _cartCount.value = _cartItems.fold(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.item.name} to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 💡 Cart Icon ကို နှိပ်လျှင် CartScreen သို့ သွားမည်
  void _showCart() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty!')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(cartItems: _cartItems),
      ),
    );

    // CartScreen မှ ပြန်ထွက်လာပါက Count ကို Sync ပြန်လုပ်ပေးခြင်း
    setState(() {
      _cartCount.value = _cartItems.fold(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );
    });
  }

  Widget _buildCategoryChip(String id, String label) {
    bool isSelected = _selectedCategoryId == id;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategoryId = id;
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: const Color(0xFF5945CB),
      side: BorderSide(
        color: isSelected ? const Color(0xFF5945CB) : Colors.grey.shade400,
        width: 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      body: Column(
        children: [
          // ---------- Header ----------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
          ),

          // ---------- Search bar ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),

          // ---------- Category Chips ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                List<Category> dbCategories = [];
                if (state is CategoryLoaded) {
                  dbCategories = state.categories;
                }

                return Row(
                  children: [
                    IconButton(
                      onPressed: _isAtStart ? null : _scrollLeft,
                      icon: Icon(
                        Icons.chevron_left,
                        color: _isAtStart ? Colors.grey : const Color(0xFF5945CB),
                        size: 28,
                      ),
                      padding: const EdgeInsets.all(1),
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      splashRadius: 20,
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryChip('All', 'All'),
                            const SizedBox(width: 4),
                            ...dbCategories.map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildCategoryChip(cat.id, cat.name),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isAtEnd ? null : _scrollRight,
                      icon: Icon(
                        Icons.chevron_right,
                        color: _isAtEnd ? Colors.grey : const Color(0xFF5945CB),
                        size: 28,
                      ),
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minHeight: 30,
                        minWidth: 30,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ---------- Product Grid ----------
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ProductLoaded) {
                  final itemsWithStock = state.products;
                  final query = _searchController.text.toLowerCase().trim();

                  final filteredItems = itemsWithStock.where((p) {
                    final matchSearch = p.item.name.toLowerCase().contains(query);
                    final matchCategory = _selectedCategoryId == 'All' ||
                        p.item.categoryId == _selectedCategoryId;
                    return matchSearch && matchCategory;
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return const Center(
                      child: Text('No products match your search'),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (ctx, index) {
                      final itemWithStock = filteredItems[index];

                      return ProductCard(
                        productWithStock: itemWithStock,
                        onAddToCart: () => _addToCart(itemWithStock),
                      );
                    },
                  );
                }

                if (state is ProductError) {
                  return Center(child: Text(state.message));
                }

                return const Center(child: Text('No Products Available'));
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================== ProductCard Widget ==================
class ProductCard extends StatefulWidget {
  final ItemWithActiveStock productWithStock;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.productWithStock,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isImageActive = false;

  String _formatPrice(int? price) => price != null ? '$price Ks' : 'No price';

  Widget _buildProductImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) =>
            const Icon(Icons.image_not_supported),
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

  @override
  Widget build(BuildContext context) {
    final item = widget.productWithStock.item;
    final stock = widget.productWithStock.activeStock;

    return Transform.scale(
      scale: _isImageActive ? 1.02 : 1.0,
      child: Card(
        elevation: _isImageActive ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isImageActive = true),
                onTapUp: (_) => setState(() => _isImageActive = false),
                onTapCancel: () => setState(() => _isImageActive = false),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: _buildProductImage(item.photoPath),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _formatPrice(stock?.sellPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFF5945CB),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: widget.onAddToCart,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF5945CB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}