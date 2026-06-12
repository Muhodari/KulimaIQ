import 'crop_type.dart';

class MarketListing {
  const MarketListing({
    required this.id,
    required this.crop,
    required this.sellerName,
    required this.location,
    required this.pricePerKg,
    required this.quantityKg,
    required this.postedAt,
    required this.contactPhone,
  });

  final String id;
  final CropType crop;
  final String sellerName;
  final String location;
  final int pricePerKg;
  final double quantityKg;
  final DateTime postedAt;
  final String contactPhone;
}
