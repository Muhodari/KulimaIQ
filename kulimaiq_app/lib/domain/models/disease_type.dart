/// Known disease labels returned by the backend.
///
/// The [id] exactly matches the folder-name convention used during training
/// (i.e. the value of `top_label` from the ML inference service).
///
/// Unknown labels (diseases added to the model after an app release) still
/// work — use [DiseaseType.fromId] which returns null for unknowns and the
/// caller falls back to displaying the raw label.
enum DiseaseType {
  // ── Shared ───────────────────────────────────────────────────────────────
  healthy,

  // ── Cassava ───────────────────────────────────────────────────────────────
  cassavaMosaic,
  cassavaBrownStreak,
  cassavaBacterialBlight,

  // ── Maize ─────────────────────────────────────────────────────────────────
  maizeNecrosis,
  maizeCommonRust,
  maizeGrayLeafSpot,
  maizeNorthernLeafBlight,
  maizeStreakVirus,

  // ── Banana ────────────────────────────────────────────────────────────────
  bananaWilt,
  bananaFusariumWilt,
  bananaSigatoka,

  // ── Tomato ────────────────────────────────────────────────────────────────
  tomatoLateBlight,
  tomatoEarlyBlight,
  tomatoBacterialSpot,
  tomatoLeafMold,
  tomatoSeptoriaLeafSpot,
  tomatoSpiderMites,
  tomatoTargetSpot,
  tomatoYellowLeafCurlVirus,
  tomatoMosaicVirus,

  // ── Potato ────────────────────────────────────────────────────────────────
  potatoLateBlight,
  potatoEarlyBlight,

  // ── Bean ──────────────────────────────────────────────────────────────────
  beanAngularSpot,
  beanRust,
  beanCommonMosaic,

  // ── Coffee ────────────────────────────────────────────────────────────────
  coffeeLeafRust,
  coffeeBerryDisease,
  coffeeWilt,

  // ── Rice ──────────────────────────────────────────────────────────────────
  riceBlast,
  riceBrownSpot,
  riceBacterialBlight,

  // ── Other crops ───────────────────────────────────────────────────────────
  sweetPotatoVirus,
  sorghumLeafBlight,
  sorghumDownyMildew,
  wheatRust,
  wheatSeptoria,
  groundnutLeafSpot,
  groundnutRosette,
  soybeanRust,
  onionPurpleBlotch,
  cabbageBlackRot,
  appleScab,
  appleBlackRot,
  appleCedarRust,
  grapeBlackRot,
  grapeEsca,
  grapeLeafBlight,
  pepperBacterialSpot,
  citrusGreening,
  mangoAnthracnose,
  mangoPowderyMildew,

  // ── Avocado ───────────────────────────────────────────────────────────────
  avocadoRootRot,
  avocadoAnthracnose,
  avocadoDieback,

  // ── Tea ───────────────────────────────────────────────────────────────────
  teaBlisterBlight,
  teaGreyBlight,
  teaRootRot,

  // ── Cowpea ────────────────────────────────────────────────────────────────
  cowpeaMosaic,
  cowpeaBrownBlotch,

  // ── Pigeon pea ────────────────────────────────────────────────────────────
  pigeonPeaWilt,
  pigeonPeaSterility,

  // ── Eggplant ──────────────────────────────────────────────────────────────
  eggplantLeafSpot,
  eggplantBacterialWilt,

  // ── Watermelon ────────────────────────────────────────────────────────────
  watermelonAnthracnose,
  watermelonGummyStemBlight,

  // ── Sugarcane ─────────────────────────────────────────────────────────────
  sugarcaneSmut,
  sugarcaneRedRot,

  // ── Cocoa ─────────────────────────────────────────────────────────────────
  cocoaBlackPod,
  cocoaSwollenShoot,

  // ── Papaya ────────────────────────────────────────────────────────────────
  papayaRingspot,
  papayaAnthracnose,

  // ── Citrus (lemon) ────────────────────────────────────────────────────────
  citrusCanker,
  citrusMelanoase;

