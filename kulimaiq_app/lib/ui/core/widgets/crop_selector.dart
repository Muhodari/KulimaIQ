import 'package:flutter/material.dart';

import '../../../domain/models/crop_type.dart';
import '../../../l10n/app_strings.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Searchable, scrollable grid for selecting a crop type.
///
/// With 26+ crops a simple horizontal row no longer works.
/// This widget shows a search field and a 3-column grid.
class CropSelector extends StatefulWidget {
  const CropSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.strings,
  });

  final CropType selected;
  final ValueChanged<CropType> onSelected;
  final AppStrings strings;

  @override
  State<CropSelector> createState() => _CropSelectorState();
}

class _CropSelectorState extends State<CropSelector> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _expanded = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CropType> get _filtered {
    if (_query.isEmpty) return CropType.values;
    final q = _query.toLowerCase();
    return CropType.values.where((c) {
      return c.id.contains(q) ||
          widget.strings.cropLabel(c.id).toLowerCase().contains(q);
    }).toList();
  }

  // Show selected crop as the compact "chip", expand grid on tap.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Selected crop chip + expand toggle ─────────────────────────────
        _SelectedCropChip(
          crop: widget.selected,
          label: widget.strings.cropLabel(widget.selected.id),
          expanded: _expanded,
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        // ── Expanded picker ─────────────────────────────────────────────────
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.sm),
          // Search bar
          TextField(
            controller: _searchCtrl,
            autofocus: true,
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
              contentPadding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Grid (constrained height, scrollable)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: _CropGrid(
              crops: _filtered,
              selected: widget.selected,
              strings: widget.strings,
              onTap: (crop) {
                widget.onSelected(crop);
                setState(() {
                  _expanded = false;
                  _query = '';
                  _searchCtrl.clear();
                });
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SelectedCropChip extends StatelessWidget {
  const _SelectedCropChip({
    required this.crop,
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final CropType crop;
  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: crop.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppTheme.primary, width: 2),
        ),
        child: Row(
          children: [
            Icon(crop.icon, color: AppTheme.primary, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CropGrid extends StatelessWidget {
  const _CropGrid({
    required this.crops,
    required this.selected,
    required this.strings,
    required this.onTap,
  });

  final List<CropType> crops;
  final CropType selected;
  final AppStrings strings;
  final ValueChanged<CropType> onTap;

  @override
  Widget build(BuildContext context) {
    if (crops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            strings.t('scan_no_crop_found'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      itemCount: crops.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, i) {
        final crop = crops[i];
        final isSelected = crop == selected;
        return _CropTile(
          label: strings.cropLabel(crop.id),
          icon: crop.icon,
          bgColor: crop.color,
          selected: isSelected,
          onTap: () => onTap(crop),
        );
      },
    );
  }
}

class _CropTile extends StatelessWidget {
  const _CropTile({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color bgColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withValues(alpha: 0.12) : bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
