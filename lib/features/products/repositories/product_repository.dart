import 'package:offline_pos/core/database/database.dart';

class ProductRepository {
  final AppDatabase db;
  ProductRepository(this.db);

  // 🔄 ဒေတာအသွင်ပြောင်းစရာမလိုဘဲ Item List ကို တိုက်ရိုက် Stream လုပ်ပေးပါတယ်
  Stream<List<Item>> watchProducts() {
    return db.watchItems();
  }

  Future<void> addProduct(ItemsCompanion item) async {
    await db.into(db.items).insert(item);
  }

  Future<int> updateProduct(String id, ItemsCompanion item) async {
    return await (db.update(
      db.items,
    )..where((tbl) => tbl.id.equals(id))).write(item);
  }

  Future<int> deleteProduct(String id) async {
    return await (db.delete(db.items)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ❌ addVariant ကို ဖြုတ်ပစ်လိုက်ပါပြီ
}
