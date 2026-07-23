import 'package:flutter_test/flutter_test.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';

void main() {
  group('ProductRepository validation', () {
    test('rejects duplicate product names case-insensitively', () {
      expect(
        () => ProductRepository.validateUniqueProductName('Apple', [
          'apple',
          'Orange',
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('allows the same product name when updating the same record', () {
      expect(
        () => ProductRepository.validateUniqueProductName('Apple', [
          'apple',
        ], excludeName: 'apple'),
        returnsNormally,
      );
    });

    test('rejects non-numeric price values', () {
      expect(
        () => ProductRepository.validateNumericPrice(
          'abc',
          fieldName: 'sell price',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts numeric price values', () {
      expect(
        () => ProductRepository.validateNumericPrice(
          '1200',
          fieldName: 'sell price',
        ),
        returnsNormally,
      );
    });
  });
}
