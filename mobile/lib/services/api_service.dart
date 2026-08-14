import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/subcategory.dart';
import '../models/order.dart';

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

  // Only discounted products — used by the home screen's "deals" row so it
  // doesn't have to download the entire catalog (which has grown a lot
  // after the brand-bundle imports) just to find a handful of items.
  static Future<List<Product>> fetchDeals() async {
    final uri = Uri.parse("$baseUrl/products").replace(queryParameters: {"deals": "true"});
    final res = await http.get(uri).timeout(const Duration(seconds: 60));

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    }
    throw Exception("Deals load करता आले नाहीत");
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
    int? storeId,
    String? storeName,
    String paymentMethod = "COD",
    String? razorpayOrderId,
    String? razorpayPaymentId,
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
      "storeId": storeId,
      "storeName": storeName,
      "paymentMethod": paymentMethod,
      "razorpayOrderId": razorpayOrderId,
      "razorpayPaymentId": razorpayPaymentId,
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

  static Future<List<Order>> fetchMyOrders(String phone) async {
    final uri = Uri.parse("$baseUrl/orders").replace(queryParameters: {"phone": phone});
    final res = await http.get(uri).timeout(const Duration(seconds: 60));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Order.fromJson(e)).toList();
    }
    throw Exception("Orders load करता आले नाहीत");
  }

  static Future<Map<String, dynamic>> createRazorpayOrder(int amount) async {
    final uri = Uri.parse("$baseUrl/payment/create-order");
    final res = await http
        .post(uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"amount": amount}))
        .timeout(const Duration(seconds: 30));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data;
    throw Exception(data['error'] ?? "Payment order तयार करता आला नाही");
  }

  static Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final uri = Uri.parse("$baseUrl/payment/verify");
    final res = await http
        .post(uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "razorpay_order_id": razorpayOrderId,
              "razorpay_payment_id": razorpayPaymentId,
              "razorpay_signature": razorpaySignature,
            }))
        .timeout(const Duration(seconds: 30));
    final data = jsonDecode(res.body);
    return data['verified'] == true;
  }

  static Future<void> registerDeviceToken({
    required String phone,
    required String token,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/device-token");
      await http
          .post(uri,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"phone": phone, "token": token}))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Non-critical — silently ignore if this fails
    }
  }
}
