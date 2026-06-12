import '../../domain/models/market_listing.dart';
import '../services/market_api_service.dart';

class MarketRepository {
  MarketRepository({required MarketApiService marketApiService})
      : _marketApiService = marketApiService;

  final MarketApiService _marketApiService;

  List<MarketListing>? _cache;

  Future<List<MarketListing>> getListings() async {
    _cache ??= await _marketApiService.fetchListings();
    return _cache!;
  }
}
