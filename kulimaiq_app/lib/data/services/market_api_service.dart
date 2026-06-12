import '../../domain/models/crop_type.dart';
import '../../domain/models/market_listing.dart';

class MarketApiService {
  Future<List<MarketListing>> fetchListings() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now();
    return [
      MarketListing(
        id: 'm1',
        crop: CropType.maize,
        sellerName: 'Cooperative Byumba',
        location: 'Byumba Market',
        pricePerKg: 450,
        quantityKg: 120,
        postedAt: now.subtract(const Duration(hours: 5)),
        contactPhone: '+250 788 000 001',
      ),
      MarketListing(
        id: 'm2',
        crop: CropType.cassava,
        sellerName: 'Marie U.',
        location: 'Rukozo Cell',
        pricePerKg: 280,
        quantityKg: 45,
        postedAt: now.subtract(const Duration(days: 1)),
        contactPhone: '+250 788 000 002',
      ),
      MarketListing(
        id: 'm3',
        crop: CropType.banana,
        sellerName: 'Jean Paul K.',
        location: 'Gicumbi Road',
        pricePerKg: 350,
        quantityKg: 80,
        postedAt: now.subtract(const Duration(hours: 12)),
        contactPhone: '+250 788 000 003',
      ),
    ];
  }
}
