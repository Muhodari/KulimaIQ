import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/climate/views/climate_view.dart';
import '../features/farms/views/farms_view.dart';
import '../features/home/views/home_view.dart';
import '../features/profile/views/profile_view.dart';
import '../features/scan/views/scan_view.dart';
import 'app_shell_view_model.dart';
import 'locale_view_model.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<AppShellViewModel>();
    final locale = context.watch<LocaleViewModel>();
    final s = locale.strings;

    final titles = [
      s.t('nav_home'),
      s.t('scan_title'),
      s.t('climate_title'),
      s.t('nav_farms'),
      s.t('profile_title'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          shell.tabIndex == 0 ? s.t('app_name') : titles[shell.tabIndex],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: IndexedStack(
        index: shell.tabIndex,
        children: [
          HomeView(onScanTap: () => shell.setTab(1)),
          const ScanView(),
          const ClimateView(),
          const FarmsView(),
          const ProfileView(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: shell.tabIndex,
          onDestinationSelected: shell.setTab,
          backgroundColor: Colors.transparent,
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: s.t('nav_home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.camera_alt_outlined),
              selectedIcon: const Icon(Icons.camera_alt_rounded),
              label: s.t('nav_scan'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.cloud_outlined),
              selectedIcon: const Icon(Icons.cloud_rounded),
              label: s.t('nav_climate'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.landscape_outlined),
              selectedIcon: const Icon(Icons.landscape_rounded),
              label: s.t('nav_farms'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person_rounded),
              label: s.t('nav_profile'),
            ),
          ],
        ),
      ),
    );
  }
}
