import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:offline_pos/core/database/database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryId = '';
  final ScrollController _scrollController = ScrollController();
  bool _isAtStart = true;
  bool _isAtEnd = false;

  final _db = AppDatabase();

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
    _scrollController.animateTo(
      _scrollController.offset - 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _formatPrice(int price) => '$price Ks';

  Widget _buildCategoryChip(String id, String name) {
    bool isSelected = _selectedCategoryId == id;
    return ChoiceChip(
      label: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedCategoryId = isSelected ? '' : id;
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
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Category>>(
            stream: _db.select(_db.categories).watch(),
            builder: (context, catSnapshot) {
              if (catSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final categories = catSnapshot.data ?? [];
              final allChips = [
                _buildCategoryChip('', 'All'),
                const SizedBox(width: 8),
                ...categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildCategoryChip(cat.id, cat.name),
                  ),
                ),
              ];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _isAtStart ? null : _scrollLeft,
                      icon: Icon(
                        Icons.chevron_left,
                        color: _isAtStart
                            ? Colors.grey
                            : const Color(0xFF5945CB),
                        size: 28,
                      ),
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      splashRadius: 20,
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: Scrollbar(
                          thumbVisibility: true,
                          thickness: 4,
                          radius: const Radius.circular(10),
                          child: ListView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2.0,
                            ),
                            children: allChips,
                          ),
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
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<List<Category>>(
      stream: _db.select(_db.categories).watch(),
      builder: (context, catSnapshot) {
        if (catSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = catSnapshot.data ?? [];
        final Map<String, String> categoryMap = {
          for (var cat in categories) cat.id: cat.name,
        };

        return StreamBuilder<List<Item>>(
          stream: _db.select(_db.items).watch(),
          builder: (context, itemSnapshot) {
            if (itemSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!itemSnapshot.hasData || itemSnapshot.data!.isEmpty) {
              return const Center(child: Text('No products available.'));
            }

            final items = itemSnapshot.data!;
            final query = _searchController.text.toLowerCase();

            final filtered = items.where((item) {
              final nameMatch = item.name.toLowerCase().contains(query);
              final categoryMatch =
                  _selectedCategoryId.isEmpty ||
                  item.categoryId == _selectedCategoryId;
              return nameMatch && categoryMatch;
            }).toList();

            if (filtered.isEmpty) {
              return const Center(child: Text('No products match your search'));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.61,
              ),
              itemCount: filtered.length,
              itemBuilder: (ctx, index) {
                final item = filtered[index];
                final product = Product(
                  name: item.name,
                  category: categoryMap[item.categoryId] ?? 'Uncategorized',
                  price: item.sellPrice,
                  imageUrl: item.photoUrl,
                );
                return ProductCard(product: product);
              },
            );
          },
        );
      },
    );
  }
}

// ─── Product model ──────────────────────────────────────────────────
class Product {
  final String name;
  final String category;
  final int price;
  final String imageUrl;

  Product({
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
  });
}

// ─── ProductCard widget ────────────────────────────────────────────
class ProductCard extends StatefulWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isImageActive = false;

  String _formatPrice(int price) => '$price Ks';

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _isImageActive ? 1.02 : 1.0,
      child: Card(
        elevation: _isImageActive ? 12 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Image with fallback ──────────────────────────────
            GestureDetector(
              onTapDown: (_) => setState(() => _isImageActive = true),
              onTapUp: (_) => setState(() => _isImageActive = false),
              onTapCancel: () => setState(() => _isImageActive = false),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isImageActive = true),
                onExit: (_) => setState(() => _isImageActive = false),
                child: SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ),
            ),
            // ─── Product info ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(9.0),
              child: Column(
                children: [
                  // Product name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // slightly larger for readability
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Sell price (with label)
                  Text(
                    'Sell: ${_formatPrice(widget.product.price)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF5945CB),
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 6),
                  // Add button (icon only)
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${widget.product.name}'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5945CB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(40, 30),
                      padding: const EdgeInsets.all(4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) {
                          if (states.contains(WidgetState.hovered) ||
                              states.contains(WidgetState.pressed)) {
                            return const Color(0xFF5945CB).withOpacity(0.8);
                          }
                          return const Color(0xFF5945CB);
                        },
                      ),
                      elevation: WidgetStateProperty.resolveWith(
                        (states) {
                          if (states.contains(WidgetState.hovered) ||
                              states.contains(WidgetState.pressed)) {
                            return 8.0;
                          }
                          return 2.0;
                        },
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
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