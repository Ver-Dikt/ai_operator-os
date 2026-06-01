import 'dart:async';
import 'dart:io';

class AceStepHealthResult {
  const AceStepHealthResult({
    required this.apiAvailable,
    required this.uiAvailable,
    this.error,
  });

  final bool apiAvailable;
  final bool uiAvailable;
  final String? error;

  bool get available => apiAvailable || uiAvailable;

  String get statusLabel {
    if (apiAvailable && uiAvailable) return 'ACE-Step API/UI доступны';
    if (apiAvailable) return 'ACE-Step API доступен';
    if (uiAvailable) return 'ACE-Step UI доступен';
    return 'ACE-Step не отвечает';
  }
}

class AceStepHealthService {
  const AceStepHealthService();

  Future<AceStepHealthResult> check({
    required String apiEndpoint,
    required String uiEndpoint,
  }) async {
    final api = await _reachable(apiEndpoint);
    final ui = await _reachable(uiEndpoint);
    return AceStepHealthResult(
      apiAvailable: api,
      uiAvailable: ui,
      error: api || ui ? null : 'ACE-Step unavailable',
    );
  }

  Future<bool> _reachable(String endpoint) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client
          .getUrl(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 3));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      await response.drain<void>();
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
