import 'package:flutter/material.dart';

import 'di/app_providers.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/shell/app_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KulimaIQApp());
}

class KulimaIQApp extends StatelessWidget {
  const KulimaIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: 'KulimaIQ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppGate(),
      ),
    );
  }
}
