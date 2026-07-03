import 'package:flutter_test/flutter_test.dart';
import 'package:kulimaiq_app/data/services/auth_service.dart';
import 'package:kulimaiq_app/data/services/backend_api_service.dart';
import 'package:kulimaiq_app/data/services/backend_connection_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BackendConnectionResult', () {
    test('ok is true only when reachable and model ready', () {
      expect(
        const BackendConnectionResult(
          reachable: true,
          mlModelReady: true,
        ).ok,
        isTrue,
      );
      expect(
        const BackendConnectionResult(
          reachable: true,
          mlModelReady: false,
        ).ok,
        isFalse,
      );
    });

    test('fromHealthJson parses Render health payload', () {
      final result = BackendConnectionResult.fromHealthJson(
        url: 'https://kulimaiq.onrender.com/health',
        statusCode: 200,
        data: {
          'status': 'ok',
          'mongodb_connected': true,
          'ml_model_ready': true,
          'num_classes': 11,
        },
      );

      expect(result.ok, isTrue);
      expect(result.message, contains('11 classes'));
    });
  });

  group('BackendApiService', () {
    test('productionUrl points at hosted Render API', () {
      expect(
        BackendApiService.productionUrl,
        'https://kulimaiq.onrender.com',
      );
    });

    test('migrates legacy localhost URL to production', () async {
      SharedPreferences.setMockInitialValues({
        'backend_url': 'http://localhost:8001',
      });
      final api = BackendApiService();
      final url = await api.getBaseUrl();
      expect(url, BackendApiService.productionUrl);
    });

    test('ensureProductionUrl sets production when unset', () async {
      SharedPreferences.setMockInitialValues({});
      final api = BackendApiService();
      await api.ensureProductionUrl();
      expect(await api.getBaseUrl(), BackendApiService.productionUrl);
    });
  });

  group('AuthService demo credentials', () {
    test('demo phone and password match README', () {
      expect(AuthService.demoPhone, '0780000000');
      expect(AuthService.demoPassword, 'farmer123');
    });
  });
}
