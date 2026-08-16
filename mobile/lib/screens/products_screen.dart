import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/wishlist_store.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

const kBrandGreen = Color(0xFFD32F2F);

class ProductsScreen extends StatefulWidget {
  final String title;
  final String? section;
  final String? subCategory;
  final String? search;
  final Map<int, CartItem> cart;
  final void Function(Product product, int delta) onChangeQty;

  const ProductsScreen({
    super.key,
    required this.title,
    this.section,
    this.subCategory,
    this.search,
    required this.cart,
    required this.onChangeQty,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final list = await ApiService.fetchProducts(
        section: widget.section ?? "All",
        subCategory: widget.subCategory ?? "",
        search: widget.search ?? "",
      );
      setState(() {
        products = list;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error =
            "Server शी कनेक्ट होत नाहीये.\nथोडं थांबून पुन्हा प्रयत्न करा.";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: kBrandGreen,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildCartBar(),
    );
  }

  Widget? _buildCartBar() {
    final items = widget.cart.values.toList();
    if (items.isEmpty) return null;

    final totalQty = items.fold(0, (sum, c) => sum + c.qty);
    final totalPrice = items.fold(0, (sum, c) => sum + c.total);
    final totalSavings = items.fold(
        0, (sum, c) => sum + (c.product.mrp - c.product.price) * c.qty);

    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kBrandGreen,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text('$totalQty',
                        style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("₹$totalPrice Cart Total",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    "$totalQty Item${totalQty > 1 ? 's' : ''}"
                    "${totalSavings > 0 ? ' • ₹$totalSavings Saved' : ''}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide.none,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CartScreen(cart: widget.cart, onChangeQty: widget.onChangeQty),
                  ),
                );
                setState(() {});
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("CART", style: TextStyle(color: kBrandGreen, fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right, color: kBrandGreen, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text("पुन्हा प्रयत्न करा")),
            ],
          ),
        ),
      );
    }
    if (products.isEmpty) {
      return const Center(child: Text("Products सापडले नाहीत"));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        final qty = widget.cart[p.id]?.qty ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                    product: p, cart: widget.cart, onChangeQty: widget.onChangeQty),
              ),
            );
            setState(() {});
          },
          child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      p.image,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 110,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 110,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  if (p.discountPercent > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${p.discountPercent}% OFF",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: InkWell(
                      onTap: () => setState(() => WishlistStore.toggle(p.id)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          WishlistStore.isWishlisted(p.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: WishlistStore.isWishlisted(p.id)
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(p.unit, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text("₹${p.price}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (p.mrp > p.price) ...[
                    const SizedBox(width: 6),
                    Text("₹${p.mrp}",
                        style: TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade500)),
                  ]
                ],
              ),
              const SizedBox(height: 8),
              qty == 0
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandGreen,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => setState(() => widget.onChangeQty(p, 1)),
                        child: const Text("ADD", style: TextStyle(color: Colors.white)),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: kBrandGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            iconSize: 18,
                            color: Colors.white,
                            icon: const Icon(Icons.remove),
                            onPressed: () => setState(() => widget.onChangeQty(p, -1)),
                          ),
                          Text('$qty', style: const TextStyle(color: Colors.white)),
                          IconButton(
                            iconSize: 18,
                            color: Colors.white,
                            icon: const Icon(Icons.add),
                            onPressed: qty >= 10
                                ? null
                                : () => setState(() => widget.onChangeQty(p, 1)),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
          ),
        );
      },
    );
  }
}
