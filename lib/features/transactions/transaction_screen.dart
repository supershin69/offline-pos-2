import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/home/views/checkout_screen.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // အချိန် Formatting
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    
    int hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'pm' : 'am';
    
    if (isToday) {
      return 'Today, $hour12:$minute $period';
    } else {
      return '${dt.day}.${dt.month}.${dt.year}, $hour12:$minute $period';
    }
  }

  // ဒီလအတွင်း စုစုပေါင်း ရောင်းရငွေ (Total Inflow)
  int _calculateTotalMonthlyInflow(List<Transaction> transactions) {
    final now = DateTime.now();
    return transactions
        .where((t) => t.createdAt.month == now.month && t.createdAt.year == now.year)
        .fold(0, (sum, item) => sum + item.totalAmount);
  }

  String get _currentMonthYear {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} – ${now.year}';
  }

  // စာရင်းအကုန် ရှင်းထုတ်မည့် Dialog
  void _clearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Transactions'),
        content: const Text('Are you sure you want to clear all transaction records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final repo = context.read<ProductRepository>();
              await repo.db.clearAllTransactions();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProductRepository>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5945CB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Transactions List for this months',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Transaction>>(
          stream: repo.db.watchAllTransactions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final transactionsList = snapshot.data ?? [];
            final totalInflow = _calculateTotalMonthlyInflow(transactionsList);

            return Column(
              children: [
                const SizedBox(height: 16),

                // ---------- 1. Monthly Summary Card ----------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFABC8F4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _currentMonthYear,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Inflow',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$totalInflow Ks',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---------- 2. Clear All Button ----------
                if (transactionsList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0, top: 12, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _clearAll(context),
                        child: const Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ---------- 3. Real-Time Transactions List ----------
                Expanded(
                  child: transactionsList.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions found',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: transactionsList.length,
                          itemBuilder: (context, index) {
                            final tx = transactionsList[index];

                            // 💡 Card ကို နှိပ်လိုက်ရင် Receipt / CheckoutScreen ပေါ်လာစေရန် GestureDetector သုံးထားသည်
                            return GestureDetector(
                              onTap: () {
                                // itemsSummary စာသား (e.g., "rese1, item2") မှ Product Name များကို ခွဲထုတ်ပြီး UI အတွက် Map အဖြစ် ပြောင်းပေးခြင်း
                                final itemNames = tx.itemsSummary.split(', ');
                                final cartItemsMap = itemNames.map((name) {
                                  return {
                                    'product': ItemWithActiveStock(
                                      item: Item(
                                        id: '',
                                        categoryId: '',
                                        name: name.trim(),
                                        photoPath: '',
                                        createdAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      ),
                                      activeStock: StockBatch(
                                        id: '',
                                        itemId: '',
                                        version: 1,
                                        quantity: 1,
                                        buyPrice: 0,
                                        sellPrice: tx.totalAmount ~/ (itemNames.length == 0 ? 1 : itemNames.length),
                                        stockInDate: DateTime.now(),
                                        createdAt: DateTime.now(),
                                      ),
                                    ),
                                    'quantity': 1,
                                  };
                                }).toList();

                                // CheckoutScreen / Receipt Screen သို့ သွားခြင်း
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutScreen(
                                      cartItems: cartItemsMap,
                                      paymentMethod: tx.paymentMethod,
                                      totalAmount: tx.totalAmount,
                                      transactionNo: tx.transactionNo,
                                      transactionTime: tx.createdAt,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Payment Method & Items Summary
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${tx.paymentMethod} pay',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            tx.itemsSummary,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Date & Time
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        _formatTime(tx.createdAt),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),

                                    // Amount (+23000)
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '+${tx.totalAmount}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF22C55E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}