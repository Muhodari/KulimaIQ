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

  /// Colour used in the crop picker tile background.
  Color get color {
    switch (this) {
      case CropType.cassava:      return const Color(0xFFE8F5E9);
      case CropType.maize:        return const Color(0xFFFFF8E1);
      case CropType.banana:       return const Color(0xFFFFF9C4);
      case CropType.bean:         return const Color(0xFFE8F5E9);
      case CropType.sweetPotato:  return const Color(0xFFFCE4EC);
      case CropType.sorghum:      return const Color(0xFFFFF3E0);
      case CropType.groundnut:    return const Color(0xFFF3E5F5);
      case CropType.cowpea:       return const Color(0xFFE8F5E9);
      case CropType.pigeonPea:    return const Color(0xFFF1F8E9);
      case CropType.yam:          return const Color(0xFFFFF3E0);
      case CropType.taro:         return const Color(0xFFE8F5E9);
      case CropType.tomato:       return const Color(0xFFFFEBEE);
      case CropType.potato:       return const Color(0xFFF5F5F5);
      case CropType.onion:        return const Color(0xFFE8EAF6);
      case CropType.pepper:       return const Color(0xFFFFEBEE);
      case CropType.eggplant:     return const Color(0xFFEDE7F6);
      case CropType.cabbage:      return const Color(0xFFE8F5E9);
      case CropType.spinach:      return const Color(0xFFE8F5E9);
      case CropType.carrot:       return const Color(0xFFFFF3E0);
      case CropType.cucumber:     return const Color(0xFFF1F8E9);
      case CropType.watermelon:   return const Color(0xFFFFEBEE);
      case CropType.pumpkin:      return const Color(0xFFFFF3E0);
      case CropType.garlic:       return const Color(0xFFF5F5F5);
      case CropType.coffee:       return const Color(0xFFEFEBE9);
      case CropType.tea:          return const Color(0xFFE8F5E9);
      case CropType.cocoa:        return const Color(0xFFEFEBE9);
      case CropType.sugarcane:    return const Color(0xFFF1F8E9);
      case CropType.rice:         return const Color(0xFFF1F8E9);
      case CropType.wheat:        return const Color(0xFFFFFDE7);
      case CropType.soybean:      return const Color(0xFFE8F5E9);
      case CropType.sunflower:    return const Color(0xFFFFF9C4);
      case CropType.sesame:       return const Color(0xFFFFF8E1);
      case CropType.cotton:       return const Color(0xFFF5F5F5);
      case CropType.mango:        return const Color(0xFFFFF9C4);
      case CropType.avocado:      return const Color(0xFFDCEDC8);
      case CropType.pineapple:    return const Color(0xFFFFF9C4);
      case CropType.passionFruit: return const Color(0xFFEDE7F6);
      case CropType.papaya:       return const Color(0xFFFFF3E0);
      case CropType.orange:       return const Color(0xFFFFF3E0);
      case CropType.lemon:        return const Color(0xFFFFFDE7);
      case CropType.apple:        return const Color(0xFFFFEBEE);
      case CropType.grape:        return const Color(0xFFEDE7F6);
      case CropType.peach:        return const Color(0xFFFCE4EC);
      case CropType.cherry:       return const Color(0xFFFFEBEE);
      case CropType.strawberry:   return const Color(0xFFFFEBEE);
      case CropType.blueberry:    return const Color(0xFFE3F2FD);
      case CropType.raspberry:    return const Color(0xFFFCE4EC);
      case CropType.macadamia:    return const Color(0xFFF5F5F5);
      case CropType.squash:       return const Color(0xFFFFF3E0);
      case CropType.lentil:       return const Color(0xFFF3E5F5);
      case CropType.chickpea:     return const Color(0xFFFFF8E1);
    }
  }
}
