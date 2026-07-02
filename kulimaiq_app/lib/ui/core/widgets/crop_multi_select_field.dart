import 'package:flutter/material.dart';

import '../../../domain/models/crop_type.dart';
import '../../../l10n/app_strings.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'crop_picker_sheet.dart';

/// Compact multi-select field — opens a searchable picker sheet instead of
/// showing every crop inline.
class CropMultiSelectField extends StatelessWidget {
  const CropMultiSelectField({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.strings,
    this.label,
    this.hint,
    this.crops,
  });

  final Set<CropType> selected;
  final ValueChanged<Set<CropType>> onChanged;
  final AppStrings strings;
  final String? label;
  final String? hint;
  final List<CropType>? crops;

  Future<void> _openPicker(BuildContext context) async {
    final result = await showCropMultiPickerSheet(
      context: context,
      strings: strings,
      selected: selected,
      crops: crops,
      title: label ?? strings.t('crop_picker_title'),
    );
    if (result != null) {
      onChanged(result);
    }
  }

  String _summary() {
    if (selected.isEmpty) {
      return hint ?? strings.t('crop_select_hint');
    }
    if (selected.length == 1) {
      return strings.cropLabel(selected.first.id);
    }
    return strings
        .t('crop_selected_count')
        .replaceAll('{n}', '${selected.length}');
  }

  @override
  Widget build(BuildContext context) {
    final sorted = selected.toList()
      ..sort((a, b) => strings.cropLabel(a.id).compareTo(strings.cropLabel(b.id)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              hintText: hint ?? strings.t('crop_select_hint'),
              prefixIcon: const Icon(Icons.eco_outlined),
              suffixIcon: const Icon(Icons.expand_more_rounded),
            ),
            child: Text(
              _summary(),
              style: TextStyle(
                color: selected.isEmpty
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
                fontWeight:
                    selected.isEmpty ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
        ),
        if (sorted.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: sorted.take(6).map((crop) {
              return InputChip(
                avatar: Icon(crop.icon, size: 16, color: AppTheme.primary),
                label: Text(
                  strings.cropLabel(crop.id),
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () {
                  final next = Set<CropType>.from(selected)..remove(crop);
                  onChanged(next);
                },
                backgroundColor: crop.color,
                side: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          if (sorted.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                strings
                    .t('crop_more_selected')
                    .replaceAll('{n}', '${sorted.length - 6}'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ],
    );
  }
}
