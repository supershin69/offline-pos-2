import 'package:flutter/material.dart';

class CheckoutScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final String paymentMethod;
  final int totalAmount;
  final String transactionNo;
  final DateTime transactionTime;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.paymentMethod,
    required this.totalAmount,
    required this.transactionNo,
    required this.transactionTime,
  });

  String _formatDateTime(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year}/${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'pm' : 'am'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5945CB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Cart ရှင်းပြီးရင် HomeScreen ဆီ အပြီးပြန်သွားမည်
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // Success Green Checkmark Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A651),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Payment Successful',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  '+ $totalAmount Ks',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                const Divider(color: Color(0xFFFFE3E3), thickness: 1),
                const SizedBox(height: 16),

                // Transaction Details Row
                _buildInfoRow('Transaction time', _formatDateTime(transactionTime)),
                const SizedBox(height: 12),
                _buildInfoRow('Transaction No.', transactionNo),
                const SizedBox(height: 12),
                _buildInfoRow('Transaction Type', paymentMethod),
                const SizedBox(height: 24),

                // Items Table Header
                const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Amount',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Items List Rows
                ...cartItems.map((itemData) {
                  final product = itemData['product'];
                  final name = product.item.name;
                  final qty = itemData['quantity'] as int;
                  final price = (product.activeStock?.sellPrice ?? 0) * qty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '$qty',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '$price',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),
                const Divider(color: Color(0xFFFFE3E3), thickness: 1),
                const SizedBox(height: 16),

                // Total Amount Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total amount:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '$totalAmount ks',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}