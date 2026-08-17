import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

const String _kSocketUrl = String.fromEnvironment('SOCKET_URL', defaultValue: 'http://10.0.2.2:5000');

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;
  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  MapLibreMapController? _mapController;
  io.Socket? _socket;
  LatLng? _partnerLocation;
  LatLng? _clientLocation;
  double? _etaMinutes;
  Symbol? _partnerMarker;
  Line? _routeLine;
  String _partnerName = 'Your Partner';

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _initSocket();
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    try {
      final res = await apiClient.get('/bookings/${widget.bookingId}');
      final booking = res.data;
      setState(() {
        _clientLocation = LatLng(booking['latitude'] ?? 28.6, booking['longitude'] ?? 77.2);
        _partnerName = booking['partner']?['user']?['name'] ?? 'Your Partner';
      });
    } catch (_) {}
  }

  Future<void> _initSocket() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'orbit_access_token');

    _socket = io.io(_kSocketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build());

    _socket!.connect();
    _socket!.emit('join:booking', widget.bookingId);

    _socket!.on('partner:location', (data) async {
      if (!mounted) return;
      final newLocation = LatLng(data['latitude'] as double, data['longitude'] as double);
      setState(() {
        _partnerLocation = newLocation;
        _etaMinutes = data['etaMinutes'] as double?;
      });
      await _updatePartnerMarker(newLocation);
      if (_clientLocation != null) {
        await _drawRoute(newLocation, _clientLocation!);
      }
    });
  }

  Future<void> _updatePartnerMarker(LatLng position) async {
    if (_mapController == null) return;
    if (_partnerMarker != null) await _mapController!.removeSymbol(_partnerMarker!);
    _partnerMarker = await _mapController!.addSymbol(SymbolOptions(
      geometry: position,
      iconImage: 'marker',
      iconSize: 1.2,
      textField: _partnerName,
      textColor: '#47D6FF',
      textSize: 11,
      textOffset: const Offset(0, 1.5),
    ));
    _mapController!.animateCamera(CameraUpdate.newLatLng(position));
  }

  Future<void> _drawRoute(LatLng origin, LatLng dest) async {
    try {
      final res = await apiClient.get('/maps/route', params: {
        'originLat': origin.latitude,
        'originLng': origin.longitude,
        'destLat': dest.latitude,
        'destLng': dest.longitude,
      });
      final geometry = res.data['geometry'];
      if (geometry != null && _mapController != null) {
        if (_routeLine != null) await _mapController!.removeLine(_routeLine!);
        final coords = (geometry['coordinates'] as List)
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();
        _routeLine = await _mapController!.addLine(LineOptions(
          geometry: coords,
          lineColor: '#47D6FF',
          lineWidth: 3.0,
          lineOpacity: 0.8,
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          MapLibreMap(
            styleString: 'https://tiles.openfreemap.org/styles/liberty',
            initialCameraPosition: CameraPosition(
              target: _clientLocation ?? const LatLng(28.6139, 77.2090),
              zoom: 14,
            ),
            onMapCreated: (controller) async {
              _mapController = controller;
              if (_clientLocation != null) {
                await controller.addSymbol(SymbolOptions(
                  geometry: _clientLocation!,
                  iconImage: 'marker',
                  iconColor: '#EDB1FF',
                ));
              }
            },
            myLocationEnabled: true,
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OrbitClientTheme.surfaceContainerLowest.withValues(alpha: 0.9),
                    border: Border.all(color: OrbitClientTheme.outlineVariant),
                  ),
                  child: const Icon(Icons.arrow_back_ios, size: 16, color: OrbitClientTheme.onSurface),
                ),
              ),
            ),
          ),

          // Bottom ETA card
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                color: OrbitClientTheme.surfaceContainerLowest.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: OrbitClientTheme.primaryGradient),
                  child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_partnerName, style: OrbitClientTheme.textTheme.titleMedium),
                  Text(
                    _partnerLocation != null
                        ? (_etaMinutes != null ? 'ETA: ~${_etaMinutes!.round()} min' : 'Partner is on the way')
                        : 'Waiting for partner location...',
                    style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant),
                  ),
                ])),
                if (_etaMinutes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(gradient: OrbitClientTheme.primaryGradient, borderRadius: BorderRadius.circular(999)),
                    child: Text('~${_etaMinutes!.round()} min', style: OrbitClientTheme.textTheme.labelMedium?.copyWith(color: Colors.white)),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
