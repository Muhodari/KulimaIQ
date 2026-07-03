import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/view_models/auth_view_model.dart';
import '../features/auth/views/login_view.dart';
import '../features/onboarding/views/onboarding_view.dart';
import '../../data/services/backend_api_service.dart';
import 'app_shell.dart';
import 'app_shell_view_model.dart';

/// Routes between login, onboarding, and the main app.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthViewModel>();
      await context.read<BackendApiService>().ensureProductionUrl();
      await auth.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final shell = context.watch<AppShellViewModel>();

    if (!auth.initialized || !shell.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
