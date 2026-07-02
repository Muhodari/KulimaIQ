import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/crop_type.dart';
import '../../../../domain/models/farm.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crop_multi_select_field.dart';
import '../view_models/farm_view_model.dart';

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
  final _sizeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final Set<CropType> _crops = {};
  FarmHealthStatus _status = FarmHealthStatus.unknown;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final f = widget.farm;
    if (f != null) {
      _nameCtrl.text = f.name;
      _sizeCtrl.text = f.sizeHa > 0 ? f.sizeHa.toString() : '';
      _notesCtrl.text = f.notes;
      _crops.addAll(f.crops);
      _status = f.healthStatus;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sizeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

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
          sizeHa: double.tryParse(_sizeCtrl.text) ?? 0,
          crops: _crops.toList(),
          notes: _notesCtrl.text,
        );
      } else {
        await vm.updateFarm(
          widget.farm!.copyWith(
            name: _nameCtrl.text.trim(),
            sizeHa: double.tryParse(_sizeCtrl.text) ?? 0,
            crops: _crops.toList(),
            notes: _notesCtrl.text.trim(),
            healthStatus: _status,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError ? e.message : s.t('error_farm_save'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_deleting || widget.farm == null) return;
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
    if (confirm != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await vm.deleteFarm(widget.farm!.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('error_farm_delete'))),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FarmViewModel>();
    final s = vm.strings;
    final isEdit = widget.farm != null;

    return Stack(
      children: [
        DraggableScrollableSheet(
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
                      onPressed: (_saving || _deleting) ? null : _delete,
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
                    CropMultiSelectField(
                      label: s.t('farm_field_crops'),
                      selected: _crops,
                      strings: s,
                      onChanged: (crops) => setState(() {
                        _crops
                          ..clear()
                          ..addAll(crops);
                      }),
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
                      onPressed: (_saving || _deleting) ? null : _save,
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
    ),
        if (_deleting)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(s.t('farm_deleting')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
