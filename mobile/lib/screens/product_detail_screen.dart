import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/wishlist_store.dart';
import 'cart_screen.dart';

const kBrandGreen = Color(0xFF2E7D32);

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Map<int, CartItem> cart;
  final void Function(Product product, int delta) onChangeQty;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.cart,
    required this.onChangeQty,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Product>? related;

  @override
  void initState() {
    super.initState();
    _loadRelated();
  }

  Future<void> _loadRelated() async {
    try {
      final list = await ApiService.fetchRelated(
        name: widget.product.name,
        subCategory: widget.product.subCategory,
        excludeId: widget.product.id,
      );
      if (!mounted) return;
      setState(() => related = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => related = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final qty = widget.cart[p.id]?.qty ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kBrandGreen,
        foregroundColor: Colors.white,
        title: const Text("Product Details"),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
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
              ),
              if (widget.cart.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    child: Text(
                      '${widget.cart.values.fold(0, (s, c) => s + c.qty)}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          Stack(
            children: [
              Image.network(
                p.image,
                height: 320,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 320,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image_not_supported_outlined, size: 60),
                ),
              ),
              if (p.discountPercent > 0)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("${p.discountPercent}% OFF",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              Positioned(
                top: 16,
                right: 16,
                child: InkWell(
                  onTap: () => setState(() => WishlistStore.toggle(p.id)),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      WishlistStore.isWishlisted(p.id) ? Icons.favorite : Icons.favorite_border,
                      color: WishlistStore.isWishlisted(p.id) ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kBrandGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(p.section.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: kBrandGreen)),
                ),
                const SizedBox(height: 10),
                Text(p.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(p.unit, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text("₹${p.price}",
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.bold, color: kBrandGreen)),
                      if (p.mrp > p.price) ...[
                        const SizedBox(width: 10),
                        Text("₹${p.mrp}",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text("Save ₹${p.mrp - p.price}",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (p.inStock)
                  Row(
                    children: const [
                      Icon(Icons.check_circle, color: kBrandGreen, size: 18),
                      SizedBox(width: 6),
                      Text("In Stock", style: TextStyle(color: kBrandGreen, fontWeight: FontWeight.w600)),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 6),
                      Text("Out of Stock",
                          style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                    ],
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: qty == 0
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: kBrandGreen),
                          onPressed: p.inStock ? () => setState(() => widget.onChangeQty(p, 1)) : null,
                          icon: const Icon(Icons.shopping_cart, color: Colors.white),
                          label: const Text("ADD TO CART",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: kBrandGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                color: Colors.white,
                                icon: const Icon(Icons.remove),
                                onPressed: () => setState(() => widget.onChangeQty(p, -1)),
                              ),
                              Text('$qty',
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                color: Colors.white,
                                icon: const Icon(Icons.add),
                                onPressed: qty >= 10
                                    ? null
                                    : () => setState(() => widget.onChangeQty(p, 1)),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (related == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (related!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("You might also like",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: related!.length,
                      itemBuilder: (_, i) => _relatedCard(related![i]),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _relatedCard(Product p) {
    final qty = widget.cart[p.id]?.qty ?? 0;
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
                product: p, cart: widget.cart, onChangeQty: widget.onChangeQty),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                p.image,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey.shade100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 32,
                    child: Text(p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  Text("₹${p.price}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: qty == 0
                        ? OutlinedButton(
                            onPressed: () => setState(() => widget.onChangeQty(p, 1)),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: kBrandGreen,
                                side: const BorderSide(color: kBrandGreen),
                                padding: EdgeInsets.zero),
                            child: const Text("ADD", style: TextStyle(fontSize: 11)),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => setState(() => widget.onChangeQty(p, -1)),
                                child: const Icon(Icons.remove_circle, color: kBrandGreen, size: 20),
                              ),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              InkWell(
                                onTap: () => setState(() => widget.onChangeQty(p, 1)),
                                child: const Icon(Icons.add_circle, color: kBrandGreen, size: 20),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
