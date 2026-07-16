// core/database/database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

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
}

class Items extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  IntColumn get buyPrice => integer()();
  IntColumn get sellPrice => integer()();
  TextColumn get photoUrl => text()();
  BoolColumn get isDiscounted => boolean().withDefault(const Constant(false))();
  IntColumn get discountedPrice => integer().nullable()();
  DateTimeColumn get stockInDate => dateTime().nullable()();
  DateTimeColumn get stockOutDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 🔗 Variants Table ကို လုံးဝ ဖြုတ်ပစ်လိုက်ပါပြီ

@DriftDatabase(
  tables: [Users, Categories, Items],
) // ◄ Variants ကို ဖြုတ်လိုက်တယ်
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ⚠️ Table ဖြုတ်လိုက်တဲ့အတွက် ဗားရှင်းတိုးပေးရပါမယ် (သို့မဟုတ် App ကို ဖျက်ပြီး ပြန်တင်ပါ)
  @override
  int get schemaVersion => 4;

  Future<User?> getUserByEmail(String email) {
    return (select(
      users,
    )..where((tbl) => tbl.email.equals(email))).getSingleOrNull();
  }

  // 🔄 ရိုးရှင်းသွားတဲ့ Real-time Items Stream
  Stream<List<Item>> watchItems() {
    return select(items).watch();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
