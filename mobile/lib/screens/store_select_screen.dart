import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/store.dart';
import '../services/api_service.dart';

const kBrandGreen = Color(0xFF2E7D32);

class StoreSelectScreen extends StatefulWidget {
  final Store? selected;
  const StoreSelectScreen({super.key, this.selected});

  @override
  State<StoreSelectScreen> createState() => _StoreSelectScreenState();
}

class _StoreSelectScreenState extends State<StoreSelectScreen> {
  List<Store>? stores;
  Store? chosen;
  Map<int, double>? distances; // storeId -> km
  String? locationError;
  String? loadError;
  bool locating = false;

  @override
  void initState() {
    super.initState();
    chosen = widget.selected;
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      stores = null;
      loadError = null;
    });
    try {
      final res = await http
          .get(Uri.parse("${ApiService.baseUrl}/stores"))
          .timeout(const Duration(seconds: 60));
      final List data = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        stores = data.map((e) => Store.fromJson(e)).toList();
      });
      _tryLocateNearest();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadError =
            "Store list load होत नाहीये.\nथोडं थांबून पुन्हा प्रयत्न करा (free server sleep मधून उठायला ५०+ सेकंद लागू शकतात).";
      });
    }
  }

  Future<void> _tryLocateNearest() async {
    setState(() {
      locating = true;
      locationError = null;
    });
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception("Location service बंद आहे");

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception("Location permission नाकारली");
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final Map<int, double> d = {};
      for (final s in stores ?? []) {
        d[s.id] = s.distanceFrom(pos.latitude, pos.longitude);
      }
      if (!mounted) return;
      setState(() {
        distances = d;
        locating = false;
        // auto-select nearest if nothing chosen yet
        if (chosen == null && stores != null && stores!.isNotEmpty) {
          final nearest = stores!.reduce(
              (a, b) => (d[a.id] ?? 999999) < (d[b.id] ?? 999999) ? a : b);
          chosen = nearest;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        locating = false;
        locationError = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandGreen,
        foregroundColor: Colors.white,
        title: const Text("Store निवडा"),
      ),
      body: loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadStores,
                      style: ElevatedButton.styleFrom(backgroundColor: kBrandGreen),
                      child: const Text("पुन्हा प्रयत्न करा",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          : stores == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
              children: [
                if (locating)
                  const LinearProgressIndicator(minHeight: 2),
                if (locationError != null)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade50,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "जवळचं store आपोआप शोधता आलं नाही ($locationError) — manually निवडा",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: stores!.length,
                    itemBuilder: (_, i) {
                      final s = stores![i];
                      final isChosen = chosen?.id == s.id;
                      final dist = distances?[s.id];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isChosen ? kBrandGreen : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => setState(() => chosen = s),
                          leading: Icon(
                            isChosen
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: kBrandGreen,
                          ),
                          title: Text(s.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(s.address,
                              style: const TextStyle(fontSize: 12)),
                          trailing: dist != null
                              ? Text("${dist.toStringAsFixed(1)} km",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: kBrandGreen))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: chosen == null
                          ? null
                          : () => Navigator.pop(context, chosen),
                      child: const Text("Confirm Store",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
