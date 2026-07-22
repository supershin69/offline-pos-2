// features/products/repositories/product_repository.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/helpers/local_image_manager.dart';

enum ProductMovementType { restock, sale, adjustment }

class ProductMovement {
  final String itemId;
  final ProductMovementType type;
  final int quantity;
  final int? price;
  final DateTime createdAt;
  final String? batchId;
  final String? note;

  ProductMovement({
    required this.itemId,
    required this.type,
    required this.quantity,
    this.price,
    required this.createdAt,
    this.batchId,
    this.note,
  });

  static ProductMovement fromStockBatch(StockBatch batch) {
    return ProductMovement(
      itemId: batch.itemId,
      type: ProductMovementType.restock,
      quantity: batch.quantity,
      price: batch.sellPrice,
      createdAt: batch.stockInDate,
      batchId: batch.id,
      note: batch.stockOutDate == null ? 'Active batch' : 'Closed batch',
    );
  }
}

class ProductRepository {
  final AppDatabase db;
  ProductRepository(this.db);

  // 🛑 Name Validation Logic (Duplicate Name စစ်ဆေးခြင်း)
  static void validateUniqueProductName(
    String? name,
    List<String> existingNames, {
    String? excludeName,
  }) {
    final normalizedName = (name ?? '').trim().toLowerCase();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Product name cannot be empty');
    }

    final normalizedExcludeName = (excludeName ?? '').trim().toLowerCase();

    final isDuplicate = existingNames.any((existingName) {
      final normalizedExistingName = existingName.trim().toLowerCase();
      return normalizedExistingName == normalizedName &&
          normalizedExistingName != normalizedExcludeName;
    });

    if (isDuplicate) {
      throw ArgumentError('Product name must be unique');
    }
  }

  // 🛑 Price Validation Logic
  static void validateNumericPrice(Object? price, {required String fieldName}) {
    if (price == null) {
      throw ArgumentError('$fieldName must be a number');
    }

    final parsedValue =
        price is int ? price : int.tryParse(price.toString().trim());

    if (parsedValue == null) {
      throw ArgumentError('$fieldName must be a number');
    }
  }

  // 🔢 Quantity တွက်ချက်သည့် Helper Functions (ပြန်လည်ပေါင်းထည့်ထားပါသည်)
  static int calculateCurrentQuantity(List<StockBatch> batches) {
    return batches
        .where((batch) => batch.stockOutDate == null)
        .fold<int>(0, (total, batch) => total + batch.quantity);
  }

  Future<int> getCurrentQuantity(String itemId) async {
    final batches = await (db.select(
      db.stockBatches,
    )..where((tbl) => tbl.itemId.equals(itemId))).get();
    return calculateCurrentQuantity(batches);
  }

  // 🔄 Active ဖြစ်နေတဲ့ Product List ကို Live Stream ကြည့်ရန်
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

  // 📝 Product အသစ်ထည့်ရန်
  Future<void> addProduct(ItemsCompanion item, File? pickedImage) async {
    if (item.name.present) {
      final existingNames = (await db.select(db.items).get())
          .map((product) => product.name)
          .toList();
      validateUniqueProductName(item.name.value, existingNames);
    }

    String localPath = '';
    if (pickedImage != null) {
      localPath = await LocalImageManager.saveImage(pickedImage);
    }
    await db.into(db.items).insert(item.copyWith(photoPath: Value(localPath)));
  }

  // ✏️ Product ပြင်ဆင်ရန်
  Future<int> updateProduct(
    String id,
    ItemsCompanion item,
    File? newImage,
  ) async {
    if (item.name.present) {
      final currentProduct = await (db.select(
        db.items,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      final existingNames = (await db.select(db.items).get())
          .map((product) => product.name)
          .toList();
      validateUniqueProductName(
        item.name.value,
        existingNames,
        excludeName: currentProduct?.name,
      );
    }

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

  // ❌ Product ဖျက်ရန်
  Future<int> deleteProduct(String id) async {
    final product = await (db.select(
      db.items,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (product != null) {
      await LocalImageManager.deleteImage(product.photoPath);
    }
    return await (db.delete(db.items)..where((tbl) => tbl.id.equals(id))).go();
  }

  // 🚚 Restock Batch သွင်းရန်
  Future<void> restockItems(List<StockBatchesCompanion> newBatches) async {
    for (final batch in newBatches) {
      if (batch.buyPrice.present) {
        validateNumericPrice(batch.buyPrice.value, fieldName: 'buy price');
      }
      if (batch.sellPrice.present) {
        validateNumericPrice(batch.sellPrice.value, fieldName: 'sell price');
      }
    }
    await db.restockItemsInBatch(newBatches);
  }

  // 📊 Movement History Streams
  Stream<List<ProductMovement>> watchMovements({String? itemId}) {
    final query = db.select(db.stockBatches);
    if (itemId != null && itemId.isNotEmpty) {
      query.where((tbl) => tbl.itemId.equals(itemId));
    }
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.stockInDate, mode: OrderingMode.desc),
    ]);
    return query.watch().map((rows) {
      return rows.map((row) => ProductMovement.fromStockBatch(row)).toList();
    });
  }

  Future<ItemWithActiveStock?> getProductById(String id) async {
    final item = await (db.select(db.items)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (item == null) return null;

    final activeBatch = await (db.select(db.stockBatches)
          ..where((tbl) => tbl.itemId.equals(id) & tbl.stockOutDate.isNull())
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.version, mode: OrderingMode.desc)]))
        .getSingleOrNull();

    return ItemWithActiveStock(item: item, activeStock: activeBatch);
  }
}