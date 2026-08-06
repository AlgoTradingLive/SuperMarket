import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/subcategory.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'products_screen.dart';
import 'app_drawer.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Subcategory>> sections = {};
  bool loading = true;
  String? error;
  String searchQuery = "";

  final Map<int, CartItem> cart = {};

  final List<String> bannerImages = [
    "assets/banners/banner1.jpg",
    "assets/banners/banner2.jpg",
    "assets/banners/banner3.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ApiService.fetchSubcategories();
      setState(() {
        sections = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error =
            "Server शी कनेक्ट होत नाहीये.\nथोडं थांबून पुन्हा प्रयत्न करा (free server sleep मधून उठायला ५०+ सेकंद लागू शकतात).";
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

  void _openSearch(String q) {
    if (q.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductsScreen(
          title: "Search: $q",
          search: q,
          cart: cart,
          onChangeQty: _changeQty,
        ),
      ),
    );
  }

  void _openSubcategory(Subcategory s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductsScreen(
          title: s.name,
          subCategory: s.name,
          cart: cart,
          onChangeQty: _changeQty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      drawer: AppDrawer(cart: cart, onChangeQty: _changeQty),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B6E4F),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/logo.png',
                height: 36,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "कांकरीया सुपरमार्केट",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
                      builder: (_) =>
                          CartScreen(cart: cart, onChangeQty: _changeQty),
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
      body: RefreshIndicator(
        onRefresh: _loadSections,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Delivery address bar
            Container(
              width: double.infinity,
              color: const Color(0xFF0B6E4F),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  const Text("Delivery to: 422010",
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(backgroundColor: Colors.white24),
                    child: const Text("Change",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
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
                onSubmitted: _openSearch,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: PageController(viewportFraction: 1.0),
                itemCount: bannerImages.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.grey.shade100,
                      child: Image.asset(
                        bannerImages[i],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionsBody(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0B6E4F),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (i) async {
          if (i == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryScreen(cart: cart, onChangeQty: _changeQty),
              ),
            );
            setState(() {});
          } else if (i == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CartScreen(cart: cart, onChangeQty: _changeQty),
              ),
            );
            setState(() {});
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Category"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.replay), label: "Reorder"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }

  Widget _buildSectionsBody() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _loadSections, child: const Text("पुन्हा प्रयत्न करा")),
          ],
        ),
      );
    }
    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text("Categories सापडल्या नाहीत")),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.entries.map((entry) {
        return _buildSectionGrid(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildSectionGrid(String sectionName, List<Subcategory> subs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sectionName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: subs.length,
            itemBuilder: (_, i) {
              final s = subs[i];
              return InkWell(
                onTap: () => _openSubcategory(s),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        s.icon,
                        height: 64,
                        width: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 64,
                          width: 64,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported_outlined, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
