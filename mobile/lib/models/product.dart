class Product {
  final int id;
  final String name;
  final String category;
  final int price;
  final int mrp;
  final String unit;
  final String image;
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.mrp,
    required this.unit,
    required this.image,
    required this.inStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0) is int
          ? json['price']
          : (json['price'] as num).toInt(),
      mrp: (json['mrp'] ?? 0) is int
          ? json['mrp']
          : (json['mrp'] as num).toInt(),
      unit: json['unit'] ?? '',
      image: json['image'] ?? '',
      inStock: json['inStock'] ?? true,
    );
  }
}

class CartItem {
  final Product product;
  int qty;

  CartItem({required this.product, this.qty = 1});

  int get total => product.price * qty;
}
