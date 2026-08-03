import 'package:flutter/material.dart';
import '../models/product.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final Map<int, CartItem> cart;
  final void Function(dynamic product, int delta) onChangeQty;

  const CartScreen({super.key, required this.cart, required this.onChangeQty});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int get total => widget.cart.values.fold(0, (sum, c) => sum + c.total);

  @override
  Widget build(BuildContext context) {
    final items = widget.cart.values.toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B6E4F),
        title: const Text("Your Cart"),
      ),
      body: items.isEmpty
          ? const Center(child: Text("तुमचं cart रिकामं आहे"))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final item = items[i];
                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text("₹${item.product.price} x ${item.qty}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() => widget.onChangeQty(item.product, -1)),
                      ),
                      Text('${item.qty}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => widget.onChangeQty(item.product, 1)),
                      ),
                    ],
                  ),
                );
              },
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
                    backgroundColor: const Color(0xFF0B6E4F),
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
