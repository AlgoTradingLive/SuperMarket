import 'package:flutter/material.dart';
import '../models/product.dart';
import 'cart_screen.dart';

class AppDrawer extends StatelessWidget {
  final Map<int, CartItem> cart;
  final void Function(Product product, int delta) onChangeQty;

  const AppDrawer({super.key, required this.cart, required this.onChangeQty});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF0B6E4F),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Hi, Guest",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text("422010", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _tile(context, Icons.grid_view, "Shop by Category", () {
                    Navigator.pop(context);
                  }),
                  _tile(context, Icons.shopping_cart_outlined, "View Cart", () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CartScreen(cart: cart, onChangeQty: onChangeQty),
                      ),
                    );
                  }),
                  _tile(context, Icons.help_outline, "Help & Support",
                      () => _comingSoon(context)),
                  _tile(context, Icons.description_outlined,
                      "Refund, Terms and Policies", () => _comingSoon(context)),
                  _tile(context, Icons.info_outline, "About Us",
                      () => _comingSoon(context)),
                  _tile(context, Icons.storefront_outlined,
                      "Store Information", () => _comingSoon(context)),
                  _tile(context, Icons.edit_location_alt_outlined,
                      "Change Location", () => _comingSoon(context)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("लवकरच उपलब्ध होईल")),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0B6E4F)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
