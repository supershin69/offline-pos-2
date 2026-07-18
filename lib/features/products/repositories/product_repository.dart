// features/products/repositories/product_repository.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/helpers/local_image_manager.dart';

class ProductRepository {
  final AppDatabase db;
  ProductRepository(this.db);

  // 🔄 Active ဖြစ်နေတဲ့ စျေးနှုန်း/Stock စာရင်းတွေပါတွဲပြီး Live Stream ကြည့်ရန်
  Stream<List<ItemWithActiveStock>> watchProducts({
    String? search,
    String? categoryId,
    ItemSortType sortBy = ItemSortType.nameAsc,
  }) {
    return db.watchItemsWithStock(
      search: search,
      categoryId: categoryId,
      sortBy: sortBy,
    );
  }

  // 📝 Product Master အချက်အလက်သစ် (နာမည်၊ ကဏ္ဍ၊ ဓာတ်ပုံ) ကိုသာ အရင်ဆောက်ရန်
  Future<void> addProduct(ItemsCompanion item, File? pickedImage) async {
    String localPath = '';
    if (pickedImage != null) {
      localPath = await LocalImageManager.saveImage(pickedImage);
    }
    await db.into(db.items).insert(item.copyWith(photoPath: Value(localPath)));
  }

  // ✏️ Product Master အချက်အလက်ကို ပြင်ဆင်ရန်
  Future<int> updateProduct(
    String id,
    ItemsCompanion item,
    File? newImage,
  ) async {
    String? finalPhotoPath;
    if (newImage != null) {
      final oldProduct = await (db.select(
        db.items,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      if (oldProduct != null) {
        await LocalImageManager.deleteImage(oldProduct.photoPath);
      }
      finalPhotoPath = await LocalImageManager.saveImage(newImage);
    }

    final updatedCompanion = finalPhotoPath != null
        ? item.copyWith(photoPath: Value(finalPhotoPath))
        : item;

    return await (db.update(
      db.items,
    )..where((tbl) => tbl.id.equals(id))).write(updatedCompanion);
  }

  // ❌ Product ကို ဖျက်ရန် (StockBatches ပါ Cascade onDelete ဖြင့် တစ်ခါတည်း ပျက်သွားမည်)
  Future<int> deleteProduct(String id) async {
    final product = await (db.select(
      db.items,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (product != null) {
      await LocalImageManager.deleteImage(product.photoPath);
    }
    return await (db.delete(db.items)..where((tbl) => tbl.id.equals(id))).go();
  }

  // 🚚 Food Truck ရောက်လာချိန်တွင် အသုတ်လိုက် ပစ္စည်းစာရင်းအသစ် သွင်းရန် (Transaction)
  Future<void> restockItems(List<StockBatchesCompanion> newBatches) async {
    await db.restockItemsInBatch(newBatches);
  }
}
