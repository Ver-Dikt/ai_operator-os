import 'dart:async';
import 'dart:convert';
import 'dart:io';

class OllamaExecutionResult {
  const OllamaExecutionResult({
    required this.success,
    this.response,
    this.error,
  });

  final bool success;
  final String? response;
  final String? error;
}

class OllamaHealthResult {
  const OllamaHealthResult({
    required this.available,
    this.models = const [],
    this.error,
  });

  final bool available;
  final List<String> models;
  final String? error;
}

class OllamaExecutionService {
  const OllamaExecutionService();

  Future<OllamaHealthResult> checkHealth({required String endpoint}) async {
    final uri = Uri.parse(
      '${endpoint.replaceFirst(RegExp(r"/+$"), "")}/api/tags',
    );
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.getUrl(uri).timeout(
        const Duration(seconds: 3),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return OllamaHealthResult(
          available: false,
          error: 'Ollama unavailable (${response.statusCode})',
        );
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final models = (data['models'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item['name'] as String?)
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty)
          .toList(growable: false);
      return OllamaHealthResult(available: true, models: models);
    } catch (_) {
      return const OllamaHealthResult(
        available: false,
        error: 'Ollama unavailable',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<OllamaExecutionResult> generate({
    required String endpoint,
    required String model,
    required String prompt,
  }) async {
    final uri = Uri.parse(
      '${endpoint.replaceFirst(RegExp(r"/+$"), "")}/api/generate',
    );
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 4));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({'model': model, 'prompt': prompt, 'stream': false}),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return OllamaExecutionResult(
          success: false,
          error: 'Ollama unavailable (${response.statusCode})',
        );
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      return OllamaExecutionResult(
        success: true,
        response: (data['response'] as String? ?? '').trim(),
      );
    } catch (_) {
      return const OllamaExecutionResult(
        success: false,
        error: 'Ollama unavailable',
      );
    } finally {
      client.close(force: true);
    }
  }
}
