// features/products/data/product_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';

// --- Events ---
abstract class ProductEvent {}

class MonitorProductStarted extends ProductEvent {}

class AddProductRequested extends ProductEvent {
  final ItemsCompanion item;
  AddProductRequested({required this.item});
}

class UpdateProductRequested extends ProductEvent {
  final String id;
  final ItemsCompanion item;
  UpdateProductRequested({required this.id, required this.item});
}

class DeleteProductRequested extends ProductEvent {
  final String id;
  DeleteProductRequested({required this.id});
}

// --- States ---
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Item> products; 
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
    on<MonitorProductStarted>((event, emit) async {
      await emit.forEach<List<Item>>(
        _repository.watchProducts(),
        onData: (itemList) => ProductLoaded(products: itemList),
        onError: (error, stackTrace) {
          final currentProducts = state is ProductLoaded ? (state as ProductLoaded).products : <Item>[];
          return ProductLoaded(products: currentProducts, error: "Error loading products: $error");
        }
      );
    });

    on<AddProductRequested>((event, emit) async {
      try {
        await _repository.addProduct(event.item);
      } catch (e) {
        _emitError(emit, "Error adding product: $e");
      }
      
    });

    on<UpdateProductRequested>((event, emit) async {
      try {
        await _repository.updateProduct(event.id, event.item);
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

  }

  void _emitError(Emitter<ProductState> emit, String errorMessage) {
    if (state is ProductLoaded) {
      emit((state as ProductLoaded).copyWithError(errorMessage));
    } else {
      emit(ProductLoaded(products: const [], error: errorMessage));
    }
  }
}
