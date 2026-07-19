import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/categories/repositories/category_repository.dart';

abstract class CategoryEvent {}

class MonitorCategoriesStarted extends CategoryEvent {
  final String? search;
  MonitorCategoriesStarted({this.search});
}

class AddCategoryRequested extends CategoryEvent {
  final CategoriesCompanion category;
  AddCategoryRequested({required this.category});
}

class UpdateCategoryRequested extends CategoryEvent {
  final String id;
  final CategoriesCompanion category;
  UpdateCategoryRequested({required this.id, required this.category});
}

class DeleteCategoryRequested extends CategoryEvent {
  final String id;
  DeleteCategoryRequested({required this.id});
}

class GetCategoryByIdRequested extends CategoryEvent {
  final String id;
  GetCategoryByIdRequested({required this.id});
}

abstract class CategoryState {}

class CategoryInitial extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  final Category? selectedCategory;
  final String? error;

  CategoryLoaded({required this.categories, this.selectedCategory, this.error});

  CategoryLoaded copyWithError(String? error) {
    return CategoryLoaded(
      categories: categories,
      selectedCategory: selectedCategory,
      error: error,
    );
  }
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _repository;

  CategoryBloc(this._repository) : super(CategoryInitial()) {
    on<MonitorCategoriesStarted>((event, emit) async {
      await emit.forEach<List<Category>>(
        _repository.watchCategories(search: event.search),
        onData: (categories) => CategoryLoaded(categories: categories),
        onError: (error, stackTrace) {
          final currentCategories = state is CategoryLoaded
              ? (state as CategoryLoaded).categories
              : <Category>[];
          return CategoryLoaded(
            categories: currentCategories,
            error: "Error loading categories: $error",
          );
        },
      );
    });

    on<AddCategoryRequested>((event, emit) async {
      try {
        await _repository.addCategory(event.category);
      } catch (e) {
        _emitError(
          emit,
          e is ArgumentError ? e.message : "Error adding category: $e",
        );
      }
    });

    on<UpdateCategoryRequested>((event, emit) async {
      try {
        await _repository.updateCategory(event.id, event.category);
      } catch (e) {
        _emitError(
          emit,
          e is ArgumentError ? e.message : "Error updating category: $e",
        );
      }
    });

    on<DeleteCategoryRequested>((event, emit) async {
      try {
        await _repository.deleteCategory(event.id);
      } catch (e) {
        _emitError(emit, "Error deleting category: $e");
      }
    });

    on<GetCategoryByIdRequested>((event, emit) async {
      try {
        final category = await _repository.getCategoryById(event.id);
        emit(
          CategoryLoaded(
            categories: state is CategoryLoaded
                ? (state as CategoryLoaded).categories
                : const [],
            selectedCategory: category,
          ),
        );
      } catch (e) {
        _emitError(
          emit,
          e is ArgumentError ? e.message : "Error loading category: $e",
        );
      }
    });
  }

  void _emitError(Emitter<CategoryState> emit, String errorMessage) {
    if (state is CategoryLoaded) {
      emit((state as CategoryLoaded).copyWithError(errorMessage));
    } else {
      emit(CategoryLoaded(categories: const [], error: errorMessage));
    }
  }
}
