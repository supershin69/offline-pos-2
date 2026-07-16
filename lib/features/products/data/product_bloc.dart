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

// ❌ AddVariantRequested Event ကို ဖြုတ်လိုက်ပါပြီ

// --- States ---
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Item> products; // ◄ Item စာရင်းသက်သက်ပဲ သယ်ဆောင်တော့တယ်
  ProductLoaded({required this.products});
}

// --- BLoC Logic ---
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc(this._repository) : super(ProductInitial()) {
    on<MonitorProductStarted>((event, emit) async {
      await emit.forEach<List<Item>>(
        _repository.watchProducts(),
        onData: (itemList) => ProductLoaded(products: itemList),
      );
    });

    on<AddProductRequested>((event, emit) async {
      await _repository.addProduct(event.item);
    });

    // ❌ on<AddVariantRequested> ကို ဖြုတ်ပစ်လိုက်ပါပြီ
  }
}
