// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:offline_pos/core/database/database.dart'; // adjust path

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final TextEditingController _searchController = TextEditingController();

//   // Access the global database instance
//   final db = AppDatabase(); // or use the global 'db' variable

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   String _formatPrice(int price) => '$price Ks';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF3EFFF),
//       body: Column(
//         children: [
//           // ---------- Header (unchanged) ----------
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   const CircleAvatar(
//                     backgroundColor: Color(0xFF5945CB),
//                     child: Icon(Icons.person, color: Colors.white),
//                   ),
//                   const SizedBox(width: 12),
//                   const Text(
//                     'Welcome, Team 4',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const Spacer(),
//                 ],
//               ),
//             ),
//           ),
//           // ---------- Search bar (unchanged) ----------
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search items...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 8),
//               ),
//               onChanged: (_) => setState(() {}),
//             ),
//           ),
//           const SizedBox(height: 16),
//           // ---------- Product grid from database ----------
//           Expanded(
//             child: StreamBuilder<List<Item>>(
//               stream: db.select(db.items).watch(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return const Center(child: Text('No products available.'));
//                 }

//                 final items = snapshot.data!;

//                 // Filter items based on search only (no category filter)
//                 final query = _searchController.text.toLowerCase();
//                 final filtered = items.where((item) {
//                   return item.name.toLowerCase().contains(query);
//                 }).toList();

//                 if (filtered.isEmpty) {
//                   return const Center(child: Text('No products match your search'));
//                 }

//                 return GridView.builder(
//                   padding: const EdgeInsets.all(10),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 10,
//                     childAspectRatio: 0.61,
//                   ),
//                   itemCount: filtered.length,
//                   itemBuilder: (ctx, index) {
//                     final item = filtered[index];
//                     // Map Item → Product
//                     // final product = Product(
//                     //   name: item.name,
//                     //   category: item.category ?? 'Uncategorized',
//                     //   price: item.price,
//                     //   imageUrl: item.imageUrl ?? '',
//                     // );
//                     // return ProductCard(product: product);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ================== Product Model ==================
// class Product {
//   final String name;
//   // final String category;
//   final int price;
//   final String imageUrl;

//   Product({
//     required this.name,
//     // required this.category,
//     required this.price,
//     required this.imageUrl,
//   });
// }

// // ================== ProductCard Widget (unchanged) ==================
// class ProductCard extends StatefulWidget {
//   final Product product;
//   const ProductCard({super.key, required this.product});

//   @override
//   State<ProductCard> createState() => _ProductCardState();
// }

// class _ProductCardState extends State<ProductCard> {
//   bool _isImageActive = false;

//   String _formatPrice(int price) => '$price Ks';

