// core/database/database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

enum ItemSortType { nameAsc, nameDesc, priceAsc, priceDesc, dateAsc, dateDesc }

class Users extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 2, max: 100)();
  TextColumn get email => text().unique()();
  TextColumn get password => text().withLength(min: 6)();
  TextColumn get role => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 📦 1. Product Master Table (ဈေးနှုန်းနှင့် ရက်စွဲများ မပါတော့ပါ)
class Items extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get photoPath => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 🔄 2. Stock Batches Table (ဗားရှင်းနှင့် စျေးနှုန်း အတက်အကျများကို သိမ်းရန်)
@DataClassName('StockBatch')
class StockBatches extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get version =>
      integer().withDefault(const Constant(1))(); // Version 1, 2, 3...
  IntColumn get quantity => integer()();
  IntColumn get buyPrice => integer()();
  IntColumn get sellPrice => integer()();

  DateTimeColumn get stockInDate =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get stockOutDate =>
      dateTime().nullable()(); // နောက်တစ်သုတ်လာရင် အဟောင်းကို ပိတ်ရန်
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// UI သို့မဟုတ် Business Logic ထဲမှာ တွဲသုံးရလွယ်အောင် Data Class တစ်ခု သတ်မှတ်ခြင်း
class ItemWithActiveStock {
  final Item item;
  final StockBatch? activeStock;

  ItemWithActiveStock({required this.item, this.activeStock});
}

@DriftDatabase(tables: [Users, Categories, Items, StockBatches])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 5; // ◄ Schema ပြောင်းသွားလို့ ဗားရှင်း တိုးပေးရပါမယ်

  Future<User?> getUserByEmail(String email) {
    return (select(
      users,
    )..where((tbl) => tbl.email.equals(email))).getSingleOrNull();
  }

  // ⚡ 3. Seamless Batch Restock Transaction (အသုတ်လိုက် စာရင်းသွင်းခြင်း Logic)
  Future<void> restockItemsInBatch(
    List<StockBatchesCompanion> newBatches,
  ) async {
    await transaction(() async {
      final today = DateTime.now();

      for (var batch in newBatches) {
        final itemId = batch.itemId.value;

        // ကာယကံရှင် Item ရဲ့ လက်ရှိ Active ဖြစ်နေတဲ့ (မကုန်သေးတဲ့/ဗားရှင်းအဟောင်း) batch ကို ရှာရပါမယ်
        final latestBatch =
            await (select(stockBatches)
                  ..where(
                    (tbl) =>
                        tbl.itemId.equals(itemId) & tbl.stockOutDate.isNull(),
                  )
                  ..orderBy([
                    (tbl) => OrderingTerm(
                      expression: tbl.version,
                      mode: OrderingMode.desc,
                    ),
                  ]))
                .getSingleOrNull();

        int nextVersion = 1;

        if (latestBatch != null) {
          nextVersion = latestBatch.version + 1;

          // စည်းကမ်းချက်အတိုင်း ဗားရှင်းအဟောင်းရဲ့ stockOutDate ကို ယနေ့ရက်စွဲနဲ့ ပိတ်လိုက်ပါမယ်
          await (update(stockBatches)
                ..where((tbl) => tbl.id.equals(latestBatch.id)))
              .write(StockBatchesCompanion(stockOutDate: Value(today)));
        }

        // ဗားရှင်းအသစ်၊ စျေးနှုန်းအသစ်နဲ့ Batch အသစ်ကို Insert လုပ်ပါမယ်
        await into(stockBatches).insert(
          batch.copyWith(
            version: Value(nextVersion),
            stockInDate: Value(today),
          ),
        );
      }
    });
  }

  // 🔍 4. Real-time Items Stream with Active Stock Prices
  Stream<List<ItemWithActiveStock>> watchItemsWithStock({
    String? search,
    String? categoryId,
    ItemSortType sortBy = ItemSortType.nameAsc,
  }) {
    // Items နဲ့ လက်ရှိ Active ဖြစ်နေတဲ့ StockBatch ကို Join ဆွဲပါမယ်
    final query = select(items).join([
      leftOuterJoin(
        stockBatches,
        stockBatches.itemId.equalsExp(items.id) &
            stockBatches.stockOutDate.isNull(),
      ),
    ]);

    if (search != null && search.isNotEmpty) {
      query.where(items.name.lower().contains(search.toLowerCase()));
    }

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'All') {
      query.where(items.categoryId.equals(categoryId));
    }

    // Sorting အတွက် ညှိပေးခြင်း (ဈေးနှုန်းနဲ့ ရက်စွဲတွေက StockBatches ထဲ ရောက်သွားလို့ ဖြစ်ပါတယ်)
    query.orderBy([
      if (sortBy == ItemSortType.nameAsc)
        OrderingTerm(expression: items.name, mode: OrderingMode.asc),
      if (sortBy == ItemSortType.nameDesc)
        OrderingTerm(expression: items.name, mode: OrderingMode.desc),
      if (sortBy == ItemSortType.priceAsc)
        OrderingTerm(
          expression: stockBatches.sellPrice,
          mode: OrderingMode.asc,
        ),
      if (sortBy == ItemSortType.priceDesc)
        OrderingTerm(
          expression: stockBatches.sellPrice,
          mode: OrderingMode.desc,
        ),
      if (sortBy == ItemSortType.dateAsc)
        OrderingTerm(
          expression: stockBatches.stockInDate,
          mode: OrderingMode.asc,
        ),
      if (sortBy == ItemSortType.dateDesc)
        OrderingTerm(
          expression: stockBatches.stockInDate,
          mode: OrderingMode.desc,
        ),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ItemWithActiveStock(
          item: row.readTable(items),
          activeStock: row.readTableOrNull(stockBatches),
        );
      }).toList();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
