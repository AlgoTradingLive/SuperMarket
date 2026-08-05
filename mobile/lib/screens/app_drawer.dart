import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
                  _tile(Icons.grid_view, "Shop by Category"),
                  _tile(Icons.shopping_cart_outlined, "View Cart"),
                  _tile(Icons.help_outline, "Help & Support"),
                  _tile(Icons.description_outlined, "Refund, Terms and Policies"),
                  _tile(Icons.info_outline, "About Us"),
                  _tile(Icons.storefront_outlined, "Store Information"),
                  _tile(Icons.edit_location_alt_outlined, "Change Location"),
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

  Widget _tile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0B6E4F)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {},
    );
  }
}
