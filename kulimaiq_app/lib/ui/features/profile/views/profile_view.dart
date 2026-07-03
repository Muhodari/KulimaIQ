import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/backend_api_service.dart';
import '../../../../data/services/backend_connection_result.dart';
import '../../../../domain/models/crop_type.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crop_multi_select_field.dart';
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
              if (vm.signedInName != null) _AccountHeader(vm: vm, strings: s),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(title: s.t('section_personal')),
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
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(title: s.t('section_location')),
              KulimaCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _sectorController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: s.t('profile_sector'),
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
                        prefixIcon: const Icon(Icons.map_outlined),
                      ),
                      onChanged: vm.setProvince,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(title: s.t('profile_crops')),
              KulimaCard(
                child: CropMultiSelectField(
                  label: s.t('profile_crops'),
                  selected: vm.selectedCrops
                      .map(CropType.fromId)
                      .whereType<CropType>()
                      .toSet(),
                  strings: s,
                  onChanged: (crops) =>
                      vm.setCrops(crops.map((c) => c.id).toSet()),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(title: s.t('profile_backend_title')),
              _BackendServerCard(strings: s),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(title: s.t('section_preferences')),
              const KulimaCard(
                child: LanguageSelector(),
              ),
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

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.vm, required this.strings});
  final ProfileViewModel vm;
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              vm.signedInName!.isNotEmpty
                  ? vm.signedInName![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textOnDark,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.signedInName!,
                  style: const TextStyle(
                    color: AppTheme.textOnDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                if (vm.signedInPhone != null && vm.signedInPhone!.isNotEmpty)
                  Text(
                    vm.signedInPhone!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackendServerCard extends StatefulWidget {
  const _BackendServerCard({required this.strings});
  final dynamic strings;

  @override
  State<_BackendServerCard> createState() => _BackendServerCardState();
}

class _BackendServerCardState extends State<_BackendServerCard> {
  String _url = BackendApiService.productionUrl;
  BackendConnectionResult? _result;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndTest());
  }

  Future<void> _loadAndTest() async {
    final api = context.read<BackendApiService>();
    await api.ensureProductionUrl();
    final url = await api.getBaseUrl();
    if (mounted) setState(() => _url = url);
    await _test();
  }

  Future<void> _test() async {
    setState(() {
      _checking = true;
      _result = null;
    });
    final result = await context.read<BackendApiService>().checkConnection();
    if (mounted) {
      setState(() {
        _result = result;
        _checking = false;
      });
    }
  }

  String _statusText() {
    final s = widget.strings;
    if (_checking) return s.t('profile_backend_checking');
    if (_result == null) return s.t('profile_backend_not_tested');
    if (_result!.ok) return s.t('profile_backend_ready');
    if (_result!.reachable) return s.t('profile_backend_no_model');
    return s.t('profile_backend_unreachable');
  }

  Color _statusColor() {
    if (_checking) return AppTheme.textSecondary;
    if (_result?.ok == true) return AppTheme.primary;
    if (_result?.reachable == true) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return KulimaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _url,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                _checking
                    ? Icons.hourglass_top_rounded
                    : (_result?.ok == true
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded),
                size: 18,
                color: _statusColor(),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _statusText(),
                  style: TextStyle(
                    color: _statusColor(),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _checking ? null : _test,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(s.t('profile_backend_test')),
          ),
        ],
      ),
    );
  }
}
