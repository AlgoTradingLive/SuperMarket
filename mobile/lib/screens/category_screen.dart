import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/subcategory.dart';
import '../services/api_service.dart';
import 'products_screen.dart';

const kBrandGreen = Color(0xFF2E7D32);
const kBrandGreenLight = Color(0xFFE8F5E9);

class CategoryScreen extends StatefulWidget {
  final Map<int, CartItem> cart;
  final void Function(Product product, int delta) onChangeQty;

  const CategoryScreen({super.key, required this.cart, required this.onChangeQty});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  Map<String, List<Subcategory>> sections = {};
  String? selectedSection;
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
      final data = await ApiService.fetchSubcategories();
      setState(() {
        sections = data;
        selectedSection = data.keys.isNotEmpty ? data.keys.first : null;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Categories load करता आल्या नाहीत.\nपुन्हा प्रयत्न करा.";
        loading = false;
      });
    }
  }

  void _openSubcategory(Subcategory s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductsScreen(
          title: s.name,
          subCategory: s.name,
          cart: widget.cart,
          onChangeQty: widget.onChangeQty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kBrandGreen,
        foregroundColor: Colors.white,
        title: const Text("SHOP BY CATEGORY"),
      ),
      body: _buildBody(),
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
    if (sections.isEmpty) {
      return const Center(child: Text("Categories सापडल्या नाहीत"));
    }

    final sectionNames = sections.keys.toList();

    return Row(
      children: [
        // डावीकडे main categories
        SizedBox(
          width: 110,
          child: ListView.builder(
            itemCount: sectionNames.length,
            itemBuilder: (_, i) {
              final name = sectionNames[i];
              final active = name == selectedSection;
              final icon = sections[name]!.isNotEmpty ? sections[name]![0].icon : "";
              return InkWell(
                onTap: () => setState(() => selectedSection = name),
                child: Container(
                  color: active ? Colors.white : Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: active
                              ? Border.all(color: kBrandGreen, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            icon,
                            height: 56,
                            width: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 56,
                              width: 56,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported_outlined, size: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          color: active ? kBrandGreen : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // उजवीकडे subcategories
        Expanded(
          child: selectedSection == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: kBrandGreenLight,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        selectedSection!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: kBrandGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 122,
                      ),
                      itemCount: sections[selectedSection]!.length,
                      itemBuilder: (_, i) {
                        final s = sections[selectedSection]![i];
                        return InkWell(
                          onTap: () => _openSubcategory(s),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                    child: const Icon(Icons.image_not_supported_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, height: 1.15),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
