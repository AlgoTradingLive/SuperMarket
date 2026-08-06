import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/subcategory.dart';

class ApiService {
  static const String baseUrl = "https://supermarket-1f13.onrender.com/api";

  static Future<List<Product>> fetchProducts({
    String section = "All",
    String subCategory = "",
    String search = "",
  }) async {
    final params = <String, String>{};
    if (section != "All") params['section'] = section;
    if (subCategory.isNotEmpty) params['subCategory'] = subCategory;
    if (search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse("$baseUrl/products").replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 60));

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    }
    throw Exception("Products load करता आले नाहीत");
  }

  static Future<Map<String, List<Subcategory>>> fetchSubcategories() async {
    final uri = Uri.parse("$baseUrl/subcategories");
    final res = await http.get(uri).timeout(const Duration(seconds: 60));

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      return data.map((section, list) => MapEntry(
            section,
            (list as List).map((e) => Subcategory.fromJson(e)).toList(),
          ));
    }
    throw Exception("Categories load करता आल्या नाहीत");
  }

  static Future<Map<String, dynamic>> placeOrder({
    required List<CartItem> items,
    required String customerName,
    required String phone,
    required String address,
  }) async {
    final uri = Uri.parse("$baseUrl/orders");
    final body = jsonEncode({
      "items": items
          .map((c) => {
                "id": c.product.id,
                "name": c.product.name,
                "price": c.product.price,
                "qty": c.qty,
              })
          .toList(),
      "customerName": customerName,
      "phone": phone,
      "address": address,
    });

    final res = await http
        .post(uri, headers: {"Content-Type": "application/json"}, body: body)
        .timeout(const Duration(seconds: 60));

    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      return data;
    }
    throw Exception(data['error'] ?? "Order place करता आला नाही");
  }
}
