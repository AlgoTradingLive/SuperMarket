import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/subcategory.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'products_screen.dart';
import 'app_drawer.dart';
import 'category_screen.dart';
import 'search_screen.dart';

const kBrandGreen = Color(0xFF2E7D32);
const kBrandGreenLight = Color(0xFFE8F5E9);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Subcategory>> sections = {};
  List<Product> offerProducts = [];
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
      final allProducts = await ApiService.fetchProducts();
      final deals = allProducts.where((p) => p.discountPercent > 0).toList();
      setState(() {
        sections = data;
        offerProducts = deals;
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

  Widget? _buildCartBar() {
    final items = cart.values.toList();
    if (items.isEmpty) return null;

    final totalQty = items.fold(0, (sum, c) => sum + c.qty);
    final totalPrice = items.fold(0, (sum, c) => sum + c.total);
    final totalSavings = items.fold(
        0, (sum, c) => sum + (c.product.mrp - c.product.price) * c.qty);

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white)),
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
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
                    builder: (_) => CartScreen(cart: cart, onChangeQty: _changeQty),
                  ),
                );
                setState(() {});
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("CART",
                      style: TextStyle(
                          color: kBrandGreen, fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right, color: kBrandGreen, size: 18),
                ],
              ),
            ),
          ],
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
        backgroundColor: kBrandGreen,
        foregroundColor: Colors.white,
        title: Image.asset(
          'assets/logo.png',
          height: 40,
          errorBuilder: (_, __, ___) => const Text("कांकरीया सुपरमार्केट"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(cart: cart, onChangeQty: _changeQty),
                ),
              ).then((_) => setState(() {}));
            },
          ),
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
              color: kBrandGreen,
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
            if (offerProducts.isNotEmpty) _buildOffersBanner(),
            const SizedBox(height: 12),
            _buildSectionsBody(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomSheet: _buildCartBar(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kBrandGreen,
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

  Widget _buildOffersBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "🔥 Best Deals",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.deepOrange.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Favorites",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductsScreen(
                          title: "Best Deals",
                          cart: cart,
                          onChangeQty: _changeQty,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: Text("View All",
                      style: TextStyle(
                          color: Colors.deepOrange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: offerProducts.length,
              itemBuilder: (_, i) {
                final p = offerProducts[i];
                final qty = cart[p.id]?.qty ?? 0;
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
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
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Image.network(
                              p.image,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 110,
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${p.discountPercent}% OFF",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
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
                              child: Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text("₹${p.price}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  "₹${p.mrp}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              height: 28,
                              child: qty == 0
                                  ? OutlinedButton(
                                      onPressed: () => _changeQty(p, 1),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: kBrandGreen,
                                        side:
                                            const BorderSide(color: kBrandGreen),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text("ADD",
                                          style: TextStyle(fontSize: 11)),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          onTap: () => _changeQty(p, -1),
                                          child: const Icon(Icons.remove_circle,
                                              color: kBrandGreen, size: 22),
                                        ),
                                        Text('$qty',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        InkWell(
                                          onTap: () => _changeQty(p, 1),
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
                );
              },
            ),
          ),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: kBrandGreenLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              sectionName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kBrandGreen,
              ),
            ),
          ),
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
