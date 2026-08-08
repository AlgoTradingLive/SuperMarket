import 'package:flutter/material.dart';
import '../models/product.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final Map<int, CartItem> cart;
  final void Function(Product product, int delta) onChangeQty;

  const CartScreen({super.key, required this.cart, required this.onChangeQty});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int get total => widget.cart.values.fold(0, (sum, c) => sum + c.total);
  int get mrpTotal =>
      widget.cart.values.fold(0, (sum, c) => sum + c.product.mrp * c.qty);
  int get savings => mrpTotal - total;

  @override
  Widget build(BuildContext context) {
    final items = widget.cart.values.toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text("Cart"),
      ),
      body: items.isEmpty
          ? const Center(child: Text("तुमचं cart रिकामं आहे"))
          : Column(
              children: [
                if (savings > 0)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFE3F2FD),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Savings ₹$savings",
                            style: const TextStyle(
                                color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                        Text("Cart Total ₹$total",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final itemSavings = (item.product.mrp - item.product.price) * item.qty;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.product.image,
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 60,
                                  width: 60,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_not_supported_outlined, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text("${item.product.unit}",
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  const SizedBox(height: 4),
                                  Text("You Pay ₹${item.total}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (itemSavings > 0)
                                    Text("You Save ₹$itemSavings",
                                        style: const TextStyle(
                                            color: Color(0xFF2E7D32), fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    iconSize: 16,
                                    color: Colors.white,
                                    icon: const Icon(Icons.remove),
                                    onPressed: () =>
                                        setState(() => widget.onChangeQty(item.product, -1)),
                                  ),
                                  Text('${item.qty}', style: const TextStyle(color: Colors.white)),
                                  IconButton(
                                    iconSize: 16,
                                    color: Colors.white,
                                    icon: const Icon(Icons.add),
                                    onPressed: item.qty >= 10
                                        ? null
                                        : () => setState(
                                            () => widget.onChangeQty(item.product, 1)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total", style: TextStyle(fontSize: 16)),
                  Text("₹$total", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: items.isEmpty
                      ? null
                      : () async {
                          final placed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(items: items, total: total),
                            ),
                          );
                          if (placed == true) {
                            setState(() {
                              widget.cart.clear();
                            });
                          }
                        },
                  child: const Text("Proceed to Checkout", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
