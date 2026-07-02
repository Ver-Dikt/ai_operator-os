import 'dart:async';
import 'dart:convert';
import 'dart:io';

class OpenAiChatMessage {
  const OpenAiChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, String> toJson() {
    return {'role': role, 'content': content};
  }
}

class OpenAiTextResult {
  const OpenAiTextResult({
    required this.success,
    this.content,
    this.error,
    this.responseId,
    this.usage,
  });

  final bool success;
  final String? content;
  final String? error;
  final String? responseId;
  final Map<String, String>? usage;
}

class OpenAiCompatibleTextService {
  const OpenAiCompatibleTextService();

  Future<OpenAiTextResult> completeChat({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<OpenAiChatMessage> messages,
    String providerName = 'OpenAI-compatible provider',
    double temperature = 0.7,
    int maxTokens = 900,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final normalizedBase = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$normalizedBase/chat/completions');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 8));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      request.write(
        jsonEncode({
          'model': model,
          'messages': messages.map((message) => message.toJson()).toList(),
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join();
      final decoded = _tryDecode(body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return OpenAiTextResult(
          success: false,
          error: _safeError(decoded, response.statusCode),
        );
      }
      if (decoded is! Map<String, dynamic>) {
        return const OpenAiTextResult(
          success: false,
          error: 'Invalid API response.',
        );
      }
      final choices = decoded['choices'];
      final firstChoice = choices is List && choices.isNotEmpty
          ? choices.first
          : null;
      final message = firstChoice is Map ? firstChoice['message'] : null;
      final content = message is Map ? message['content'] as String? : null;
      final clean = content?.trim();
      if (clean == null || clean.isEmpty) {
        return const OpenAiTextResult(
          success: false,
          error: 'API response did not contain assistant content.',
        );
      }
      return OpenAiTextResult(
        success: true,
        content: clean,
        responseId: decoded['id'] as String?,
        usage: _usage(decoded['usage']),
      );
    } on TimeoutException {
      return OpenAiTextResult(
        success: false,
        error: '$providerName не ответил вовремя.',
      );
    } on SocketException {
      return OpenAiTextResult(
        success: false,
        error: 'Network error while calling $providerName.',
      );
    } catch (_) {
      return OpenAiTextResult(
        success: false,
        error: '$providerName request failed.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Object? _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _safeError(Object? decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map) {
        final message = error['message'] as String?;
        if (message != null && message.trim().isNotEmpty) {
          return 'HTTP $statusCode: ${_redact(message)}';
        }
      }
      final message = decoded['message'] as String?;
      if (message != null && message.trim().isNotEmpty) {
        return 'HTTP $statusCode: ${_redact(message)}';
      }
    }
    return 'HTTP $statusCode';
  }

  String _redact(String value) {
    return value.replaceAll(RegExp(r'sk-[A-Za-z0-9_\-]+'), 'sk-***');
  }

  Map<String, String>? _usage(Object? value) {
    if (value is! Map) return null;
    final result = <String, String>{};
    for (final entry in value.entries) {
      result['${entry.key}'] = '${entry.value}';
    }
    return result.isEmpty ? null : result;
  }
}
