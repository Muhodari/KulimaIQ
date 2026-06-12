import 'package:flutter/foundation.dart';

import '../../../../data/repositories/market_repository.dart';
import '../../../../domain/models/market_listing.dart';
import '../../../../l10n/app_strings.dart';

class MarketViewModel extends ChangeNotifier {
  MarketViewModel({
    required MarketRepository marketRepository,
    required AppStrings strings,
  })  : _marketRepository = marketRepository,
        _strings = strings;

  final MarketRepository _marketRepository;
  AppStrings _strings;

  AppStrings get strings => _strings;

  List<MarketListing> _listings = [];
  bool _loading = true;
  String? _error;

  List<MarketListing> get listings => _listings;
  bool get loading => _loading;
  String? get error => _error;

  void refreshStrings(AppStrings strings) {
    _strings = strings;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _listings = await _marketRepository.getListings();
    } catch (_) {
      _error = _strings.t('error_generic');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
