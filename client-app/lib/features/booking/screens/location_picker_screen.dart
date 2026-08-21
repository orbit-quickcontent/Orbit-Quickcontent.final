import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../../core/theme.dart';

class LocationPickerScreen extends StatefulWidget {
  final String packageId;
  const LocationPickerScreen({super.key, required this.packageId});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  MapLibreMapController? _mapController;
  LatLng _selectedLocation = const LatLng(28.6139, 77.2090); // Delhi default
  String _address = '';
  bool _isLocating = true;
  Symbol? _marker;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      // Try fast lookup first
      Position? position = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: true,
      );

      // If no last known position, request current position
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // faster than high
        timeLimit: const Duration(seconds: 5),
        forceAndroidLocationManager: true,
      );

      setState(() {
        _selectedLocation = LatLng(position!.latitude, position.longitude);
        _isLocating = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 15),
      );
      await _updateMarker(_selectedLocation);
      await _reverseGeocode(_selectedLocation);
    } catch (_) {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _updateMarker(LatLng position) async {
    if (_mapController == null) return;
    if (_marker != null) {
      await _mapController!.removeSymbol(_marker!);
    }
    _marker = await _mapController!.addSymbol(SymbolOptions(
      geometry: position,
      iconImage: 'marker',
      iconSize: 1.5,
      iconColor: '#47D6FF',
    ));
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      // Use Nominatim for reverse geocoding
      final nominatimRes = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json'),
        headers: {'User-Agent': 'ORBIT-App/1.0'},
      );
      if (nominatimRes.statusCode == 200) {
        final data = jsonDecode(nominatimRes.body);
        setState(() => _address = data['display_name'] ?? '');
      }
    } catch (_) {
      setState(() => _address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
    }
  }

  void _onMapClick(math.Point<double> point, LatLng coordinates) async {
    setState(() {
      _selectedLocation = coordinates;
      _address = 'Updating address...';
    });
    await _updateMarker(coordinates);
    await _reverseGeocode(coordinates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          MapLibreMap(
            styleString: 'https://tiles.openfreemap.org/styles/liberty',
            initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 14),
            onMapCreated: (controller) {
              _mapController = controller;
              if (!_isLocating) {
                _updateMarker(_selectedLocation);
              }
            },
            onMapClick: _onMapClick,
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.none,
          ),

          // ── Top: Back button + Search ─────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: OrbitClientTheme.surfaceContainerLowest.withOpacity(0.9),
                            border: Border.all(color: OrbitClientTheme.outlineVariant),
                          ),
                          child: const Icon(Icons.arrow_back_ios, size: 16, color: OrbitClientTheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: OrbitClientTheme.surfaceContainerLowest.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: OrbitClientTheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(Icons.search, size: 18, color: OrbitClientTheme.outline),
                              const SizedBox(width: 8),
                              const Text('Tap on map to select location', style: TextStyle(fontSize: 13, color: OrbitClientTheme.outline)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom: Address + Confirm ──────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                color: OrbitClientTheme.surfaceContainerLowest.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(top: BorderSide(color: OrbitClientTheme.outlineVariant, width: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: OrbitClientTheme.primaryGradient,
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SELECTED LOCATION', style: OrbitClientTheme.textTheme.labelSmall),
                            const SizedBox(height: 2),
                            Text(
                              _address.isEmpty ? 'Tap the map to set location' : _address,
                              style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurface),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('My Location'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: OrbitClientTheme.primaryFixed,
                            side: const BorderSide(color: OrbitClientTheme.outlineVariant),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: OrbitGradientButton(
                          label: 'Proceed to Review',
                          height: 46,
                          onPressed: () {
                            OrbitMotion.lightTap();
                            final confirmedAddress = _address.isNotEmpty && !_address.startsWith('Updating')
                                ? _address
                                : 'Connaught Place, New Delhi';
                            context.push('/review', extra: {
                              'packageId': widget.packageId,
                              'latitude': _selectedLocation.latitude,
                              'longitude': _selectedLocation.longitude,
                              'address': confirmedAddress,
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }
}
