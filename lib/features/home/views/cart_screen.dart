import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/products/data/product_bloc.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartScreen({super.key, required this.cartItems});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Selected Payment Method (Default: 'Cash')
  String _selectedPaymentMethod = 'Cash';

  // Payment Options List
  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'Cash', 'name': 'Cash', 'icon': Icons.payments_outlined},
    {'id': 'KPay', 'name': 'KPay', 'icon': Icons.account_balance_wallet_outlined},
    {'id': 'Wave', 'name': 'Wave Money', 'icon': Icons.phone_android_outlined},
    {'id': 'Other', 'name': 'Other', 'icon': Icons.more_horiz_outlined},
  ];

  // Total Amount Calculation
  int get _totalAmount {
    return widget.cartItems.fold(0, (sum, item) {
      final product = item['product'] as ItemWithActiveStock;
      final price = product.activeStock?.sellPrice ?? 0;
      final quantity = item['quantity'] as int;
      return sum + (price * quantity);
    });
  }

  void _incrementQuantity(int index) {
    setState(() {
      widget.cartItems[index]['quantity'] = (widget.cartItems[index]['quantity'] as int) + 1;
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      final currentQty = widget.cartItems[index]['quantity'] as int;
      if (currentQty > 1) {
        widget.cartItems[index]['quantity'] = currentQty - 1;
      } else {
        widget.cartItems.removeAt(index);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      widget.cartItems.removeAt(index);
    });
  }

  // 💡 Checkout Logic Handler Function
  Future<void> _handleCheckout() async {
    if (widget.cartItems.isEmpty) return;

    // 1️⃣ Stock မလုံလောက်မှု ရှိ/မရှိ အရင် စစ်ဆေးခြင်း
    for (var itemData in widget.cartItems) {
      final product = itemData['product'] as ItemWithActiveStock;
      final purchasedQty = itemData['quantity'] as int;
      final currentStock = product.activeStock?.quantity ?? 0;

      if (purchasedQty > currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${product.item.name} ၏ Stock မလုံလောက်ပါ! (လက်ကျန်: $currentStock)',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return; // Stock မလောက်ပါက Checkout ကို ရပ်မည်
      }
    }

    try {
      final repo = context.read<ProductRepository>();

      // 2️⃣ Drift DB ထဲတွင် Active Stock Quantity ကို လျှော့ပေးခြင်း
      for (var itemData in widget.cartItems) {
        final product = itemData['product'] as ItemWithActiveStock;
        final purchasedQty = itemData['quantity'] as int;
        final currentStock = product.activeStock?.quantity ?? 0;
        final newStock = currentStock - purchasedQty;

        if (product.activeStock != null) {
          await (repo.db.update(repo.db.stockBatches)
                ..where((tbl) => tbl.id.equals(product.activeStock!.id)))
              .write(
            StockBatchesCompanion(
              quantity: Value(newStock < 0 ? 0 : newStock),
            ),
          );
        }
      }

      // 3️⃣ Transactions Table ထဲသို့ အရောင်းစာရင်း Record ထည့်သွင်းခြင်း
      final itemsSummary = widget.cartItems
          .map((e) => (e['product'] as ItemWithActiveStock).item.name)
          .join(', ');

      final transactionNo = DateTime.now().millisecondsSinceEpoch.toString().substring(5);

      await repo.db.into(repo.db.transactions).insert(
        TransactionsCompanion.insert(
          transactionNo: transactionNo,
          paymentMethod: _selectedPaymentMethod,
          itemsSummary: itemsSummary,
          totalAmount: _totalAmount,
          createdAt: Value(DateTime.now()),
        ),
      );

      if (mounted) {
        // 4️⃣ ProductBloc သို့ Event ပို့ပြီး Real-Time Refresh လုပ်ခြင်း
        context.read<ProductBloc>().add(MonitorProductStarted());

        // 5️⃣ Receipt / Checkout Screen သို့ Navigate သွားခြင်း
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutScreen(
              cartItems: List.from(widget.cartItems),
              paymentMethod: _selectedPaymentMethod,
              totalAmount: _totalAmount,
              transactionNo: transactionNo,
              transactionTime: DateTime.now(),
            ),
          ),
        );

        // Cart ထဲမှ Items များကို ရှင်းထုတ်ခြင်း
        widget.cartItems.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        title: Text(
          'Shopping Cart (${widget.cartItems.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5945CB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: widget.cartItems.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                // Cart Product List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final itemData = widget.cartItems[index];
                      final productWithStock = itemData['product'] as ItemWithActiveStock;
                      final item = productWithStock.item;
                      final stock = productWithStock.activeStock;
                      final quantity = itemData['quantity'] as int;
                      final price = stock?.sellPrice ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: item.photoPath.isNotEmpty && File(item.photoPath).existsSync()
                                      ? Image.file(
                                          File(item.photoPath),
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.image, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$price Ks',
                                      style: const TextStyle(
                                        color: Color(0xFF5945CB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                                    color: Colors.redAccent,
                                    onPressed: () => _decrementQuantity(index),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 22),
                                    color: const Color(0xFF5945CB),
                                    onPressed: () => _incrementQuantity(index),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Payment Method Selection & Checkout Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Payment Methods Chips/Selection
                        Row(
                          children: _paymentMethods.map((method) {
                            final isSelected = _selectedPaymentMethod == method['id'];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPaymentMethod = method['id'] as String;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF5945CB).withOpacity(0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF5945CB)
                                          : Colors.grey.shade300,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        method['icon'] as IconData,
                                        size: 18,
                                        color: isSelected
                                            ? const Color(0xFF5945CB)
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        method['name'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? const Color(0xFF5945CB)
                                              : Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        // Total Price Display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$_totalAmount Ks',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5945CB),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Checkout Action Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5945CB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _handleCheckout,
                            child: const Text(
                              'Checkout',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}