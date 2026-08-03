import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  List<String> categories = ["All"];
  String activeCategory = "All";
  String searchQuery = "";
  bool loading = true;
  String? error;

  final Map<int, CartItem> cart = {};

  // Offer banners — assets/banners/ मधल्या फोटोंची यादी
  final List<String> bannerImages = [
    "assets/banners/banner1.jpg",
    "assets/banners/banner2.jpg",
    "assets/banners/banner3.jpg",
    "assets/banners/banner4.jpg",
    "assets/banners/banner5.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      setState(() => categories = cats);
    } catch (_) {
      // categories न आल्या तरी products दाखवत राहू
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final list = await ApiService.fetchProducts(
        category: activeCategory,
        search: searchQuery,
      );
      setState(() {
        products = list;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Server शी कनेक्ट होत नाहीये.\nथोडं थांबून पुन्हा प्रयत्न करा (free server sleep मधून उठायला ५०+ सेकंद लागू शकतात).";
        loading = false;
      });
    }
  }

  void _changeQty(Product p, int delta) {
    setState(() {
      final existing = cart[p.id];
      final newQty = (existing?.qty ?? 0) + delta;
      if (newQty <= 0) {
        cart.remove(p.id);
      } else if (existing != null) {
        existing.qty = newQty;
      } else {
        cart[p.id] = CartItem(product: p, qty: newQty);
      }
    });
  }

  int get totalCartQty => cart.values.fold(0, (sum, c) => sum + c.qty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B6E4F),
        title: const Text("🛒 QuickMart", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartScreen(cart: cart, onChangeQty: _changeQty),
                    ),
                  );
                  setState(() {});
                },
              ),
              if (totalCartQty > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$totalCartQty',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search for products...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                searchQuery = v;
                _loadProducts();
              },
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = categories[i];
                final active = c == activeCategory;
                return ChoiceChip(
                  label: Text(c),
                  selected: active,
                  selectedColor: const Color(0xFF0B6E4F),
                  labelStyle: TextStyle(color: active ? Colors.white : Colors.black87),
                  onSelected: (_) {
                    activeCategory = c;
                    _loadProducts();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // ---- Offer Banners (आडवं स्क्रोल) ----
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              itemCount: bannerImages.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    bannerImages[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.image_not_supported_outlined)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
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
              ElevatedButton(onPressed: _loadProducts, child: const Text("पुन्हा प्रयत्न करा")),
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
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        final qty = cart[p.id]?.qty ?? 0;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  p.image,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 90,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
              const Spacer(),
              qty == 0
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B6E4F),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _changeQty(p, 1),
                        child: const Text("ADD", style: TextStyle(color: Colors.white)),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B6E4F),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            iconSize: 18,
                            color: Colors.white,
                            icon: const Icon(Icons.remove),
                            onPressed: () => _changeQty(p, -1),
                          ),
                          Text('$qty', style: const TextStyle(color: Colors.white)),
                          IconButton(
                            iconSize: 18,
                            color: Colors.white,
                            icon: const Icon(Icons.add),
                            onPressed: () => _changeQty(p, 1),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}
