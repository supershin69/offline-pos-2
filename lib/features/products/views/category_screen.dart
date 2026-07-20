// import 'package:flutter/material.dart';
// import 'package:offline_pos/core/database/database.dart';
// import 'package:offline_pos/features/products/views/add_product_screen.dart';

// class CategoryScreen extends StatefulWidget {
//   final Function(String)? onCategorySelected;
//   const CategoryScreen({super.key, this.onCategorySelected});

//   @override
//   State<CategoryScreen> createState() => _CategoryScreenState();
// }

// class _CategoryScreenState extends State<CategoryScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final AppDatabase _db = AppDatabase();

//   // ─── Navigate to Add Product Screen ──────────────────────────────
//   void _navigateToAddProduct() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const AddProductScreen()),
//     );
//   }

//   // ─── Add Category ─────────────────────────────────────────────────
//   Future<void> _addCategory() async {
//     final controller = TextEditingController();
//     await showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Add Category'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(
//             labelText: 'Category Name',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               final name = controller.text.trim();
//               if (name.isNotEmpty) {
//                 await _db.into(_db.categories).insert(
//                   CategoriesCompanion.insert(name: name),
//                 );
//                 if (mounted) Navigator.pop(ctx);
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF5945CB),
//             ),
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── Edit Category ───────────────────────────────────────────────
//   Future<void> _editCategory(Category category) async {
//     final controller = TextEditingController(text: category.name);
//     await showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Edit Category'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(
//             labelText: 'Category Name',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               final newName = controller.text.trim();
//               if (newName.isNotEmpty) {
//                 final updated = category.copyWith(name: newName);
//                 await _db.update(_db.categories).replace(updated);
//                 if (mounted) Navigator.pop(ctx);
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF5945CB),
//             ),
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── Delete Category ─────────────────────────────────────────────
//   Future<void> _deleteCategory(Category category) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Delete Category'),
//         content: Text('Are you sure you want to delete "${category.name}"?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//     if (confirm == true) {
//       await (_db.delete(_db.categories)
//           ..where((tbl) => tbl.id.equals(category.id)))
//           .go();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF3EFFF),
//       appBar: AppBar(
//         title: const Text('Category List'),
//         backgroundColor: const Color(0xFF5945CB),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           // ─── + button → navigate to product upload ───────────────
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: _navigateToAddProduct,
//             tooltip: 'Add Product',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // ─── Search Bar ───────────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search Category',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 8),
//               ),
//               onChanged: (_) => setState(() {}),
//             ),
//           ),

//           // ─── Title + Category Count ─────────────────────────────
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Category List',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 const SizedBox(height: 2),
//                 StreamBuilder<List<Category>>(
//                   stream: _db.select(_db.categories).watch(),
//                   builder: (context, snapshot) {
//                     final int count = snapshot.data?.length ?? 0;
//                     return Text(
//                       'Category : $count',
//                       style: const TextStyle(fontSize: 14, color: Colors.grey),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),

//           // ─── Category Table (ListView with rows) ─────────────────
//           Expanded(
//             child: StreamBuilder<List<Category>>(
//               stream: _db.select(_db.categories).watch(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 final categories = snapshot.data ?? [];
//                 final query = _searchController.text.toLowerCase();
//                 final filtered = categories.where(
//                   (cat) => cat.name.toLowerCase().contains(query),
//                 ).toList();

//                 if (filtered.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       'No categories found',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                   itemCount: filtered.length,
//                   itemBuilder: (ctx, index) {
//                     final cat = filtered[index];
//                     return Card(
//                       elevation: 1,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       margin: const EdgeInsets.only(bottom: 8),
//                       child: ListTile(
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 4,
//                         ),
//                         // ─── Category name (left) ──────────────────
//                         title: GestureDetector(
//                           onTap: () {
//                             if (widget.onCategorySelected != null) {
//                               widget.onCategorySelected!(cat.id);
//                               Navigator.pop(context);
//                             }
//                           },
//                           child: Text(
//                             cat.name,
//                             style: const TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         // ─── Edit + Delete (right) ──────────────────
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: const Icon(
//                                 Icons.edit,
//                                 size: 20,
//                                 color: Colors.blue,
//                               ),
//                               onPressed: () => _editCategory(cat),
//                               padding: EdgeInsets.zero,
//                               constraints: const BoxConstraints(
//                                 minWidth: 40,
//                                 minHeight: 40,
//                               ),
//                             ),
//                             const SizedBox(width: 4),
//                             IconButton(
//                               icon: const Icon(
//                                 Icons.delete,
//                                 size: 20,
//                                 color: Colors.red,
//                               ),
//                               onPressed: () => _deleteCategory(cat),
//                               padding: EdgeInsets.zero,
//                               constraints: const BoxConstraints(
//                                 minWidth: 40,
//                                 minHeight: 40,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       // ─── FloatingActionButton for adding categories ─────────────
//       floatingActionButton: FloatingActionButton(
//         onPressed: _addCategory,
//         backgroundColor: const Color(0xFF5945CB),
//         child: const Icon(Icons.add, color: Colors.white),
//         tooltip: 'Add Category',
//       ),
//     );
//   }
// }