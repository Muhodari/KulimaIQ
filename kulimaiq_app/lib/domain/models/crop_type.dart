import 'package:flutter/material.dart';

/// All crop types the app can scan.
///
/// The [id] maps to the folder-name convention used on the backend
/// (lower_snake_case), and is sent as the `crop` parameter in API calls.
enum CropType {
  // ── Staples / Subsistence (Africa-priority) ───────────────────────────
  cassava,
  maize,
  banana,
  bean,
  sweetPotato,
  sorghum,
  groundnut,
  cowpea,
  pigeonPea,
  yam,
  taro,
  // (banana varieties are tracked under the single 'banana' crop)
  // ── High-value vegetables & field crops ──────────────────────────────
  tomato,
  potato,
  onion,
  pepper,
  eggplant,
  cabbage,
  spinach,
  carrot,
  cucumber,
  watermelon,
  pumpkin,
  garlic,
  // ── Cash / Export crops ────────────────────────────────────────────────
  coffee,
  tea,
  cocoa,
  sugarcane,
  rice,
  wheat,
  soybean,
  sunflower,
  sesame,
  cotton,
  // ── Fruit trees ────────────────────────────────────────────────────────
  mango,
  avocado,
  pineapple,
  passionFruit,
  papaya,
  orange,
  lemon,
  apple,
  grape,
  peach,
  cherry,
  strawberry,
  blueberry,
  raspberry,
  macadamia,
  // ── Other ──────────────────────────────────────────────────────────────
  squash,
  lentil,
  chickpea;

  /// Backend slug — matches the class folder naming convention.
  String get id {
    switch (this) {
      case CropType.sweetPotato:   return 'sweet_potato';
      case CropType.pigeonPea:     return 'pigeon_pea';
      case CropType.passionFruit:  return 'passion_fruit';
      default:
        return name.toLowerCase();
    }
  }

  static CropType? fromId(String? id) {
    if (id == null) return null;
    for (final crop in CropType.values) {
      if (crop.id == id) return crop;
    }
    return null;
  }

  /// Icon shown in the crop picker grid.
  IconData get icon {
    switch (this) {
      case CropType.cassava:      return Icons.grass;
      case CropType.maize:        return Icons.agriculture;
      case CropType.banana:       return Icons.spa;
      case CropType.bean:         return Icons.eco;
      case CropType.sweetPotato:  return Icons.nature;
      case CropType.sorghum:      return Icons.grain;
      case CropType.groundnut:    return Icons.circle_outlined;
      case CropType.cowpea:       return Icons.eco;
      case CropType.pigeonPea:    return Icons.eco;
      case CropType.yam:          return Icons.nature;
      case CropType.taro:         return Icons.nature;
      case CropType.tomato:       return Icons.local_florist;
      case CropType.potato:       return Icons.circle;
      case CropType.onion:        return Icons.bubble_chart;
      case CropType.pepper:       return Icons.whatshot;
      case CropType.eggplant:     return Icons.egg_outlined;
      case CropType.cabbage:      return Icons.local_florist;
      case CropType.spinach:      return Icons.grass;
      case CropType.carrot:       return Icons.arrow_downward;
      case CropType.cucumber:     return Icons.view_in_ar;
      case CropType.watermelon:   return Icons.circle;
      case CropType.pumpkin:      return Icons.circle;
      case CropType.garlic:       return Icons.bubble_chart;
      case CropType.coffee:       return Icons.coffee;
      case CropType.tea:          return Icons.emoji_food_beverage;
      case CropType.cocoa:        return Icons.coffee_maker;
      case CropType.sugarcane:    return Icons.grass;
      case CropType.rice:         return Icons.rice_bowl;
      case CropType.wheat:        return Icons.grain;
      case CropType.soybean:      return Icons.eco;
      case CropType.sunflower:    return Icons.wb_sunny;
      case CropType.sesame:       return Icons.grain;
      case CropType.cotton:       return Icons.cloud;
      case CropType.mango:        return Icons.park;
      case CropType.avocado:      return Icons.park;
      case CropType.pineapple:    return Icons.filter_vintage;
      case CropType.passionFruit: return Icons.filter_vintage;
      case CropType.papaya:       return Icons.park;
      case CropType.orange:       return Icons.brightness_high;
      case CropType.lemon:        return Icons.brightness_high;
      case CropType.apple:        return Icons.apple;
      case CropType.grape:        return Icons.wine_bar;
      case CropType.peach:        return Icons.circle_outlined;
      case CropType.cherry:       return Icons.favorite;
      case CropType.strawberry:   return Icons.favorite_border;
      case CropType.blueberry:    return Icons.circle;
      case CropType.raspberry:    return Icons.circle;
      case CropType.macadamia:    return Icons.circle_outlined;
      case CropType.squash:       return Icons.circle_outlined;
      case CropType.lentil:       return Icons.eco;
      case CropType.chickpea:     return Icons.eco;
    }
  }

  /// Uniform soft green tint for crop chips and tiles (matches app brand).
  static const Color _chipTint = Color(0xFFE8F3EB);
  Color get color => _chipTint;
}
