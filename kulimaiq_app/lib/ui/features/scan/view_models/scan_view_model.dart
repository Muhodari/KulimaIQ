import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/repositories/diagnosis_repository.dart';
import '../../../../data/services/image_capture_service.dart';
import '../../../../domain/models/crop_type.dart';
import '../../../../domain/models/diagnosis_result.dart';
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
  DiagnosisResult? _result;
  bool _analyzing = false;
  bool _loadingCapabilities = true;
  bool _cameraSupported = false;
  String? _error;

  CropType get selectedCrop => _selectedCrop;
  String? get imagePath => _imagePath;
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
    _selectedCrop = crop;
    _result = null;
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
      );
    } catch (_) {
      _error = _strings.t('error_generic');
    } finally {
      _analyzing = false;
      notifyListeners();
    }
  }

  void reset() {
    _imagePath = null;
    _result = null;
    _error = null;
    notifyListeners();
  }
}
