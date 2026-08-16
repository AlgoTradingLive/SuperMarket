import 'package:flutter/material.dart';
import '../models/product.dart';
import 'cart_screen.dart';
import 'category_screen.dart';
import 'info_screens.dart';
import 'orders_screen.dart';

const kBrandGreen = Color(0xFFD32F2F);

class AppDrawer extends StatelessWidget {
  final Map<int, CartItem> cart;
  final void Function(Product product, int delta) onChangeQty;

  const AppDrawer({super.key, required this.cart, required this.onChangeQty});

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: kBrandGreen,
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
                    _go(context, CategoryScreen(cart: cart, onChangeQty: onChangeQty));
                  }),
                  _tile(context, Icons.shopping_cart_outlined, "View Cart", () {
                    _go(context, CartScreen(cart: cart, onChangeQty: onChangeQty));
                  }),
                  _tile(context, Icons.receipt_long_outlined, "My Orders", () {
                    _go(context, const OrdersScreen());
                  }),
                  _tile(context, Icons.help_outline, "Help & Support", () {
                    _go(context, const HelpSupportScreen());
                  }),
                  _tile(context, Icons.description_outlined,
                      "Refund, Terms and Policies", () {
                    _go(context, const TermsPolicyScreen());
                  }),
                  _tile(context, Icons.info_outline, "About Us", () {
                    _go(context, const AboutUsScreen());
                  }),
                  _tile(context, Icons.storefront_outlined,
                      "Store Information", () {
                    _go(context, const StoreInformationScreen());
                  }),
                  _tile(context, Icons.edit_location_alt_outlined,
                      "Change Location", () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("लवकरच उपलब्ध होईल")),
                    );
                  }),
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

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: kBrandGreen),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
