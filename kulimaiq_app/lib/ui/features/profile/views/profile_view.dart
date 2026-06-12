import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/backend_api_service.dart';
import '../../../../domain/models/crop_type.dart';
import '../../../../l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/kulima_card.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/section_header.dart';
import '../view_models/profile_view_model.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sectorController = TextEditingController();
  final _provinceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _sectorController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final s = vm.strings;

    if (!vm.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_nameController.text != vm.name) _nameController.text = vm.name;
    if (_phoneController.text != vm.phone) _phoneController.text = vm.phone;
    if (_sectorController.text != vm.sector) _sectorController.text = vm.sector;
    if (_provinceController.text != vm.province) {
      _provinceController.text = vm.province;
    }

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (vm.signedInName != null)
                KulimaCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                        child: Text(
                          vm.signedInName!.isNotEmpty
                              ? vm.signedInName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.t('profile_signed_in'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              vm.signedInName!,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              vm.signedInPhone ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(title: s.t('profile_title')),
              KulimaCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: s.t('profile_name'),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      onChanged: vm.setName,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: s.t('profile_phone'),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: vm.setPhone,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _sectorController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: s.t('profile_sector'),
                        hintText: s.t('profile_sector_hint'),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      onChanged: vm.setSector,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _provinceController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: s.t('profile_province'),
                        hintText: s.t('profile_province_hint'),
                        prefixIcon:
                            const Icon(Icons.map_outlined),
                      ),
                      onChanged: vm.setProvince,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                s.t('profile_crops'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: CropType.values.map((crop) {
                  final id = crop.id;
                  final selected = vm.selectedCrops.contains(id);
                  return FilterChip(
                    label: Text(s.cropLabel(id)),
                    selected: selected,
                    onSelected: (_) => vm.toggleCrop(id),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              KulimaCard(
                child: const LanguageSelector(showHint: true),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _BackendSettingsCard(s: s),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: vm.saving ? null : vm.save,
                child: vm.saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.t('profile_save')),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: vm.logout,
                icon: const Icon(Icons.logout_rounded),
                label: Text(s.t('profile_logout')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Backend settings card ─────────────────────────────────────────────────────

enum _BackendStatus { unknown, checking, ready, noModel, unreachable }

class _BackendSettingsCard extends StatefulWidget {
  const _BackendSettingsCard({required this.s});
  final AppStrings s;

  @override
  State<_BackendSettingsCard> createState() => _BackendSettingsCardState();
}

class _BackendSettingsCardState extends State<_BackendSettingsCard> {
  late final TextEditingController _urlCtrl;
  _BackendStatus _status = _BackendStatus.unknown;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
    _loadUrl();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUrl() async {
    final svc = context.read<BackendApiService>();
    final url = await svc.getBaseUrl();
    if (mounted) setState(() => _urlCtrl.text = url);
  }

  Future<void> _testConnection() async {
    setState(() => _status = _BackendStatus.checking);
    final svc = context.read<BackendApiService>();
    final ready = await svc.isBackendReady();
    if (!mounted) return;
    setState(() {
      _status = ready ? _BackendStatus.ready : _BackendStatus.unreachable;
    });
  }

  Future<void> _saveUrl() async {
    final svc = context.read<BackendApiService>();
    await svc.setBaseUrl(_urlCtrl.text.trim());
    if (mounted) setState(() => _editing = false);
    await _testConnection();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return KulimaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_outlined, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                s.t('profile_backend_title'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              _StatusDot(status: _status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_editing) ...[
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'http://192.168.1.x:8000',
                prefixIcon: Icon(Icons.link_rounded),
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _editing = false),
                    child: Text(s.t('farm_cancel')),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveUrl,
                    child: const Text('Save & test'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              _urlCtrl.text,
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace'),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: Text(s.t('profile_backend_edit')),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _status == _BackendStatus.checking
                        ? null
                        : _testConnection,
                    icon: _status == _BackendStatus.checking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering_rounded, size: 15),
                    label: Text(s.t('profile_backend_test')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _statusLabel(_status, s),
              style: TextStyle(
                  fontSize: 11,
                  color: _statusColor(_status)),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(_BackendStatus st, AppStrings s) {
    switch (st) {
      case _BackendStatus.unknown:
        return s.t('profile_backend_not_tested');
      case _BackendStatus.checking:
        return s.t('profile_backend_checking');
      case _BackendStatus.ready:
        return s.t('profile_backend_ready');
      case _BackendStatus.noModel:
        return s.t('profile_backend_no_model');
      case _BackendStatus.unreachable:
        return s.t('profile_backend_unreachable');
    }
  }

  Color _statusColor(_BackendStatus st) {
    switch (st) {
      case _BackendStatus.ready:
        return AppTheme.success;
      case _BackendStatus.unreachable:
        return AppTheme.error;
      case _BackendStatus.noModel:
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final _BackendStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case _BackendStatus.ready:
        color = AppTheme.success;
      case _BackendStatus.unreachable:
        color = AppTheme.error;
      case _BackendStatus.noModel:
        color = AppTheme.warning;
      case _BackendStatus.checking:
        color = Colors.orange;
      case _BackendStatus.unknown:
        color = AppTheme.border;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
