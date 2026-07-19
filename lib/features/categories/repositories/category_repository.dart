import 'package:drift/drift.dart';
import 'package:offline_pos/core/database/database.dart';

class CategoryRepository {
  final AppDatabase db;
  CategoryRepository(this.db);

  static void validateCategoryName(
    String? name,
    List<String> existingNames, {
    String? excludeName,
  }) {
    final normalizedName = (name ?? '').trim().toLowerCase();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final normalizedExcludeName = (excludeName ?? '').trim().toLowerCase();

    final isDuplicate = existingNames.any((existingName) {
      final normalizedExistingName = existingName.trim().toLowerCase();
      return normalizedExistingName == normalizedName &&
          normalizedExistingName != normalizedExcludeName;
    });

    if (isDuplicate) {
      throw ArgumentError('Category name must be unique');
    }
  }

  Stream<List<Category>> watchCategories({String? search}) {
    final query = db.select(db.categories);

    if (search != null && search.isNotEmpty) {
      query.where((tbl) => tbl.name.lower().contains(search.toLowerCase()));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
    ]);

    return query.watch();
  }

  Future<Category?> getCategoryById(String id) async {
    return (db.select(
      db.categories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> addCategory(CategoriesCompanion category) async {
    if (category.name.present) {
      final existingNames = (await db.select(db.categories).get())
          .map((item) => item.name)
          .toList();
      validateCategoryName(category.name.value, existingNames);
    }

    await db.into(db.categories).insert(category);
  }

  Future<int> updateCategory(String id, CategoriesCompanion category) async {
    if (category.name.present) {
      final currentCategory = await (db.select(
        db.categories,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      final existingNames = (await db.select(db.categories).get())
          .map((item) => item.name)
          .toList();
      validateCategoryName(
        category.name.value,
        existingNames,
        excludeName: currentCategory?.name,
      );
    }

    return await (db.update(
      db.categories,
    )..where((tbl) => tbl.id.equals(id))).write(category);
  }

  Future<int> deleteCategory(String id) async {
    return await (db.delete(
      db.categories,
    )..where((tbl) => tbl.id.equals(id))).go();
  }
}
