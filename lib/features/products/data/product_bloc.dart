// Events
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/products/models/item_with_quantity.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';

abstract class ProductEvent {}

class MonitorProductStarted extends ProductEvent {}

class AddProductRequested extends ProductEvent {
  final ItemsCompanion item;
  AddProductRequested({required this.item});
}

class AddVariantRequested extends ProductEvent {
  final VariantsCompanion variant;
  AddVariantRequested({required this.variant});
}

// States
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ItemWithQuantity> products;
  ProductLoaded({required this.products});
}

// Bloc

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;
  ProductBloc(this._repository) : super(ProductInitial()) {
    on<MonitorProductStarted>((event, emit) async {
      await emit.forEach<List<ItemWithQuantity>>(
        _repository.watchProducts(),
        onData: (itemList) => ProductLoaded(products: itemList),
      );
    });
    on<AddProductRequested>((event, emit) async {
      await _repository.addProduct(event.item);
    });
    on<AddVariantRequested>((event, emit) async {
      await _repository.addVariant(event.variant);
    });
  }
}