  /// The exact label used in training folder names and returned by the API.
  String get id {
    switch (this) {
      case DiseaseType.healthy:              return 'healthy';
      case DiseaseType.cassavaMosaic:        return 'cassava_mosaic';
      case DiseaseType.cassavaBrownStreak:   return 'cassava_brown_streak';
      case DiseaseType.cassavaBacterialBlight: return 'cassava_bacterial_blight';
      case DiseaseType.maizeNecrosis:        return 'maize_necrosis';
      case DiseaseType.maizeCommonRust:      return 'maize_common_rust';
      case DiseaseType.maizeGrayLeafSpot:    return 'maize_gray_leaf_spot';
      case DiseaseType.maizeNorthernLeafBlight: return 'maize_northern_leaf_blight';
      case DiseaseType.maizeStreakVirus:     return 'maize_streak_virus';
      case DiseaseType.bananaWilt:           return 'banana_wilt';
      case DiseaseType.bananaFusariumWilt:   return 'banana_fusarium_wilt';
      case DiseaseType.bananaSigatoka:       return 'banana_sigatoka';
      case DiseaseType.tomatoLateBlight:     return 'tomato_late_blight';
      case DiseaseType.tomatoEarlyBlight:    return 'tomato_early_blight';
      case DiseaseType.tomatoBacterialSpot:  return 'tomato_bacterial_spot';
      case DiseaseType.tomatoLeafMold:       return 'tomato_leaf_mold';
      case DiseaseType.tomatoSeptoriaLeafSpot: return 'tomato_septoria_leaf_spot';
      case DiseaseType.tomatoSpiderMites:    return 'tomato_spider_mites';
      case DiseaseType.tomatoTargetSpot:     return 'tomato_target_spot';
      case DiseaseType.tomatoYellowLeafCurlVirus: return 'tomato_yellow_leaf_curl_virus';
      case DiseaseType.tomatoMosaicVirus:    return 'tomato_mosaic_virus';
      case DiseaseType.potatoLateBlight:     return 'potato_late_blight';
      case DiseaseType.potatoEarlyBlight:    return 'potato_early_blight';
      case DiseaseType.beanAngularSpot:      return 'bean_angular_spot';
      case DiseaseType.beanRust:             return 'bean_rust';
      case DiseaseType.beanCommonMosaic:     return 'bean_common_mosaic';
      case DiseaseType.coffeeLeafRust:       return 'coffee_leaf_rust';
      case DiseaseType.coffeeBerryDisease:   return 'coffee_berry_disease';
      case DiseaseType.coffeeWilt:           return 'coffee_wilt';
      case DiseaseType.riceBlast:            return 'rice_blast';
      case DiseaseType.riceBrownSpot:        return 'rice_brown_spot';
      case DiseaseType.riceBacterialBlight:  return 'rice_bacterial_blight';
      case DiseaseType.sweetPotatoVirus:     return 'sweet_potato_virus';
      case DiseaseType.sorghumLeafBlight:    return 'sorghum_leaf_blight';
      case DiseaseType.sorghumDownyMildew:   return 'sorghum_downy_mildew';
      case DiseaseType.wheatRust:            return 'wheat_rust';
      case DiseaseType.wheatSeptoria:        return 'wheat_septoria';
      case DiseaseType.groundnutLeafSpot:    return 'groundnut_leaf_spot';
      case DiseaseType.groundnutRosette:     return 'groundnut_rosette';
      case DiseaseType.soybeanRust:          return 'soybean_rust';
      case DiseaseType.onionPurpleBlotch:    return 'onion_purple_blotch';
      case DiseaseType.cabbageBlackRot:      return 'cabbage_black_rot';
      case DiseaseType.appleScab:            return 'apple_scab';
      case DiseaseType.appleBlackRot:        return 'apple_black_rot';
      case DiseaseType.appleCedarRust:       return 'apple_cedar_rust';
      case DiseaseType.grapeBlackRot:        return 'grape_black_rot';
      case DiseaseType.grapeEsca:            return 'grape_esca';
      case DiseaseType.grapeLeafBlight:      return 'grape_leaf_blight';
      case DiseaseType.pepperBacterialSpot:  return 'pepper_bacterial_spot';
      case DiseaseType.citrusGreening:       return 'citrus_greening';
      case DiseaseType.mangoAnthracnose:       return 'mango_anthracnose';
      case DiseaseType.mangoPowderyMildew:     return 'mango_powdery_mildew';
      case DiseaseType.avocadoRootRot:         return 'avocado_root_rot';
      case DiseaseType.avocadoAnthracnose:     return 'avocado_anthracnose';
      case DiseaseType.avocadoDieback:         return 'avocado_dieback';
      case DiseaseType.teaBlisterBlight:       return 'tea_blister_blight';
      case DiseaseType.teaGreyBlight:          return 'tea_grey_blight';
      case DiseaseType.teaRootRot:             return 'tea_root_rot';
      case DiseaseType.cowpeaMosaic:           return 'cowpea_mosaic';
      case DiseaseType.cowpeaBrownBlotch:      return 'cowpea_brown_blotch';
      case DiseaseType.pigeonPeaWilt:          return 'pigeon_pea_wilt';
      case DiseaseType.pigeonPeaSterility:     return 'pigeon_pea_sterility';
      case DiseaseType.eggplantLeafSpot:       return 'eggplant_leaf_spot';
      case DiseaseType.eggplantBacterialWilt:  return 'eggplant_bacterial_wilt';
      case DiseaseType.watermelonAnthracnose:  return 'watermelon_anthracnose';
      case DiseaseType.watermelonGummyStemBlight: return 'watermelon_gummy_stem_blight';
      case DiseaseType.sugarcaneSmut:          return 'sugarcane_smut';
      case DiseaseType.sugarcaneRedRot:        return 'sugarcane_red_rot';
      case DiseaseType.cocoaBlackPod:          return 'cocoa_black_pod';
      case DiseaseType.cocoaSwollenShoot:      return 'cocoa_swollen_shoot';
      case DiseaseType.papayaRingspot:         return 'papaya_ringspot';
      case DiseaseType.papayaAnthracnose:      return 'papaya_anthracnose';
      case DiseaseType.citrusCanker:           return 'citrus_canker';
      case DiseaseType.citrusMelanoase:        return 'citrus_melanose';
    }
  }

  static DiseaseType? fromId(String? id) {
    if (id == null) return null;
    for (final disease in DiseaseType.values) {
      if (disease.id == id) return disease;
    }
    return null;
  }
}
