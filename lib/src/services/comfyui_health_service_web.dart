// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

class ComfyUiHealthResult {
  const ComfyUiHealthResult({
    required this.available,
    this.info,
    this.error,
  });

  final bool available;
  final String? info;
  final String? error;
}

class ComfyUiHealthService {
  const ComfyUiHealthService();

  Future<ComfyUiHealthResult> check({required String endpoint}) async {
    final base = endpoint.replaceFirst(RegExp(r'/+$'), '');
    final system = await _get('$base/system_stats');
    if (system != null) return system;
    final objects = await _get('$base/object_info');
    if (objects != null) return objects;
    return const ComfyUiHealthResult(
      available: false,
      error: 'ComfyUI unavailable',
    );
  }

  Future<ComfyUiHealthResult?> _get(String url) async {
    try {
      final request = await html.HttpRequest.request(
        url,
        method: 'GET',
      ).timeout(const Duration(seconds: 5));
      if (request.status == null ||
          request.status! < 200 ||
          request.status! >= 300) {
        return null;
      }
      String? info;
      try {
        final decoded =
            jsonDecode(request.responseText ?? '{}') as Map<String, dynamic>;
        info = decoded.keys.take(4).join(', ');
      } catch (_) {
        info = null;
      }
      return ComfyUiHealthResult(available: true, info: info);
    } catch (_) {
      return null;
    }
  }
}
