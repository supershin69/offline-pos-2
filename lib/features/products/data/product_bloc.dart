// features/products/data/product_bloc.dart
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';

// --- Events ---
abstract class ProductEvent {}

class MonitorProductStarted extends ProductEvent {
  final String? search;
  final String? categoryId;
  final ItemSortType sortBy;

  MonitorProductStarted({
    this.search,
    this.categoryId,
    this.sortBy = ItemSortType.nameAsc,
  });
}

class AddProductRequested extends ProductEvent {
  final ItemsCompanion item;
  final File? image;
  AddProductRequested({required this.item, this.image});
}

class UpdateProductRequested extends ProductEvent {
  final String id;
  final ItemsCompanion item;
  final File? image;
  UpdateProductRequested({required this.id, required this.item, this.image});
}

class DeleteProductRequested extends ProductEvent {
  final String id;
  DeleteProductRequested({required this.id});
}

// 🚚 Food Truck အသုတ်လိုက် ဝင်လာသည့် ပွဲအတွက် Event အသစ်
class RestockItemsRequested extends ProductEvent {
  final List<StockBatchesCompanion> newBatches;
  RestockItemsRequested({required this.newBatches});
}

// --- States ---
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ItemWithActiveStock> products; // ◄ List<Item> မှ ပြောင်းလဲထားသည်
  final String? error;
  ProductLoaded({required this.products, this.error});

  ProductLoaded copyWithError(String? error) {
    return ProductLoaded(products: products, error: error);
  }
}

// --- BLoC Logic ---
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc(this._repository) : super(ProductInitial()) {
    // 🔄 Monitor လုပ်သည့်နေရာတွင် Type အသစ်သို့ ပြောင်းလဲခြင်း
    on<MonitorProductStarted>((event, emit) async {
      await emit.forEach<List<ItemWithActiveStock>>(
        _repository.watchProducts(
          search: event.search,
          categoryId: event.categoryId,
          sortBy: event.sortBy,
        ),
        onData: (itemList) => ProductLoaded(products: itemList),
        onError: (error, stackTrace) {
          final currentProducts = state is ProductLoaded
              ? (state as ProductLoaded).products
              : <ItemWithActiveStock>[];
          return ProductLoaded(
            products: currentProducts,
            error: "Error loading products: $error",
          );
        },
      );
    });

    on<AddProductRequested>((event, emit) async {
      try {
        await _repository.addProduct(event.item, event.image);
      } catch (e) {
        _emitError(emit, "Error adding product: $e");
      }
    });

    on<UpdateProductRequested>((event, emit) async {
      try {
        await _repository.updateProduct(event.id, event.item, event.image);
      } catch (e) {
        _emitError(emit, "Error updating product: $e");
      }
    });

    on<DeleteProductRequested>((event, emit) async {
      try {
        await _repository.deleteProduct(event.id);
      } catch (e) {
        _emitError(emit, "Error deleting product: $e");
      }
    });

    // 🚚 Restock Logic Handler
    on<RestockItemsRequested>((event, emit) async {
      try {
        await _repository.restockItems(event.newBatches);
      } catch (e) {
        _emitError(emit, "Error restocking items: $e");
      }
    });
  }

  void _emitError(Emitter<ProductState> emit, String errorMessage) {
    if (state is ProductLoaded) {
      emit((state as ProductLoaded).copyWithError(errorMessage));
    } else {
      emit(ProductLoaded(products: const [], error: errorMessage));
    }
  }
}
