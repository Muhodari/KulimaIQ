# KulimaIQ Mobile App

Machine learning-powered agricultural intelligence for smallholder farmers in Eastern Africa (Byumba Sector, Rwanda pilot).

## Features

- **CNN disease detection** — Scan leaf photos for CMD, MLN, and BXW (offline-capable inference layer)
- **Climate advisory** — Localized weather and planting guidance for Byumba Sector
- **Market listings** — Basic produce prices from nearby sellers
- **Farmer profile** — Store crops, contact info, and sector
- **Bilingual UI** — Kinyarwanda (default) and English
- **Offline-first** — SQLite history, cached advisories, on-device inference

## Architecture

Layered MVVM structure per Flutter best practices:

```
lib/
├── data/          # Services + Repositories
├── domain/        # Domain models
├── ui/            # Views + ViewModels by feature
├── l10n/          # EN/RW strings
└── di/            # Provider dependency injection
```

## Run

```bash
cd kulimaiq_app
flutter pub get
flutter run
```

## TensorFlow Lite integration

The `DiseaseInferenceService` currently uses a prototype heuristic for demo purposes. To plug in your trained CNN:

1. Export your MobileNetV2/EfficientNet model to `assets/models/crop_disease_classifier.tflite`
2. Add `tflite_flutter` to `pubspec.yaml`
3. Replace `_inferWithHeuristics` in `lib/data/services/disease_inference_service.dart` with TFLite inference (224×224 input)

## Target diseases

| Crop   | Disease                          |
|--------|----------------------------------|
| Cassava | Cassava Mosaic Disease (CMD)    |
| Maize   | Maize Lethal Necrosis (MLN)     |
| Banana  | Banana Xanthomonas Wilt (BXW)   |

## Backend (future)

FastAPI backend for model updates, Rwanda Meteo climate sync, and market data is planned per the capstone design. The app works standalone for the pilot prototype.
