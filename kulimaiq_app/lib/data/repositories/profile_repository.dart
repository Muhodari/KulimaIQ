import 'package:sqflite/sqflite.dart';

import '../../domain/models/farmer_profile.dart';
import '../services/database_service.dart';

class ProfileRepository {
  ProfileRepository({required DatabaseService databaseService})
      : _databaseService = databaseService;

  final DatabaseService _databaseService;

  Future<FarmerProfile> getProfile() async {
    final db = await _databaseService.database;
    final rows = await db.query('farmer_profile', where: 'id = 1');
    if (rows.isEmpty) return FarmerProfile.defaultProfile;
    final row = rows.first;
    final cropsRaw = row['crops']! as String;
    return FarmerProfile(
      name: row['name']! as String,
      sector: row['sector']! as String,
      province: row['province']! as String,
      phone: row['phone']! as String,
      crops: cropsRaw.isEmpty ? [] : cropsRaw.split(','),
    );
  }

  Future<void> saveProfile(FarmerProfile profile) async {
    final db = await _databaseService.database;
    await db.insert(
      'farmer_profile',
      {
        'id': 1,
        'name': profile.name,
        'sector': profile.sector,
        'province': profile.province,
        'phone': profile.phone,
        'crops': profile.crops.join(','),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
