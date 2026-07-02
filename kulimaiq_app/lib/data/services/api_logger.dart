import 'package:flutter/foundation.dart';

/// Lightweight console logger for backend HTTP calls (visible in `flutter run`).
class ApiLogger {
  static const _tag = '[KulimaIQ API]';

  static void info(String message) {
    debugPrint('$_tag $message');
  }

  static void success(String method, String url, {int? statusCode}) {
    final status = statusCode != null ? ' ($statusCode)' : '';
    debugPrint('$_tag ✓ $method $url$status');
  }

  static void failure(
    String method,
    String url, {
    Object? error,
    int? statusCode,
    String? body,
  }) {
    final parts = <String>['✗ $method', url];
    if (statusCode != null) parts.add('status=$statusCode');
    if (body != null && body.isNotEmpty) {
      final snippet =
          body.length > 240 ? '${body.substring(0, 240)}…' : body;
      parts.add('body=$snippet');
    }
    if (error != null) parts.add('error=$error');
    debugPrint('$_tag ${parts.join(' | ')}');
  }
}
