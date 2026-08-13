import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';

const kBrandGreen = Color(0xFF2E7D32);

class SearchScreen extends StatefulWidget {
  final Map<int, CartItem> cart;
  final void Function(Product product, int delta) onChangeQty;

  const SearchScreen({super.key, required this.cart, required this.onChangeQty});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  Timer? _debounce;
  List<Product>? results;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        results = null;
        error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query.trim()));
  }

  Future<void> _search(String query) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final list = await ApiService.fetchProducts(search: query);
      if (!mounted) return;
      setState(() {
        results = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "शोधता आलं नाही, पुन्हा प्रयत्न करा.";
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
        titleSpacing: 0,
        title: TextField(
          controller: controller,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Products शोधा...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                setState(() {
                  results = null;
                  error = null;
                });
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));
    if (results == null) {
      return const Center(
        child: Text("काय शोधायचंय ते टाइप करा",
            style: TextStyle(color: Colors.grey)),
      );
    }
    if (results!.isEmpty) {
      return const Center(
        child: Text("काही सापडलं नाही",
            style: TextStyle(color: Colors.grey)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results!.length,
      itemBuilder: (_, i) => _productCard(results![i]),
    );
  }

  Widget _productCard(Product p) {
    final qty = widget.cart[p.id]?.qty ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  p.image,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 120, color: Colors.grey.shade200),
                ),
              ),
              if (p.discountPercent > 0)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text("${p.discountPercent}% OFF",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
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
                Text(p.unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("₹${p.price}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (p.discountPercent > 0) ...[
                      const SizedBox(width: 4),
                      Text("₹${p.mrp}",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: qty == 0
                      ? OutlinedButton(
                          onPressed: () => setState(() => widget.onChangeQty(p, 1)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kBrandGreen,
                            side: const BorderSide(color: kBrandGreen),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text("ADD", style: TextStyle(fontSize: 12)),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => setState(() => widget.onChangeQty(p, -1)),
                              child: const Icon(Icons.remove_circle,
                                  color: kBrandGreen, size: 22),
                            ),
                            Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                            InkWell(
                              onTap: () => setState(() => widget.onChangeQty(p, 1)),
                              child: const Icon(Icons.add_circle,
                                  color: kBrandGreen, size: 22),
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
