import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({super.key});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  LatLng? _picked;
  String area = "", city = "", stateName = "", pincode = "";
  bool _fetching = false;
  DateTime? _lastTap;

  Future<void> _reverseGeocode(LatLng pos) async {
    if (_fetching) return; // Prevent multiple simultaneous calls
    setState(() => _fetching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json&addressdetails=1',
      );
      final res = await http.get(
        url,
        headers: {
          // 👇 Required by Nominatim (use your project name + email)
          'User-Agent': 'LocalMartApp/1.0 (palak.localmart.project@example.com)',
          'Accept-Language': 'en',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] ?? {};

        setState(() {
          area = addr['suburb'] ??
              addr['neighbourhood'] ??
              addr['village'] ??
              addr['quarter'] ??
              '';
          city = addr['city'] ?? addr['town'] ?? addr['village'] ?? '';
          stateName = addr['state'] ?? '';
          pincode = addr['postcode'] ?? '';
        });
      } else {
        debugPrint('Reverse geocode failed with code ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  void _confirmAndContinue(Map<String, dynamic>? prevArgs) {
    if (_picked == null) return;
    Navigator.pushReplacementNamed(
      context,
      '/address-details',
      arguments: {
        ...?prevArgs,
        'lat': _picked!.latitude,
        'lng': _picked!.longitude,
        'area': area,
        'city': city,
        'state': stateName,
        'pincode': pincode,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prevArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7FECEC), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                "Mark your exact location",
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(20.5937, 78.9629), // India
                    initialZoom: 4.8,
                    onTap: (tapPos, point) async {
                      // 👇 Debounce — ignore rapid taps
                      final now = DateTime.now();
                      if (_lastTap != null &&
                          now.difference(_lastTap!) < const Duration(seconds: 1)) {
                        return;
                      }
                      _lastTap = now;

                      setState(() => _picked = point);
                      await _reverseGeocode(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (_picked != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _picked!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.redAccent,
                            ),
                          )
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _picked == null
                          ? "Tap on the map to drop a pin."
                          : _fetching
                          ? "Detecting area, city, state & pincode…"
                          : (pincode.isEmpty && city.isEmpty)
                          ? "Couldn’t detect address — fill manually on next screen."
                          : "Detected: ${[
                        if (area.isNotEmpty) area,
                        if (city.isNotEmpty) city,
                        if (stateName.isNotEmpty) stateName,
                        if (pincode.isNotEmpty) pincode
                      ].join(', ')}",
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                        _picked == null || _fetching ? null : () => _confirmAndContinue(prevArgs),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Confirm & Continue",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
