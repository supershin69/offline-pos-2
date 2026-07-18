import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProductRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ProductRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductRepository', () {
    test('validates duplicate product names', () {
      expect(
        () => ProductRepository.validateUniqueProductName('Milk', ['milk']),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates numeric price values', () {
      expect(
        () => ProductRepository.validateNumericPrice(
          'abc',
          fieldName: 'sell price',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('adds a product and fetches it by id', () async {
      final categoryId =
          (await db
                  .into(db.categories)
                  .insert(CategoriesCompanion.insert(name: 'Food')))
              .toString();

      await repository.addProduct(
        ItemsCompanion.insert(
          categoryId: categoryId,
          name: 'Milk',
          photoPath: '',
        ),
        null,
      );

      final products = await db.select(db.items).get();
      expect(products, isNotEmpty);

      final fetched = await repository.getProductById(products.single.id);
      expect(fetched, isNotNull);
      expect(fetched!.item.name, 'Milk');
    });

    test('calculates current quantity from active batches', () {
      final batches = [
        StockBatch(
          id: 'b1',
          itemId: 'item-1',
          version: 1,
          quantity: 10,
          buyPrice: 100,
          sellPrice: 150,
          stockInDate: DateTime(2024, 1, 1),
          stockOutDate: null,
          createdAt: DateTime(2024, 1, 1),
        ),
        StockBatch(
          id: 'b2',
          itemId: 'item-1',
          version: 2,
          quantity: 5,
          buyPrice: 120,
          sellPrice: 180,
          stockInDate: DateTime(2024, 1, 2),
          stockOutDate: null,
          createdAt: DateTime(2024, 1, 2),
        ),
      ];

      expect(ProductRepository.calculateCurrentQuantity(batches), 15);
    });

    test('restocks items and updates movement stream', () async {
      final categoryId =
          (await db
                  .into(db.categories)
                  .insert(CategoriesCompanion.insert(name: 'Food')))
              .toString();

      final itemId =
          (await db
                  .into(db.items)
                  .insert(
                    ItemsCompanion.insert(
                      categoryId: categoryId,
                      name: 'Bread',
                      photoPath: '',
                    ),
                  ))
              .toString();

      await repository.restockItems([
        StockBatchesCompanion.insert(
          itemId: itemId,
          quantity: 15,
          buyPrice: 200,
          sellPrice: 300,
        ),
      ]);

      final movements = await repository.watchMovements(itemId: itemId).first;
      expect(movements, isNotEmpty);
      expect(movements.first.itemId, itemId);
    });
  });
}
