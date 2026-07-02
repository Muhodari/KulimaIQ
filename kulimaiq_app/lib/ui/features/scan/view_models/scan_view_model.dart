import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/repositories/diagnosis_repository.dart';
import '../../../../data/services/image_capture_service.dart';
import '../../../../domain/models/crop_type.dart';
import '../../../../domain/models/diagnosis_result.dart';
import '../../../../domain/models/farm.dart';
import '../../../../l10n/app_strings.dart';

class ScanViewModel extends ChangeNotifier {
  ScanViewModel({
    required DiagnosisRepository diagnosisRepository,
    required ImageCaptureService imageCaptureService,
    required AppStrings strings,
  })  : _diagnosisRepository = diagnosisRepository,
        _imageCaptureService = imageCaptureService,
        _strings = strings;

  final DiagnosisRepository _diagnosisRepository;
  final ImageCaptureService _imageCaptureService;
  AppStrings _strings;

  AppStrings get strings => _strings;

  CropType _selectedCrop = CropType.cassava;
  String? _imagePath;
  String? _farmId;
  String? _farmName;
  List<CropType>? _farmCrops;
  DiagnosisResult? _result;
  bool _analyzing = false;
  bool _loadingCapabilities = true;
  bool _cameraSupported = false;
  String? _error;

  CropType get selectedCrop => _selectedCrop;
  String? get imagePath => _imagePath;
  String? get farmId => _farmId;
  String? get farmName => _farmName;
  List<CropType>? get farmCrops => _farmCrops;
  bool get isFarmScan => _farmId != null;
  bool get hasFarmCrops => _farmCrops != null && _farmCrops!.isNotEmpty;
  DiagnosisResult? get result => _result;
  bool get analyzing => _analyzing;
  bool get loadingCapabilities => _loadingCapabilities;
  bool get cameraSupported => _cameraSupported;
  String? get error => _error;

  void refreshStrings(AppStrings strings) {
    _strings = strings;
    notifyListeners();
  }

  Future<void> loadCapabilities() async {
    _loadingCapabilities = true;
    notifyListeners();
    _cameraSupported = await _imageCaptureService.isCameraSupported();
    _loadingCapabilities = false;
    notifyListeners();
  }

  void selectCrop(CropType crop) {
    if (_farmCrops != null && !_farmCrops!.contains(crop)) return;
    _selectedCrop = crop;
    _result = null;
    notifyListeners();
  }

  void beginFarmScan(Farm farm) {
    _farmId = farm.id;
    _farmName = farm.name;
    _farmCrops = List<CropType>.from(farm.crops);
    if (_farmCrops!.isNotEmpty) {
      _selectedCrop = _farmCrops!.first;
    }
    _imagePath = null;
    _result = null;
    _error = null;
    notifyListeners();
  }

  void clearFarmContext() {
    _farmId = null;
    _farmName = null;
    _farmCrops = null;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    _error = null;
    notifyListeners();
    try {
      final path = await _imageCaptureService.pickImage(source);
      if (path != null) {
        _imagePath = path;
        _result = null;
      }
    } on ImageCaptureException catch (e) {
      if (e.failure == ImageCaptureFailure.cancelled) return;
      _error = _messageForCaptureFailure(e.failure, source);
    } catch (_) {
      _error = _strings.t('error_generic');
    } finally {
      notifyListeners();
    }
  }

  String _messageForCaptureFailure(
    ImageCaptureFailure failure,
    ImageSource source,
  ) {
    switch (failure) {
      case ImageCaptureFailure.cameraUnavailable:
        return _strings.t('error_camera_unavailable');
      case ImageCaptureFailure.permissionDenied:
        return source == ImageSource.camera
            ? _strings.t('error_camera_permission')
            : _strings.t('error_gallery_permission');
      case ImageCaptureFailure.cancelled:
        return '';
      case ImageCaptureFailure.unknown:
        return _strings.t('error_generic');
    }
  }

  Future<void> analyze() async {
    if (_imagePath == null) {
      _error = _strings.t('error_no_image');
      notifyListeners();
      return;
    }
    _analyzing = true;
    _error = null;
    _result = null;
    notifyListeners();
    try {
      _result = await _diagnosisRepository.diagnose(
        imagePath: _imagePath!,
        crop: _selectedCrop,
        farmId: _farmId,
      );
    } catch (_) {
      _error = _strings.t('error_generic');
    } finally {
      _analyzing = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    _error = null;
    notifyListeners();
  }

  void startNewScan() {
    _imagePath = null;
    _result = null;
    _error = null;
    notifyListeners();
  }

  void reset() {
    _imagePath = null;
    _result = null;
    _error = null;
    _farmId = null;
    _farmName = null;
    _farmCrops = null;
    notifyListeners();
  }
}