//   @override
//   Widget build(BuildContext context) {
//     return Transform.scale(
//       scale: _isImageActive ? 1.02 : 1.0,
//       child: Card(
//         elevation: _isImageActive ? 12 : 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Image with hover/press effect (only image triggers card scale)
//             GestureDetector(
//               onTapDown: (_) => setState(() => _isImageActive = true),
//               onTapUp: (_) => setState(() => _isImageActive = false),
//               onTapCancel: () => setState(() => _isImageActive = false),
//               child: MouseRegion(
//                 onEnter: (_) => setState(() => _isImageActive = true),
//                 onExit: (_) => setState(() => _isImageActive = false),
//                 child: SizedBox(
//                   height: 180,
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(12),
//                     ),
//                     child: CachedNetworkImage(
//                       imageUrl: widget.product.imageUrl,
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       placeholder: (context, url) => const Center(
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                       errorWidget: (context, url, error) =>
//                           const Icon(Icons.image_not_supported),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             // Content (name, price, Add button)
//             Padding(
//               padding: const EdgeInsets.all(9.0),
//               child: Column(
//                 children: [
//                   Text(
//                     widget.product.name,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 10,
//                     ),
//                     textAlign: TextAlign.center,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           _formatPrice(widget.product.price),
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 12,
//                             color: Color.fromRGBO(89, 69, 203, 1),
//                           ),
//                           textAlign: TextAlign.left,
//                         ),
//                       ),
//                       // Add button
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('Added ${widget.product.name}'),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.add, size: 14, color: Colors.white),
//                         label: const Text('Add', style: TextStyle(fontSize: 10)),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF5945CB),
//                           foregroundColor: Colors.white,
//                           minimumSize: const Size(60, 26),
//                           padding: const EdgeInsets.symmetric(horizontal: 6),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                         ).copyWith(
//                           backgroundColor:
//                               WidgetStateProperty.resolveWith((states) {
//                             if (states.contains(WidgetState.hovered) ||
//                                 states.contains(WidgetState.pressed)) {
//                               return Colors.indigo.shade800;
//                             }
//                             return Colors.indigo;
//                           }),
//                           elevation:
//                               WidgetStateProperty.resolveWith((states) {
//                             if (states.contains(WidgetState.hovered) ||
//                                 states.contains(WidgetState.pressed)) {
//                               return 8.0;
//                             }
//                             return 2.0;
//                           }),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:offline_pos/mock_data.dart'; // adjust import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  // ---------- Scroll Controller for category chips ----------
  final ScrollController _scrollController = ScrollController();
  bool _isAtStart = true;
  bool _isAtEnd = false;

  // ---------- Mock data (or switch to DB) ----------
  final List<Product> _allProducts = getMockProducts(); // from mock_data.dart

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

  // ---------- Getters for categories and filtered products ----------
  List<String> get _categories {
    final cats = _allProducts.map((p) => p.category).toSet().toList();
    cats.insert(0, 'All');
    return cats;
  }

  List<Product> get _filteredProducts {
    final query = _searchController.text.toLowerCase();
    return _allProducts.where((p) {
      final matchSearch = p.name.toLowerCase().contains(query);
      final matchCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  String _formatPrice(int price) => '$price Ks';

  // ---------- Build category chip ----------
  Widget _buildCategoryChip(String category, String label) {
    bool isSelected = _selectedCategory == category;
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
          _selectedCategory = category;
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Color(0xFF5945CB),
      side: BorderSide(
        color: isSelected ? Color(0xFF5945CB) : Colors.grey.shade400,
        width: 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3EFFF),
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
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          // ---------- Category chips with arrow buttons ----------
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
          //   child: Row(
          //     children: [
          //       // Left arrow button
          //       IconButton(
          //         onPressed: _isAtStart ? null : _scrollLeft,
          //         icon: Icon(
          //           Icons.chevron_left,
          //           color: _isAtStart ? Colors.grey : Color(0xFF5945CB),
          //           size: 28,
          //         ),
          //         padding: EdgeInsets.all(1),
          //         constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          //         splashRadius: 20,
          //       ),
          //       // Scrollable chips
          //       Expanded(
          //         child: SizedBox(
          //           height: 40,
          //           child: Scrollbar(
          //             // thumbVisibility: true,
          //             // thickness: 5,
          //             radius: const Radius.circular(10),
          //             child: ListView(
          //               controller: _scrollController,
          //               scrollDirection: Axis.horizontal,
          //               padding: const EdgeInsets.symmetric(horizontal: 0.0),
          //               children: [
          //                 _buildCategoryChip('All', 'All'),
          //                 const SizedBox(width: 4),
          //                 ..._categories
          //                     .where((cat) => cat != 'All')
          //                     .map((cat) => Padding(
          //                           padding: const EdgeInsets.only(right: 8.0),
          //                           child: _buildCategoryChip(cat, cat),
          //                         )),
          //               ],
          //             ),
          //           ),
          //         ),
          //       ),
          //       // Right arrow button
          //       IconButton(
          //         onPressed: _isAtEnd ? null : _scrollRight,
          //         icon: Icon(
          //           Icons.chevron_right,
          //           color: _isAtEnd ? Colors.grey : Color(0xFF5945CB),
          //           size: 28,
          //         ),
          //         padding: EdgeInsets.all(2),
          //         constraints: const BoxConstraints(minHeight: 30, minWidth: 30),
          //         splashRadius: 20,
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(height: 10),
          // ---------- Product grid ----------
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(child: Text('No products match your search'))
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.65,
                        ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (ctx, index) {
                      final product = _filteredProducts[index];
                      return ProductCard(product: product);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ================== Product Model (same as before) ==================
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

// ================== ProductCard (unchanged) ==================
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
            GestureDetector(
              onTapDown: (_) => setState(() => _isImageActive = true),
              onTapUp: (_) => setState(() => _isImageActive = false),
              onTapCancel: () => setState(() => _isImageActive = false),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isImageActive = true),
                onExit: (_) => setState(() => _isImageActive = false),
                child: SizedBox(
                  height: 150,
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
            Padding(
              padding: const EdgeInsets.all(9.0),
              child: Column(
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatPrice(widget.product.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFF5945CB),
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${widget.product.name}'),
                            ),
                          );
                        },

                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5945CB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(40, 26),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ).copyWith(
                              backgroundColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.hovered) ||
                                    states.contains(WidgetState.pressed)) {
                                  return Color(0xFF5945CB).withOpacity(0.8);
                                }
                                return Color(0xFF5945CB);
                              }),
                              elevation: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.hovered) ||
                                    states.contains(WidgetState.pressed)) {
                                  return 8.0;
                                }
                                return 2.0;
                              }),
                            ),
                        child: const Icon(
                          Icons.add,
                          size: 20,
                          color: Colors.white,
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
