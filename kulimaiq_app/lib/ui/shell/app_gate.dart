import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/backend_api_service.dart';
import '../../l10n/app_strings.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/auth/views/login_view.dart';
import '../features/onboarding/views/onboarding_view.dart';
import 'app_shell.dart';
import 'app_shell_view_model.dart';
import 'locale_view_model.dart';

/// Routes between login, onboarding, and the main app.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with WidgetsBindingObserver {
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_bootstrapping) {
      // Re-wake Render if the user returns after the service went idle.
      context.read<BackendApiService>().warmUpBackend(background: true);
    }
  }

  Future<void> _bootstrap() async {
    final backend = context.read<BackendApiService>();
    final auth = context.read<AuthViewModel>();
    await backend.warmUpBackend();
    await auth.initialize();
    if (mounted) {
      setState(() => _bootstrapping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final shell = context.watch<AppShellViewModel>();
    final locale = context.watch<LocaleViewModel>();
    final strings = AppStrings(locale.locale);

    if (_bootstrapping || !auth.initialized || !shell.initialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                strings.t('app_warming_backend'),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginView();
    }

    if (shell.showOnboarding) {
      return const OnboardingView();
    }

    return const AppShell();
  }
}
