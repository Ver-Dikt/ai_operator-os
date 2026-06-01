// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

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
    try {
      final request = await html.HttpRequest.request(
        endpoint,
        method: 'GET',
      ).timeout(const Duration(seconds: 5));
      return request.status != null &&
          request.status! >= 200 &&
          request.status! < 500;
    } catch (_) {
      return false;
    }
  }
}
