import 'package:drift/drift.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/products/models/item_with_quantity.dart';

class ProductRepository {
  final AppDatabase db;
  ProductRepository(this.db);

  Stream<List<ItemWithQuantity>> watchProducts() {
    return db.getItemsWithCount().map((List<TypedResult> rows) {
      return rows.map((row) {
        final item = row.readTable(db.items);
        final quantity = row.read<int>(db.variants.id.count()) ?? 0;
        return ItemWithQuantity(item: item, quantity: quantity);
      }).toList();
    });
  }

  Future<void> addProduct(ItemsCompanion item) async {
    await db.into(db.items).insert(item);
  }

  Future<void> addVariant(VariantsCompanion variant) async {
    await db.into(db.variants).insert(variant);
  }
}
