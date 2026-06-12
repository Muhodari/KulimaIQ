import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/auth_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/kulima_card.dart';
import '../../../core/widgets/language_selector.dart';
import '../view_models/auth_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().prepareLoginScreen();
    });
  }

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthViewModel vm) async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (vm.isRegisterMode) {
      await vm.register(
        phone: phone,
        password: password,
        displayName: _nameController.text.trim(),
      );
    } else {
      await vm.login(phone: phone, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final s = vm.strings;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + AppSpacing.lg,
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              bottom: AppSpacing.xxxl,
            ),
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandLogo(size: 48, light: true),
                    const LanguageSelector(
                      compact: true,
                      showHint: true,
                      onDark: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  s.t('login_tagline'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -AppSpacing.xxl),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                children: [
                  KulimaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          vm.isRegisterMode
                              ? s.t('register_title')
                              : s.t('login_title'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          vm.isRegisterMode
                              ? 'Join farmers using KulimaIQ in Byumba Sector.'
                              : 'Sign in to detect crop diseases and get local advisories.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        if (vm.isRegisterMode) ...[
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: s.t('profile_name'),
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: s.t('login_phone'),
                            hintText: s.t('login_phone_hint'),
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: s.t('login_password'),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        if (vm.error != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          ErrorBanner(message: vm.error!),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                        FilledButton(
                          onPressed: vm.loading ? null : () => _submit(vm),
                          child: vm.loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  vm.isRegisterMode
                                      ? s.t('register_button')
                                      : s.t('login_button'),
                                ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: TextButton(
                            onPressed: vm.loading
                                ? null
                                : () => vm.setRegisterMode(!vm.isRegisterMode),
                            child: Text(
                              vm.isRegisterMode
                                  ? s.t('login_switch')
                                  : s.t('register_switch'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  KulimaCard(
                    accentColor: AppTheme.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AppTheme.primary, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              s.t('login_demo_title'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DemoRow(
                          label: s.t('login_phone'),
                          value: AuthService.demoPhone,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _DemoRow(
                          label: s.t('login_password'),
                          value: AuthService.demoPassword,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoRow extends StatelessWidget {
  const _DemoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
