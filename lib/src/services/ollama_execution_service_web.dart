// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

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
    final url = '${endpoint.replaceFirst(RegExp(r"/+$"), "")}/api/generate';
    try {
      final request = await html.HttpRequest.request(
        url,
        method: 'POST',
        requestHeaders: {'Content-Type': 'application/json'},
        sendData: jsonEncode({
          'model': model,
          'prompt': prompt,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 60));
      if (request.status == null ||
          request.status! < 200 ||
          request.status! >= 300) {
        return OllamaExecutionResult(
          success: false,
          error: 'Ollama unavailable (${request.status ?? 'no status'})',
        );
      }
      final data =
          jsonDecode(request.responseText ?? '{}') as Map<String, dynamic>;
      return OllamaExecutionResult(
        success: true,
        response: (data['response'] as String? ?? '').trim(),
      );
    } catch (_) {
      return const OllamaExecutionResult(
        success: false,
        error: 'Ollama unavailable',
      );
    }
  }
}
