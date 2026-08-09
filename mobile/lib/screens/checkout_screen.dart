import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/store.dart';
import '../services/api_service.dart';
import 'store_select_screen.dart';

const kBrandGreen = Color(0xFF2E7D32);

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final int total;

  const CheckoutScreen({super.key, required this.items, required this.total});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  bool placing = false;
  Store? selectedStore;

  Future<void> _pickStore() async {
    final result = await Navigator.push<Store>(
      context,
      MaterialPageRoute(
          builder: (_) => StoreSelectScreen(selected: selectedStore)),
    );
    if (result != null) {
      setState(() => selectedStore = result);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickStore());
  }

  Future<void> _loadSavedDetails() async {
    final prefs = await SharedPreferences.getInstance();
    nameCtrl.text = prefs.getString('saved_name') ?? '';
    phoneCtrl.text = prefs.getString('saved_phone') ?? '';
    addressCtrl.text = prefs.getString('saved_address') ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _saveDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_name', nameCtrl.text.trim());
    await prefs.setString('saved_phone', phoneCtrl.text.trim());
    await prefs.setString('saved_address', addressCtrl.text.trim());
  }

  Future<void> _placeOrder() async {
    if (nameCtrl.text.trim().isEmpty ||
        phoneCtrl.text.trim().isEmpty ||
        addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("कृपया सर्व माहिती भरा")));
      return;
    }
    if (selectedStore == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("कृपया Store निवडा")));
      return;
    }

    setState(() => placing = true);
    try {
      final res = await ApiService.placeOrder(
        items: widget.items,
        customerName: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        storeId: selectedStore!.id,
        storeName: selectedStore!.name,
      );
      final orderId = res['order']['id'];
      await _saveDetails();

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("✅ Order Placed!"),
          content: Text("Order #$orderId confirmed for ₹${widget.total}.\nPay on delivery."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Continue Shopping"),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandGreen,
        foregroundColor: Colors.white,
        title: const Text("Delivery Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _pickStore,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: kBrandGreen),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, color: kBrandGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedStore?.name ?? "Store निवडा",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: kBrandGreen),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Delivery Address", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            Text("Amount to Pay: ₹${widget.total}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: placing ? null : _placeOrder,
              child: placing
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Place Order (Cash on Delivery)", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
