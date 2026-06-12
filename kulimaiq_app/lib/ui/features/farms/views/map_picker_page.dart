import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// Result returned when the user confirms a pin on the map.
class MapPickResult {
  const MapPickResult({
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.region,
  });

  final double latitude;
  final double longitude;

  /// Country name resolved via Nominatim reverse geocoding (may be empty if
  /// offline or the reverse-geocode call fails).
  final String country;

  /// Sub-region (state / county / district) resolved via Nominatim.
  final String region;
}

/// Full-screen map that lets the user pin any location in the world.
///
/// Usage:
/// ```dart
/// final result = await Navigator.push<MapPickResult>(
///   context,
///   MaterialPageRoute(builder: (_) => MapPickerPage(initial: ...)),
/// );
/// ```
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, this.initial});

  /// Pre-existing coordinates to centre the map on (e.g. when editing).
  final LatLng? initial;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final _mapController = MapController();

  LatLng? _pin;
  String _country = '';
  String _region = '';
  bool _geocoding = false;
  bool _gpsLoading = false;

  static const _defaultCenter = LatLng(1.0, 30.0); // centred on East Africa
  static const _defaultZoom = 4.0;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _pin = widget.initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.initial!, 10);
        _reverseGeocode(widget.initial!);
      });
    }
  }

  // ── Map interaction ───────────────────────────────────────────────────────

  void _onTap(TapPosition _, LatLng point) {
    setState(() {
      _pin = point;
      _country = '';
      _region = '';
    });
    _reverseGeocode(point);
  }

  // ── GPS ───────────────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    setState(() => _gpsLoading = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      _mapController.move(here, 13);
      setState(() => _pin = here);
      await _reverseGeocode(here);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location')),
        );
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  // ── Nominatim reverse geocoding ───────────────────────────────────────────

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _geocoding = true);
    try {
      final uri =
          Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
        queryParameters: {
          'format': 'json',
          'lat': point.latitude.toStringAsFixed(6),
          'lon': point.longitude.toStringAsFixed(6),
          'accept-language': 'en',
        },
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'KulimaIQ/1.0 (crop-health-app)'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final country = (address['country'] as String?) ?? '';
        // Prefer state > county > region > territory for sub-region
        final region = ((address['state'] ??
                address['county'] ??
                address['region'] ??
                address['territory'] ??
                address['city'] ??
                '') as String);
        if (mounted) {
          setState(() {
            _country = country;
            _region = region;
          });
        }
      }
    } catch (_) {
      // Offline or timeout — leave country/region blank
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  // ── Confirm ───────────────────────────────────────────────────────────────

  void _confirm() {
    if (_pin == null) return;
    Navigator.of(context).pop(
      MapPickResult(
        latitude: _pin!.latitude,
        longitude: _pin!.longitude,
        country: _country,
        region: _region,
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initial ?? _defaultCenter,
              initialZoom:
                  widget.initial != null ? 10.0 : _defaultZoom,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kulimaiq.app',
              ),
              if (_pin != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pin!,
                      width: 40,
                      height: 48,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.agriculture_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(10, 6),
                            painter: _PinTailPainter(color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top bar ───────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _MapButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app_rounded,
                              size: 16,
                              color: AppTheme.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Tap the map to pin your farm location',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── My-location FAB ───────────────────────────────────────────────
          Positioned(
            right: AppSpacing.md,
            bottom: 200,
            child: _MapButton(
              icon: _gpsLoading ? null : Icons.my_location_rounded,
              loading: _gpsLoading,
              onTap: _gpsLoading ? null : _goToMyLocation,
              tooltip: 'Go to my current location',
            ),
          ),

          // ── Bottom panel ──────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomPanel(
              pin: _pin,
              country: _country,
              region: _region,
              geocoding: _geocoding,
              onConfirm: _pin != null ? _confirm : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom panel ──────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.pin,
    required this.country,
    required this.region,
    required this.geocoding,
    required this.onConfirm,
  });

  final LatLng? pin;
  final String country;
  final String region;
  final bool geocoding;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (pin == null) ...[
            Row(
              children: [
                Icon(Icons.touch_app_rounded,
                    color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'No location selected yet',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded,
                    color: AppTheme.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (geocoding)
                        Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('Looking up address…',
                                style: TextStyle(fontSize: 13)),
                          ],
                        )
                      else if (country.isNotEmpty || region.isNotEmpty) ...[
                        if (region.isNotEmpty)
                          Text(
                            region,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        if (country.isNotEmpty)
                          Text(
                            country,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ] else
                        Text(
                          'Address unavailable (offline)',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${pin!.latitude.toStringAsFixed(5)}, '
                        '${pin!.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Confirm location'),
              style: FilledButton.styleFrom(
                backgroundColor:
                    onConfirm != null ? AppTheme.primary : AppTheme.border,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map overlay button ────────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  const _MapButton({
    this.icon,
    this.loading = false,
    this.onTap,
    this.tooltip,
  });

  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, size: 22, color: AppTheme.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pin tail painter ──────────────────────────────────────────────────────────

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}
