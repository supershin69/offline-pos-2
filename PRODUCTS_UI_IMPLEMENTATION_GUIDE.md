# Products Feature Implementation Guide for UI Developers

This guide is based only on the products-related code that currently exists in the project. It describes how the UI layer can work with the implemented backend and state flow for product add, list, single-item fetch, edit, delete, restocking, movement tracking, and validation.

## 1. Feature location

The products feature is organized as follows:

- State and events: [lib/features/products/data/product_bloc.dart](lib/features/products/data/product_bloc.dart)
- Repository logic: [lib/features/products/repositories/product_repository.dart](lib/features/products/repositories/product_repository.dart)
- Screen placeholder: [lib/features/products/views/product_screen.dart](lib/features/products/views/product_screen.dart)

## 2. What the UI can already use

The UI layer can already work with the following capabilities:

- Add a product
- View the product list in real time
- Fetch a single product by ID
- Update a product
- Delete a product
- Restock a product
- Watch product movement history
- Receive validation errors from the business layer

## 3. Main state model

The BLoC exposes a single state class named `ProductLoaded`.

### ProductLoaded fields

- `products`: a list of `ItemWithActiveStock`
- `movements`: a list of `ProductMovement`
- `error`: optional error message

### Important note

The current UI should listen to `ProductLoaded` and render from the `products` list for main product viewing.

## 4. How to wire the BLoC in the UI

Create a `ProductBloc` instance and provide it using `BlocProvider`.

Example:

```dart
final repository = ProductRepository(db);
final bloc = ProductBloc(repository);
```

Then in the widget tree:

```dart
BlocProvider(
  create: (_) => ProductBloc(repository),
  child: ProductScreen(),
)
```

## 5. Product list screen flow

### 5.1 Load product list

Dispatch `MonitorProductStarted` to start watching the product stream.

Example:

```dart
context.read<ProductBloc>().add(
  MonitorProductStarted(),
);
```

### 5.2 What the UI should render

The repository returns `List<ItemWithActiveStock>`.

Each item contains:

- `item`: product master fields
- `activeStock`: the currently active stock batch for that product

### 5.3 What the UI can show from the data

From `item`, the UI can show:

- `item.name`
- `item.categoryId`
- `item.photoPath`
- `item.createdAt`
- `item.updatedAt`

From `activeStock`, the UI can show:

- `activeStock.sellPrice`
- `activeStock.buyPrice`
- `activeStock.quantity`
- `activeStock.version`

## 6. Add product flow

### 6.1 Event to dispatch

Use `AddProductRequested`.

Example:

```dart
context.read<ProductBloc>().add(
  AddProductRequested(
    item: ItemsCompanion(
      categoryId: Value('category-id'),
      name: Value('Milk'),
      photoPath: Value(''),
    ),
    image: null,
  ),
);
```

### 6.2 What the repository does

The repository will:

- validate the product name
- ensure it is unique
- save the image if an image is provided
- insert the product into the database

### 6.3 Validation behavior the UI should expect

The repository throws `ArgumentError` when:

- the product name is empty
- the product name already exists

The BLoC converts this into an error message in `ProductLoaded.error`.

## 7. Edit product flow

### 7.1 Event to dispatch

Use `UpdateProductRequested`.

Example:

```dart
context.read<ProductBloc>().add(
  UpdateProductRequested(
    id: productId,
    item: ItemsCompanion(
      name: Value('Updated Milk'),
      categoryId: Value('category-id'),
    ),
    image: null,
  ),
);
```

### 7.2 What the UI should know

The update flow:

- updates the existing product by ID
- checks the product name uniqueness again during update
- replaces the image if a new one is provided

### 7.3 Validation behavior

The UI should show the error from `ProductLoaded.error` if the updated name conflicts with another product.

## 8. Delete product flow

### 8.1 Event to dispatch

Use `DeleteProductRequested`.

Example:

```dart
context.read<ProductBloc>().add(
  DeleteProductRequested(id: productId),
);
```

### 8.2 What the repository does

The repository:

- deletes the product by ID
- deletes the associated image file when present

## 9. Fetch a single product by ID

### 9.1 Event to dispatch

Use `GetProductByIdRequested`.

Example:

```dart
context.read<ProductBloc>().add(
  GetProductByIdRequested(id: productId),
);
```

### 9.2 What the UI receives

The BLoC emits `ProductLoaded` with:

- `products`: a list containing one `ItemWithActiveStock` if found
- `movements`: empty by default

### 9.3 UI usage

Use this when opening a detail screen or editing a selected product.

## 10. Restock flow

### 10.1 Event to dispatch

Use `RestockItemsRequested`.

Example:

```dart
context.read<ProductBloc>().add(
  RestockItemsRequested(
    newBatches: [
      StockBatchesCompanion(
        itemId: Value(productId),
        quantity: Value(20),
        buyPrice: Value(1000),
        sellPrice: Value(1500),
      ),
    ],
  ),
);
```

### 10.2 What the repository does

The repository validates:

- `buy price` is numeric
- `sell price` is numeric

Then it sends the batch to `db.restockItemsInBatch(...)`.

### 10.3 Important behavior for UI

The restock flow uses stock batches. The UI should treat each restock as a new batch entry and rely on the active stock data to reflect the latest state.

## 11. Movement tracking flow

### 11.1 Event to dispatch

Use `LoadProductMovementsRequested`.

Example:

```dart
context.read<ProductBloc>().add(
  LoadProductMovementsRequested(itemId: productId),
);
```

### 11.2 What the UI receives

The BLoC emits `ProductLoaded.movements`.

Each movement item is a `ProductMovement` with:

- `itemId`
- `type`
- `quantity`
- `price`
- `createdAt`
- `batchId`
- `note`

### 11.3 Current implementation behavior

The current movement tracking is derived from stock batches and treats them as restock movements.

The UI can display the movement list as a history feed for a product.

## 12. Current quantity support

The repository includes a helper method to calculate current quantity:

```dart
await repository.getCurrentQuantity(productId);
```

This uses the currently active stock batches and sums their quantities.

The UI can use this when showing stock availability on the product card or detail screen.

## 13. Error handling for UI

All actions that fail will emit `ProductLoaded.error`.

The UI should read the error field and show a message when present.

Example:

```dart
BlocBuilder<ProductBloc, ProductState>(
  builder: (context, state) {
    if (state is ProductLoaded && state.error != null) {
      return Text(state.error!);
    }
    return SizedBox();
  },
)
```

## 14. Recommended UI screen structure

A simple UI structure based on the current implementation could be:

1. Product list screen
   - dispatch `MonitorProductStarted`
   - show `products`

2. Product detail screen
   - dispatch `GetProductByIdRequested`
   - show selected product details and active stock

3. Add/Edit product screen
   - use `AddProductRequested` or `UpdateProductRequested`
   - pass the product companion and optional image

4. Restock screen
   - dispatch `RestockItemsRequested`
   - collect `quantity`, `buyPrice`, `sellPrice`

5. Movement/history screen
   - dispatch `LoadProductMovementsRequested`
   - show `movements`

## 15. What is not included in the current code

This guide intentionally does not describe UI behavior for features that are not implemented in the current code, including:

- stock-out / sale flow
- purchase return flow
- adjustment flow
- customer-facing order flow
- barcode or SKU handling
- advanced reporting dashboards
