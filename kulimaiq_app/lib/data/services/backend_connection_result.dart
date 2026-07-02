/// Result of probing the KulimaIQ FastAPI `/health` endpoint.
class BackendConnectionResult {
  const BackendConnectionResult({
    required this.reachable,
    this.mlModelReady = false,
    this.message = '',
    this.statusCode,
    this.url = '',
  });

  final bool reachable;
  final bool mlModelReady;
  final String message;
  final int? statusCode;
  final String url;

  bool get ok => reachable && mlModelReady;

  factory BackendConnectionResult.unreachable({
    required String url,
    required String message,
    int? statusCode,
  }) =>
      BackendConnectionResult(
        reachable: false,
        message: message,
        statusCode: statusCode,
        url: url,
      );

  factory BackendConnectionResult.fromHealthJson({
    required String url,
    required int statusCode,
    required Map<String, dynamic> data,
  }) {
    final modelReady = data['ml_model_ready'] == true;
    return BackendConnectionResult(
      reachable: true,
      mlModelReady: modelReady,
      statusCode: statusCode,
      url: url,
      message: modelReady
          ? 'Connected — ML model ready (${data['num_classes'] ?? '?'} classes)'
          : 'Connected but ML model is not loaded yet',
    );
  }
}
