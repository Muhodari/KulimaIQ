class FarmerProfile {
  const FarmerProfile({
    required this.name,
    required this.sector,
    required this.province,
    required this.phone,
    required this.crops,
  });

  final String name;
  final String sector;
  final String province;
  final String phone;
  final List<String> crops;

  static const FarmerProfile defaultProfile = FarmerProfile(
    name: '',
    sector: '',
    province: '',
    phone: '',
    crops: [],
  );
}
