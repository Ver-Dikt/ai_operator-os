import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final system = await _get(client, '$base/system_stats');
      if (system != null) return system;
      final objects = await _get(client, '$base/object_info');
      if (objects != null) return objects;
      return const ComfyUiHealthResult(
        available: false,
        error: 'ComfyUI unavailable',
      );
    } catch (_) {
      return const ComfyUiHealthResult(
        available: false,
        error: 'ComfyUI unavailable',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<ComfyUiHealthResult?> _get(HttpClient client, String url) async {
    try {
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      String? info;
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded.isNotEmpty) {
          info = decoded.keys.take(4).join(', ');
        }
      } catch (_) {
        info = null;
      }
      return ComfyUiHealthResult(available: true, info: info);
    } catch (_) {
      return null;
    }
  }
}
