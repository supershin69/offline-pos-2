import 'package:flutter_test/flutter_test.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';

void main() {
  group('Product movement helpers', () {
    test('calculates current quantity from active batches', () {
      final batches = [
        StockBatch(
          id: 'b1',
          itemId: 'i1',
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
          itemId: 'i1',
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

    test('creates a restock movement from a stock batch', () {
      final batch = StockBatch(
        id: 'b1',
        itemId: 'i1',
        version: 1,
        quantity: 8,
        buyPrice: 100,
        sellPrice: 140,
        stockInDate: DateTime(2024, 1, 1),
        stockOutDate: null,
        createdAt: DateTime(2024, 1, 1),
      );

      final movement = ProductMovement.fromStockBatch(batch);

      expect(movement.type, ProductMovementType.restock);
      expect(movement.quantity, 8);
      expect(movement.itemId, 'i1');
    });
  });
}
