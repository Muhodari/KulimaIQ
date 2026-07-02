import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
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
      s.t('nav_farms'),
      s.t('profile_title'),
    ];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          shell.tabIndex == 0 ? s.t('app_name') : titles[shell.tabIndex],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppTheme.pageGradient,
        ),
        child: IndexedStack(
          index: shell.tabIndex,
          children: [
            HomeView(onScanTap: () => shell.setTab(1)),
            const ScanView(),
            const FarmsView(),
            const ProfileView(),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          border: const Border(top: BorderSide(color: AppTheme.border)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
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
      ),
    );
  }
}
