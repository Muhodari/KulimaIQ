import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/crop_type.dart';
import '../../../../domain/models/farm.dart';
import '../../../../l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/farm_view_model.dart';
import 'map_picker_page.dart';

class FarmFormSheet extends StatefulWidget {
  const FarmFormSheet({super.key, this.farm});

  /// Null = add mode. Non-null = edit mode.
  final Farm? farm;

  @override
  State<FarmFormSheet> createState() => _FarmFormSheetState();
}

class _FarmFormSheetState extends State<FarmFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _gpsLoading = false;

  final Set<CropType> _crops = {};
  FarmHealthStatus _status = FarmHealthStatus.unknown;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.farm;
    if (f != null) {
      _nameCtrl.text = f.name;
      _countryCtrl.text = f.country;
      _regionCtrl.text = f.region;
      _sizeCtrl.text = f.sizeHa > 0 ? f.sizeHa.toString() : '';
      _notesCtrl.text = f.notes;
      _latitude = f.latitude;
      _longitude = f.longitude;
      _crops.addAll(f.crops);
      _status = f.healthStatus;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _regionCtrl.dispose();
    _sizeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Location helpers ──────────────────────────────────────────────────────

  /// Opens the full-screen map picker. The user can tap anywhere in the world
  /// to set the farm pin. Nominatim reverse geocoding auto-fills country and
  /// region when online.
  Future<void> _openMapPicker() async {
    final initial = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : null;

    final result = await Navigator.of(context).push<MapPickResult>(
      MaterialPageRoute(
        builder: (_) => MapPickerPage(initial: initial),
        fullscreenDialog: true,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
      // Auto-fill country / region only when they are blank or the map
      // returned non-empty values.
      if (result.country.isNotEmpty && _countryCtrl.text.trim().isEmpty) {
        _countryCtrl.text = result.country;
      }
      if (result.region.isNotEmpty && _regionCtrl.text.trim().isEmpty) {
        _regionCtrl.text = result.region;
      }
    }
  }

  /// Quick shortcut: get the device's current GPS position and jump to the
  /// map picker centred there so the user can still fine-tune the pin.
  Future<void> _useCurrentLocationOnMap() async {
    setState(() => _gpsLoading = true);
    LatLng? devicePos;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          final s = context.read<FarmViewModel>().strings;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.t('error_location_permission'))),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      devicePos = LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      if (mounted) {
        final s = context.read<FarmViewModel>().strings;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('error_location_unavailable'))),
        );
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }

    if (devicePos != null && mounted) {
      // Open the map pre-centred on the device's current location so the user
      // can confirm or adjust the pin.
      final result = await Navigator.of(context).push<MapPickResult>(
        MaterialPageRoute(
          builder: (_) => MapPickerPage(initial: devicePos),
          fullscreenDialog: true,
        ),
      );
      if (result != null && mounted) {
        setState(() {
          _latitude = result.latitude;
          _longitude = result.longitude;
        });
        if (result.country.isNotEmpty && _countryCtrl.text.trim().isEmpty) {
          _countryCtrl.text = result.country;
        }
        if (result.region.isNotEmpty && _regionCtrl.text.trim().isEmpty) {
          _regionCtrl.text = result.region;
        }
      }
    }
  }

  void _clearCoordinates() => setState(() {
        _latitude = null;
        _longitude = null;
      });

  // ── Save / delete ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final vm = context.read<FarmViewModel>();
    final s = vm.strings;
    try {
      if (widget.farm == null) {
        await vm.addFarm(
          name: _nameCtrl.text,
          country: _countryCtrl.text,
          region: _regionCtrl.text,
          latitude: _latitude,
          longitude: _longitude,
          sizeHa: double.tryParse(_sizeCtrl.text) ?? 0,
          crops: _crops.toList(),
          notes: _notesCtrl.text,
        );
      } else {
        await vm.updateFarm(
          widget.farm!.copyWith(
            name: _nameCtrl.text.trim(),
            country: _countryCtrl.text.trim(),
            region: _regionCtrl.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
            clearCoordinates: _latitude == null,
            sizeHa: double.tryParse(_sizeCtrl.text) ?? 0,
            crops: _crops.toList(),
            notes: _notesCtrl.text.trim(),
            healthStatus: _status,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('error_generic'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final vm = context.read<FarmViewModel>();
    final s = vm.strings;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('farm_delete_confirm_title')),
        content: Text(s.t('farm_delete_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.t('farm_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.t('farm_delete'),
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await vm.deleteFarm(widget.farm!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FarmViewModel>();
    final s = vm.strings;
    final isEdit = widget.farm != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Text(
                    isEdit ? s.t('farm_edit_title') : s.t('farm_add_title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (isEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.error),
                      onPressed: _delete,
                    ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  children: [
                    // ── Name ───────────────────────────────────────────────
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: s.t('farm_field_name'),
                        prefixIcon: const Icon(Icons.landscape_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s.t('farm_required')
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // ── Country ────────────────────────────────────────────
                    TextFormField(
                      controller: _countryCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: s.t('farm_field_country'),
                        prefixIcon: const Icon(Icons.public_outlined),
                        hintText: s.t('farm_field_country_hint'),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s.t('farm_required')
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // ── Region / Sector ────────────────────────────────────
                    TextFormField(
                      controller: _regionCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: s.t('farm_field_region'),
                        prefixIcon: const Icon(Icons.place_outlined),
                        hintText: s.t('farm_field_region_hint'),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s.t('farm_required')
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // ── Map area (GPS coordinates) ─────────────────────────
                    _LocationSection(
                      latitude: _latitude,
                      longitude: _longitude,
                      gpsLoading: _gpsLoading,
                      onPickOnMap: _openMapPicker,
                      onUseCurrentLocation: _useCurrentLocationOnMap,
                      onClear: _clearCoordinates,
                      strings: s,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // ── Size ───────────────────────────────────────────────
                    TextFormField(
                      controller: _sizeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: s.t('farm_field_size'),
                        suffixText: 'ha',
                        prefixIcon:
                            const Icon(Icons.straighten_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // ── Crops ──────────────────────────────────────────────
                    Text(
                      s.t('farm_field_crops'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: CropType.values.map((crop) {
                        final selected = _crops.contains(crop);
                        return FilterChip(
                          label: Text(s.cropLabel(crop.id)),
                          selected: selected,
                          selectedColor:
                              AppTheme.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppTheme.primary,
                          onSelected: (_) => setState(() {
                            if (selected) {
                              _crops.remove(crop);
                            } else {
                              _crops.add(crop);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        s.t('farm_field_status'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SegmentedButton<FarmHealthStatus>(
                        segments: [
                          ButtonSegment(
                            value: FarmHealthStatus.healthy,
                            label: Text(s.t('farm_status_healthy')),
                          ),
                          ButtonSegment(
                            value: FarmHealthStatus.atRisk,
                            label: Text(s.t('farm_status_at_risk')),
                          ),
                          ButtonSegment(
                            value: FarmHealthStatus.diseased,
                            label: Text(s.t('farm_status_diseased')),
                          ),
                        ],
                        selected: {_status},
                        onSelectionChanged: (set) =>
                            setState(() => _status = set.first),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    // ── Notes ──────────────────────────────────────────────
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: s.t('farm_field_notes'),
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEdit
                              ? s.t('farm_save')
                              : s.t('farm_create')),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location section widget ───────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.latitude,
    required this.longitude,
    required this.gpsLoading,
    required this.onPickOnMap,
    required this.onUseCurrentLocation,
    required this.onClear,
    required this.strings,
  });

  final double? latitude;
  final double? longitude;
  final bool gpsLoading;
  final VoidCallback onPickOnMap;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onClear;
  final dynamic strings;

  bool get _hasPinned => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.t('farm_field_map_area'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        // ── Coordinates display (when pinned) ──────────────────────────
        if (_hasPinned)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${latitude!.toStringAsFixed(5)}, '
                    '${longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onPickOnMap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    strings.t('farm_change_location'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppTheme.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClear,
                  tooltip: strings.t('farm_clear_location'),
                ),
              ],
            ),
          )
        else
          Text(
            strings.t('farm_field_map_area_hint'),
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        const SizedBox(height: AppSpacing.md),
        // ── Action buttons ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickOnMap,
                icon: const Icon(Icons.map_outlined, size: 16),
                label: Text(
                  strings.t('farm_pick_on_map'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: gpsLoading ? null : onUseCurrentLocation,
                icon: gpsLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 16),
                label: Text(
                  strings.t('farm_detect_location'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
