import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/product.dart';
import '../models/store.dart';
import '../services/api_service.dart';
import '../services/push_service.dart';
import 'store_select_screen.dart';

const kBrandGreen = Color(0xFFD32F2F);

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
  String paymentMethod = "COD"; // "COD" or "Online"
  late Razorpay _razorpay;
  String? _pendingRazorpayOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _loadSavedDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickStore());
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingRazorpayOrderId == null) return;
    try {
      final verified = await ApiService.verifyPayment(
        razorpayOrderId: _pendingRazorpayOrderId!,
        razorpayPaymentId: response.paymentId ?? "",
        razorpaySignature: response.signature ?? "",
      );
      if (!verified) {
        _showError("Payment verify करता आलं नाही, पुन्हा प्रयत्न करा.");
        setState(() => placing = false);
        return;
      }
      await _finalizeOrder(
        paymentMethod: "Online",
        razorpayOrderId: _pendingRazorpayOrderId,
        razorpayPaymentId: response.paymentId,
      );
    } catch (e) {
      _showError(e.toString());
      setState(() => placing = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => placing = false);
    _showError("Payment अयशस्वी झालं: ${response.message ?? 'unknown error'}");
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => placing = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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

    if (paymentMethod == "COD") {
      try {
        await _finalizeOrder(paymentMethod: "COD");
      } catch (e) {
        _showError(e.toString());
      } finally {
        if (mounted) setState(() => placing = false);
      }
      return;
    }

    // Online payment flow: create a Razorpay order first, then open checkout.
    try {
      final rzpOrder = await ApiService.createRazorpayOrder(widget.total);
      _pendingRazorpayOrderId = rzpOrder['orderId'];

      final options = {
        'key': rzpOrder['keyId'],
        'amount': rzpOrder['amount'],
        'order_id': rzpOrder['orderId'],
        'currency': 'INR',
        'name': 'SM Super Market',
        'description': 'Order Payment',
        'prefill': {
          'contact': phoneCtrl.text.trim(),
          'name': nameCtrl.text.trim(),
        },
      };
      _razorpay.open(options);
      // placing stays true while Razorpay checkout is open;
      // success/error handlers will reset it.
    } catch (e) {
      _showError(e.toString());
      setState(() => placing = false);
    }
  }

  Future<void> _finalizeOrder({
    required String paymentMethod,
    String? razorpayOrderId,
    String? razorpayPaymentId,
  }) async {
    final res = await ApiService.placeOrder(
      items: widget.items,
      customerName: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      storeId: selectedStore!.id,
      storeName: selectedStore!.name,
      paymentMethod: paymentMethod,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
    );
    final orderId = res['order']['id'];
    await _saveDetails();
    if (PushService.currentToken != null) {
      ApiService.registerDeviceToken(
        phone: phoneCtrl.text.trim(),
        token: PushService.currentToken!,
      );
    }

    if (!mounted) return;
    setState(() => placing = false);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✅ Order Placed!"),
        content: Text(
          "Order #$orderId confirmed for ₹${widget.total}.\n"
          "${paymentMethod == 'Online' ? 'Payment received online.' : 'Pay on delivery.'}",
        ),
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
            const Text("Payment Method",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _paymentOption(
                    label: "Cash on Delivery",
                    icon: Icons.money,
                    value: "COD",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _paymentOption(
                    label: "Pay Online (UPI/Card)",
                    icon: Icons.qr_code_scanner,
                    value: "Online",
                  ),
                ),
              ],
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
                  : Text(
                      paymentMethod == "Online"
                          ? "Pay ₹${widget.total} Online"
                          : "Place Order (Cash on Delivery)",
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final selected = paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? kBrandGreen : Colors.grey.shade300, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
          color: selected ? kBrandGreen.withOpacity(0.06) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? kBrandGreen : Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? kBrandGreen : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
