import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart'; // Required for NativeDatabase.memory()
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' as matcher;
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/categories/repositories/category_repository.dart';

void main() {
  // No path provider mocking needed here anymore since we don't touch the disk!
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CategoryRepository repository;

  setUp(() {
    // Spin up a completely isolated sandbox in memory
    db = AppDatabase(NativeDatabase.memory());
    repository = CategoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepository', () {
    test('rejects duplicate category names case-insensitively', () {
      expect(
        () => CategoryRepository.validateCategoryName('Fruit', [
          'fruit',
          'Vegetables',
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('allows the same category name when updating the same record', () {
      expect(
        () => CategoryRepository.validateCategoryName('Fruit', [
          'fruit',
        ], excludeName: 'fruit'),
        returnsNormally,
      );
    });

    test('rejects empty category names', () {
      expect(
        () => CategoryRepository.validateCategoryName('   ', ['Fruit']),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('adds and fetches a category', () async {
      await repository.addCategory(CategoriesCompanion.insert(name: 'Fruit'));

      final category = await repository.getCategoryById(
        (await db.select(db.categories).get()).single.id,
      );

      expect(category, isNotNull);
      expect(category!.name, 'Fruit');
    });

    test('updates and deletes a category', () async {
      await db
          .into(db.categories)
          .insert(CategoriesCompanion.insert(name: 'Fruit'));

      final created = await (db.select(
        db.categories,
      )..where((tbl) => tbl.name.equals('Fruit'))).getSingleOrNull();
      expect(created, isNotNull);

      await repository.updateCategory(
        created!.id,
        CategoriesCompanion(name: const Value('Vegetables')),
      );

      final updated = await repository.getCategoryById(created.id);
      expect(updated!.name, 'Vegetables');

      final deletedCount = await repository.deleteCategory(created.id);
      expect(deletedCount, 1);
    });
  });
}
