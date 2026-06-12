import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/climate_repository.dart';
import '../data/repositories/diagnosis_repository.dart';
import '../data/repositories/farm_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/climate_api_service.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/database_service.dart';
import '../data/services/disease_inference_service.dart';
import '../data/services/backend_api_service.dart';
import '../data/services/farm_service.dart';
import '../data/services/farm_weather_service.dart';
import '../data/services/image_capture_service.dart';
import '../data/services/preferences_service.dart';
import '../l10n/app_strings.dart';
import '../ui/features/auth/view_models/auth_view_model.dart';
import '../ui/features/climate/view_models/climate_view_model.dart';
import '../ui/features/farms/view_models/farm_view_model.dart';
import '../ui/features/home/view_models/home_view_model.dart';
import '../ui/features/profile/view_models/profile_view_model.dart';
import '../ui/features/scan/view_models/scan_view_model.dart';
import '../ui/shell/app_shell_view_model.dart';
import '../ui/shell/locale_view_model.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => DatabaseService()),
        Provider(create: (_) => BackendApiService()),
        ProxyProvider<BackendApiService, DiseaseInferenceService>(
          update: (_, backend, __) =>
              DiseaseInferenceService(backendApiService: backend),
        ),
        Provider(create: (_) => ClimateApiService()),
        Provider(create: (_) => ConnectivityService()),
        Provider(create: (_) => PreferencesService()),
        Provider(create: (_) => ImageCaptureService()),
        ProxyProvider3<DatabaseService, PreferencesService, BackendApiService,
            AuthService>(
          update: (_, db, prefs, backend, __) => AuthService(
            databaseService: db,
            preferencesService: prefs,
            backendApiService: backend,
          ),
        ),
        ProxyProvider<AuthService, AuthRepository>(
          update: (_, auth, __) => AuthRepository(authService: auth),
        ),
        ProxyProvider4<DatabaseService, DiseaseInferenceService,
            ConnectivityService, BackendApiService, DiagnosisRepository>(
          update: (_, db, inference, connectivity, backend, __) =>
              DiagnosisRepository(
            databaseService: db,
            inferenceService: inference,
            connectivityService: connectivity,
            backendApiService: backend,
          ),
        ),
        ProxyProvider2<ClimateApiService, ConnectivityService,
            ClimateRepository>(
          update: (_, api, connectivity, __) => ClimateRepository(
            climateApiService: api,
            connectivityService: connectivity,
          ),
        ),
        ProxyProvider<DatabaseService, ProfileRepository>(
          update: (_, db, __) => ProfileRepository(databaseService: db),
        ),
        Provider(create: (_) => FarmWeatherService()),
        ProxyProvider2<DatabaseService, BackendApiService, FarmService>(
          update: (_, db, backend, __) => FarmService(
            databaseService: db,
            backendApiService: backend,
          ),
        ),
        ProxyProvider<FarmService, FarmRepository>(
          update: (_, svc, __) => FarmRepository(farmService: svc),
        ),
        ChangeNotifierProvider(
          create: (ctx) => LocaleViewModel(
            preferencesService: ctx.read<PreferencesService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AppShellViewModel(
            preferencesService: ctx.read<PreferencesService>(),
          ),
        ),
        ChangeNotifierProxyProvider2<AuthRepository, LocaleViewModel,
            AuthViewModel>(
          create: (ctx) => AuthViewModel(
            authRepository: ctx.read<AuthRepository>(),
            strings: AppStrings(ctx.read<LocaleViewModel>().locale),
          ),
          update: (_, repo, locale, vm) =>
              vm!..refreshStrings(AppStrings(locale.locale)),
        ),
        ChangeNotifierProxyProvider2<DiagnosisRepository, LocaleViewModel,
            HomeViewModel>(
          create: (ctx) => HomeViewModel(
            diagnosisRepository: ctx.read<DiagnosisRepository>(),
            strings: AppStrings(ctx.read<LocaleViewModel>().locale),
          ),
          update: (_, repo, locale, vm) =>
              vm!..refreshStrings(AppStrings(locale.locale)),
        ),
        ChangeNotifierProxyProvider3<DiagnosisRepository, ImageCaptureService,
            LocaleViewModel, ScanViewModel>(
          create: (ctx) => ScanViewModel(
            diagnosisRepository: ctx.read<DiagnosisRepository>(),
            imageCaptureService: ctx.read<ImageCaptureService>(),
            strings: AppStrings(ctx.read<LocaleViewModel>().locale),
          ),
          update: (_, repo, capture, locale, vm) =>
              vm!..refreshStrings(AppStrings(locale.locale)),
        ),
        ChangeNotifierProxyProvider3<ClimateRepository, FarmRepository,
            LocaleViewModel, ClimateViewModel>(
          create: (ctx) => ClimateViewModel(
            climateRepository: ctx.read<ClimateRepository>(),
            farmRepository: ctx.read<FarmRepository>(),
            strings: AppStrings(ctx.read<LocaleViewModel>().locale),
          ),
          update: (_, climateRepo, farmRepo, locale, vm) =>
              vm!..refreshStrings(AppStrings(locale.locale)),
        ),
        ChangeNotifierProxyProvider3<FarmRepository, FarmWeatherService,
            LocaleViewModel, FarmViewModel>(
          create: (ctx) => FarmViewModel(
            farmRepository: ctx.read<FarmRepository>(),
            farmWeatherService: ctx.read<FarmWeatherService>(),
            strings: AppStrings(ctx.read<LocaleViewModel>().locale),
          ),
          update: (_, repo, weather, locale, vm) =>
              vm!..refreshStrings(AppStrings(locale.locale)),
        ),
        ChangeNotifierProxyProvider3<ProfileRepository, LocaleViewModel,
            AuthViewModel, ProfileViewModel>(
          create: (ctx) => ProfileViewModel(
            profileRepository: ctx.read<ProfileRepository>(),
            authViewModel: ctx.read<AuthViewModel>(),
            localeViewModel: ctx.read<LocaleViewModel>(),
            strings: AppStrings(ctx.read<LocaleViewModel>().locale),
          ),
          update: (_, profileRepo, locale, auth, vm) =>
              vm!..refreshStrings(AppStrings(locale.locale)),
        ),
      ],
      child: child,
    );
  }
}
