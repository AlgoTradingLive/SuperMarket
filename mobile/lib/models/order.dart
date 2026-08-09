class OrderItem {
  final String name;
  final int qty;
  final int price;

  OrderItem({required this.name, required this.qty, required this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      qty: (json['qty'] ?? 1) is int ? json['qty'] : (json['qty'] as num).toInt(),
      price: (json['price'] ?? 0) is int ? json['price'] : (json['price'] as num).toInt(),
    );
  }
}

class Order {
  final int id;
  final List<OrderItem> items;
  final String customerName;
  final String phone;
  final String address;
  final int total;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
      customerName: json['customerName'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      total: (json['total'] ?? 0) is int ? json['total'] : (json['total'] as num).toInt(),
      status: json['status'] ?? 'Placed',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Steps to render progress in the tracking UI
  static const List<String> allStatuses = [
    "Placed",
    "Packed",
    "Out for Delivery",
    "Delivered",
  ];

  int get statusIndex => allStatuses.indexOf(status).clamp(0, allStatuses.length - 1);
}
