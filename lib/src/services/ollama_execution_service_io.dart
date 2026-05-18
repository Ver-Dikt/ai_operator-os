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

class OllamaExecutionService {
  const OllamaExecutionService();

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
