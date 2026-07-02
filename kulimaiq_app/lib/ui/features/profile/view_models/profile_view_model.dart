import 'package:flutter/foundation.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../domain/models/farmer_profile.dart';
import '../../../../l10n/app_strings.dart';
import '../../../features/auth/view_models/auth_view_model.dart';
import '../../../shell/locale_view_model.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required ProfileRepository profileRepository,
    required AuthViewModel authViewModel,
    required LocaleViewModel localeViewModel,
    required AppStrings strings,
  })  : _profileRepository = profileRepository,
        _authViewModel = authViewModel,
        _localeViewModel = localeViewModel,
        _strings = strings {
    _load();
  }

  final ProfileRepository _profileRepository;
  final AuthViewModel _authViewModel;
  final LocaleViewModel _localeViewModel;
  AppStrings _strings;

  AppStrings get strings => _strings;
  String get locale => _localeViewModel.locale;
  String? get signedInName => _authViewModel.user?.displayName;
  String? get signedInPhone => _authViewModel.user?.phone;

  String _name = '';
  String _phone = '';
  String _sector = '';
  String _province = '';
  final Set<String> _selectedCrops = {};
  bool _saving = false;
  bool _loaded = false;

  String get name => _name;
  String get phone => _phone;
  String get sector => _sector;
  String get province => _province;
  Set<String> get selectedCrops => _selectedCrops;
  bool get saving => _saving;
  bool get loaded => _loaded;

  void refreshStrings(AppStrings strings) {
    _strings = strings;
    notifyListeners();
  }

  Future<void> _load() async {
    final profile = await _profileRepository.getProfile();
    _name = profile.name.isNotEmpty
        ? profile.name
        : (_authViewModel.user?.displayName ?? '');
    _phone = profile.phone.isNotEmpty
        ? profile.phone
        : (_authViewModel.user?.phone ?? '');
    _sector = profile.sector;
    _province = profile.province;
    _selectedCrops
      ..clear()
      ..addAll(profile.crops);
    _loaded = true;
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setPhone(String value) {
    _phone = value;
    notifyListeners();
  }

  void setSector(String value) {
    _sector = value;
    notifyListeners();
  }

  void setProvince(String value) {
    _province = value;
    notifyListeners();
  }

  void toggleCrop(String cropId) {
    if (_selectedCrops.contains(cropId)) {
      _selectedCrops.remove(cropId);
    } else {
      _selectedCrops.add(cropId);
    }
    notifyListeners();
  }

  void setCrops(Set<String> cropIds) {
    _selectedCrops
      ..clear()
      ..addAll(cropIds);
    notifyListeners();
  }

  Future<void> save() async {
    _saving = true;
    notifyListeners();
    await _profileRepository.saveProfile(
      FarmerProfile(
        name: _name,
        sector: _sector,
        province: _province,
        phone: _phone,
        crops: _selectedCrops.toList(),
      ),
    );
    _saving = false;
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    await _localeViewModel.setLocale(code);
    refreshStrings(AppStrings(code));
  }

  Future<void> logout() => _authViewModel.logout();
}
