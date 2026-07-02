import 'package:flutter/material.dart';

import '../../../domain/models/crop_type.dart';
import '../../../l10n/app_strings.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'crop_picker_sheet.dart';

/// Compact single-select crop field — opens a searchable picker sheet.
class CropSelector extends StatelessWidget {
  const CropSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.strings,
    this.allowedCrops,
    this.hint,
  });

  final CropType selected;
  final ValueChanged<CropType> onSelected;
  final AppStrings strings;
  final List<CropType>? allowedCrops;
  final String? hint;

  List<CropType> get _crops =>
      (allowedCrops != null && allowedCrops!.isNotEmpty)
          ? allowedCrops!
          : CropType.values;

  bool get _farmMode => allowedCrops != null && allowedCrops!.isNotEmpty;

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showCropPickerSheet(
      context: context,
      strings: strings,
      selected: selected,
      crops: _crops,
      title: _farmMode
          ? strings.t('scan_select_farm_crop')
          : strings.t('crop_picker_single_title'),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_farmMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.landscape_rounded, size: 16, color: AppTheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings.t('scan_farm_crops_only'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hint ?? strings.t('crop_select_one'),
              prefixIcon: Container(
                margin: const EdgeInsets.all(AppSpacing.sm),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(selected.icon, color: AppTheme.primary, size: 20),
              ),
              suffixIcon: const Icon(Icons.expand_more_rounded),
            ),
            child: Text(
              strings.cropLabel(selected.id),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
