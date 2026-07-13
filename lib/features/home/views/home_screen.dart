import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  // ---------- MOCK PRODUCTS ----------
  final List<Product> _allProducts = [
    Product(
      name: 'Mineral Water',
      category: 'Water',
      imageUrl:
          'https://i.pinimg.com/736x/c8/ed/3f/c8ed3f2b1eb4192dee6976b2cdb1740a.jpg',
    ),
    Product(
      name: 'Chocolate Bar',
      category: 'Snacks',
      imageUrl:
          'https://i.pinimg.com/736x/a0/e7/16/a0e716af8f7fd4dd0c9a35f0b73fd1cb.jpg',
    ),
    Product(
      name: 'Potato Chips',
      category: 'Snacks',
      imageUrl:
          'https://i.pinimg.com/736x/14/fb/f5/14fbf589a2f366f1c3c38a217bf04876.jpg',
    ),
    Product(
      name: 'Cola Soda',
      category: 'Drinks',
      imageUrl:
          'https://i.pinimg.com/1200x/20/87/e3/2087e377e2e4bf4c9d0b66fd1e00a088.jpg',
    ),
    Product(
      name: 'Orange Juice',
      category: 'Drinks',
      imageUrl:
          'https://i.pinimg.com/1200x/0c/55/d5/0c55d53c665f8cf0f7bfd2e25674551d.jpg',
    ),
    Product(
      name: 'Ice Cream',
      category: 'Desserts',
      imageUrl:
          'https://i.pinimg.com/736x/04/c1/8d/04c18d69b1df86d5edeb74a89235b711.jpg',
    ),
  ];

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Welcome, Team 4 👋',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
              ],
            ),
          ),
          // Search + compact dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                //  DROPDOWN (Center + Rounded + Gray Icon)
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    alignment:
                        AlignmentDirectional.center, // button content center
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        alignment:
                            AlignmentDirectional.center, //  menu items center
                        child: Text(cat, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.black,
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    isDense: true,
                    padding: EdgeInsets.zero,
                    elevation: 1,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Product grid
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
                          childAspectRatio: 0.7,
                        ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (ctx, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 153,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Column(
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Added ${product.name}',
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(
                                        double.infinity,
                                        26,
                                      ),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final String name;
  final String category;
  final String imageUrl;

  Product({required this.name, required this.category, required this.imageUrl});
}
