import 'package:flutter/material.dart';

import '../../../domain/models/crop_type.dart';
import '../../../l10n/app_strings.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Opens a searchable bottom sheet to pick one crop.
Future<CropType?> showCropPickerSheet({
  required BuildContext context,
  required AppStrings strings,
  required CropType selected,
  List<CropType>? crops,
  String? title,
}) {
  return showModalBottomSheet<CropType>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CropPickerSheet(
      strings: strings,
      crops: crops ?? CropType.values,
      selected: {selected},
      multiSelect: false,
      title: title ?? strings.t('crop_picker_single_title'),
      onSingleSelected: (crop) => Navigator.pop(ctx, crop),
    ),
  );
}

/// Opens a searchable bottom sheet to pick multiple crops.
Future<Set<CropType>?> showCropMultiPickerSheet({
  required BuildContext context,
  required AppStrings strings,
  required Set<CropType> selected,
  List<CropType>? crops,
  String? title,
}) {
  return showModalBottomSheet<Set<CropType>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CropPickerSheet(
      strings: strings,
      crops: crops ?? CropType.values,
      selected: Set<CropType>.from(selected),
      multiSelect: true,
      title: title ?? strings.t('crop_picker_title'),
      onMultiDone: (value) => Navigator.pop(ctx, value),
    ),
  );
}

class _CropPickerSheet extends StatefulWidget {
  const _CropPickerSheet({
    required this.strings,
    required this.crops,
    required this.selected,
    required this.multiSelect,
    required this.title,
    this.onSingleSelected,
    this.onMultiDone,
  });

  final AppStrings strings;
  final List<CropType> crops;
  final Set<CropType> selected;
  final bool multiSelect;
  final String title;
  final ValueChanged<CropType>? onSingleSelected;
  final ValueChanged<Set<CropType>>? onMultiDone;

  @override
  State<_CropPickerSheet> createState() => _CropPickerSheetState();
}

class _CropPickerSheetState extends State<_CropPickerSheet> {
  final _searchCtrl = TextEditingController();
  late Set<CropType> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<CropType>.from(widget.selected);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CropType> get _filtered {
    if (_query.isEmpty) return widget.crops;
    final q = _query.toLowerCase();
    return widget.crops.where((crop) {
      return crop.id.contains(q) ||
          widget.strings.cropLabel(crop.id).toLowerCase().contains(q);
    }).toList();
  }

  void _toggle(CropType crop) {
    if (widget.multiSelect) {
      setState(() {
        if (_selected.contains(crop)) {
          _selected.remove(crop);
        } else {
          _selected.add(crop);
        }
      });
    } else {
      widget.onSingleSelected?.call(crop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.multiSelect)
                  TextButton(
                    onPressed: () => widget.onMultiDone?.call(_selected),
                    child: Text(widget.strings.t('crop_picker_done')),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: widget.strings.t('scan_search_crop'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: _filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        widget.strings.t('scan_no_crop_found'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      0,
                      AppSpacing.screenPadding,
                      AppSpacing.xxl,
                    ),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final crop = _filtered[index];
                      final isSelected = _selected.contains(crop);
                      return Material(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.08)
                            : AppTheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        child: InkWell(
                          onTap: () => _toggle(crop),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: crop.color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    crop.icon,
                                    color: AppTheme.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    widget.strings.cropLabel(crop.id),
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  widget.multiSelect
                                      ? (isSelected
                                          ? Icons.check_box_rounded
                                          : Icons
                                              .check_box_outline_blank_rounded)
                                      : (isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons
                                              .radio_button_off_rounded),
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
