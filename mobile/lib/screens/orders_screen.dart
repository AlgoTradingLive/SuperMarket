import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../services/api_service.dart';

const kBrandGreen = Color(0xFF2E7D32);

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order>? orders;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      orders = null;
      error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('saved_phone') ?? '';
    if (phone.isEmpty) {
      setState(() => orders = []);
      return;
    }
    try {
      final result = await ApiService.fetchMyOrders(phone);
      if (!mounted) return;
      setState(() => orders = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandGreen,
        foregroundColor: Colors.white,
        title: const Text("My Orders"),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (error != null) {
      return ListView(children: [
        const SizedBox(height: 60),
        Center(child: Text(error!)),
      ]);
    }
    if (orders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders!.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 80),
        Center(
          child: Text("अजून एकही ऑर्डर नाहीये",
              style: TextStyle(color: Colors.grey, fontSize: 15)),
        ),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders!.length,
      itemBuilder: (_, i) => _orderCard(orders![i]),
    );
  }

  Widget _orderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Order #${order.id}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("₹${order.total}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: kBrandGreen)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}  ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _statusTracker(order),
            const SizedBox(height: 10),
            ...order.items.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text("${i.qty} × ${i.name}",
                      style: const TextStyle(fontSize: 13)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _statusTracker(Order order) {
    final steps = Order.allStatuses;
    final currentIndex = order.statusIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final passed = (i ~/ 2) < currentIndex;
              return Expanded(
                child: Container(
                  height: 3,
                  color: passed ? kBrandGreen : Colors.grey.shade300,
                ),
              );
            }
            final stepIndex = i ~/ 2;
            final reached = stepIndex <= currentIndex;
            return Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached ? kBrandGreen : Colors.grey.shade300,
              ),
              child: reached
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          steps[currentIndex],
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: kBrandGreen, fontSize: 12),
        ),
      ],
    );
  }
}
