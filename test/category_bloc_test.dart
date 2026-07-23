import 'package:flutter_test/flutter_test.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/categories/data/category_bloc.dart';
import 'package:offline_pos/features/categories/repositories/category_repository.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

// Reuse a single instance of the fake database to prevent Drift multiple-instance warnings
final _fakeDb = _FakeAppDatabase();

class FakeCategoryRepository extends CategoryRepository {
  FakeCategoryRepository() : super(_fakeDb);

  @override
  Stream<List<Category>> watchCategories({String? search}) {
    return Stream.value([]);
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    return null;
  }

  @override
  Future<void> addCategory(CategoriesCompanion category) async {}

  @override
  Future<int> updateCategory(String id, CategoriesCompanion category) async {
    return 1;
  }

  @override
  Future<int> deleteCategory(String id) async {
    return 1;
  }
}

class _FakeAppDatabase extends AppDatabase {}

class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/tmp';

  @override
  Future<String?> getApplicationSupportPath() async => '/tmp';

  @override
  Future<String?> getTemporaryPath() async => '/tmp';

  @override
  Future<String?> getLibraryPath() async => '/tmp';

  @override
  Future<String?> getDownloadsPath() async => '/tmp';

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => ['/tmp'];

  @override
  Future<String?> getExternalStoragePath() async => '/tmp';

  @override
  Future<String?> getPlatformVersion() async => 'fake';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  group('CategoryBloc workflow', () {
    test('emits loaded state after monitor starts', () async {
      final bloc = CategoryBloc(FakeCategoryRepository());
      final states = <CategoryState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(MonitorCategoriesStarted());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.any((state) => state is CategoryLoaded), isTrue);
      await sub.cancel();
      await bloc.close();
    });

    test('emits loaded state for get-by-id', () async {
      final bloc = CategoryBloc(FakeCategoryRepository());
      final states = <CategoryState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(GetCategoryByIdRequested(id: 'fake-id'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.any((state) => state is CategoryLoaded), isTrue);
      await sub.cancel();
      await bloc.close();
    });
  });
}
