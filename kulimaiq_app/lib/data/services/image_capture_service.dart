import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum ImageCaptureFailure {
  cameraUnavailable,
  permissionDenied,
  cancelled,
  unknown,
}

class ImageCaptureException implements Exception {
  ImageCaptureException(this.failure, {this.message});

  final ImageCaptureFailure failure;
  final String? message;
}

class ImageCaptureService {
  ImageCaptureService({
    ImagePicker? picker,
    DeviceInfoPlugin? deviceInfo,
  })  : _picker = picker ?? ImagePicker(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final ImagePicker _picker;
  final DeviceInfoPlugin _deviceInfo;

  bool? _cameraSupportedCache;
  bool? _physicalDeviceCache;

  /// True when the device can use the system camera (not simulator/emulator).
  Future<bool> isCameraSupported() async {
    _cameraSupportedCache ??= await _checkCameraSupported();
    return _cameraSupportedCache!;
  }

  Future<bool> _checkCameraSupported() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    return _isPhysicalDevice();
  }

  Future<bool> _isPhysicalDevice() async {
    if (_physicalDeviceCache != null) return _physicalDeviceCache!;
    try {
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        _physicalDeviceCache = info.isPhysicalDevice;
      } else if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        _physicalDeviceCache = info.isPhysicalDevice;
      } else {
        _physicalDeviceCache = true;
      }
    } catch (_) {
      _physicalDeviceCache = true;
    }
    return _physicalDeviceCache!;
  }

  Future<bool> _ensureCameraPermission() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;

    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _ensurePhotosPermission() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;

    if (Platform.isAndroid) {
      final sdk = (await _deviceInfo.androidInfo).version.sdkInt;
      final permission =
          sdk >= 33 ? Permission.photos : Permission.storage;
      var status = await permission.status;
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied) return false;
      status = await permission.request();
      return status.isGranted || status.isLimited;
    }

    var status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied) return false;
    status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  /// Returns local file path, or null if the user cancelled.
  Future<String?> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      if (!await isCameraSupported()) {
        throw ImageCaptureException(ImageCaptureFailure.cameraUnavailable);
      }
      if (!await _ensureCameraPermission()) {
        throw ImageCaptureException(ImageCaptureFailure.permissionDenied);
      }
    } else {
      if (!await _ensurePhotosPermission()) {
        throw ImageCaptureException(ImageCaptureFailure.permissionDenied);
      }
    }

    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      return file?.path;
    } on Exception catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('cancel') || text.contains('cancelled')) {
        return null;
      }
      if (text.contains('not available') ||
          text.contains('no camera') ||
          text.contains('camera_access') ||
          text.contains('unavailable')) {
        throw ImageCaptureException(
          ImageCaptureFailure.cameraUnavailable,
          message: e.toString(),
        );
      }
      if (text.contains('denied') || text.contains('permission')) {
        throw ImageCaptureException(ImageCaptureFailure.permissionDenied);
      }
      throw ImageCaptureException(
        ImageCaptureFailure.unknown,
        message: e.toString(),
      );
    }
  }
}
