import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/categories/data/category_bloc.dart';
// Note: CategoryRepository အသစ်ခေါ်စရာမလိုတော့လို့ import ဖြုတ်ထားပါတယ်။

class CategoryScreen extends StatefulWidget {
  final Function(String)? onCategorySelected;
  const CategoryScreen({super.key, this.onCategorySelected});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // main.dart မှ ထောက်ပံ့ပေးထားသော Global Bloc ကိုသာ တိုက်ရိုက်သုံးပါမည်
    context.read<CategoryBloc>().add(MonitorCategoriesStarted());
  }

  @override
  void dispose() {
    // _categoryBloc.close(); ကို ဖြုတ်လိုက်ပါပြီ။ (Global Bloc ဖြစ်လို့ ပိတ်စရာမလိုပါ)
    _searchController.dispose();
    super.dispose();
  }

  // ─── Add Category Dialog ────────────────────────────────────────
  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                // context.read ဖြင့်သာ Bloc ကို ခေါ်သုံးပါ
                context.read<CategoryBloc>().add(
                  AddCategoryRequested(
                    category: CategoriesCompanion.insert(name: name),
                  ),
                );
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

  // ─── Edit Category Dialog ────────────────────────────────────────
  Future<void> _showEditCategoryDialog(Category category) async {
    final controller = TextEditingController(text: category.name);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                context.read<CategoryBloc>().add(
                  UpdateCategoryRequested(
                    id: category.id,
                    category: CategoriesCompanion.insert(name: newName),
                  ),
                );
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

  // ─── Delete Category ─────────────────────────────────────────────
  Future<void> _confirmDeleteCategory(Category category) async {
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
    if (confirm == true && mounted) {
      context.read<CategoryBloc>().add(DeleteCategoryRequested(id: category.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        title: const Text('Category List'),
        backgroundColor: const Color(0xFF5945CB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<CategoryBloc, CategoryState>(
        // bloc: _categoryBloc, ကို ဖြုတ်လိုက်ပါပြီ (Tree ထဲကနေ Auto ရှာပေးပါလိမ့်မယ်)
        listener: (context, state) {
          if (state is CategoryLoaded && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is CategoryInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CategoryLoaded) {
              final categories = state.categories;
              final query = _searchController.text.toLowerCase();
              final filtered = categories.where(
                (cat) => cat.name.toLowerCase().contains(query),
              ).toList();

              return Column(
                children: [
                  // ─── Search Bar ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Category',
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

                  // ─── Title + Category Count ───────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Category List',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Category : ${categories.length}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ─── "All Categories" Button ────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        onTap: () {
                          if (widget.onCategorySelected != null) {
                            widget.onCategorySelected!('');
                          }
                          Navigator.pop(context, '');
                        },
                        leading: const Icon(
                          Icons.grid_view_rounded,
                          color: Color(0xFF5945CB),
                        ),
                        title: const Text(
                          'All Categories',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5945CB),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ─── Category List ─────────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No categories found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, index) {
                              final cat = filtered[index];
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  onTap: () {
                                    if (widget.onCategorySelected != null) {
                                      widget.onCategorySelected!(cat.id);
                                    }
                                    Navigator.pop(context, cat.id);
                                  },
                                  title: Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _showEditCategoryDialog(cat),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _confirmDeleteCategory(cat),
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
                          ),
                  ),
                ],
              );
            }
            return const Center(child: Text('Unknown state'));
          },
        ),
      ),
      // ─── FloatingActionButton for adding categories ─────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: const Color(0xFF5945CB),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Category',
      ),
    );
  }
}