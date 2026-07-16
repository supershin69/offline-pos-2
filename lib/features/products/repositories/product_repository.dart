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

  // ❌ addVariant ကို ဖြုတ်ပစ်လိုက်ပါပြီ
}
