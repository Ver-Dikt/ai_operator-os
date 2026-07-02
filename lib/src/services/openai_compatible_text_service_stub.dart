class OpenAiChatMessage {
  const OpenAiChatMessage({required this.role, required this.content});

  final String role;
  final String content;
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

enum OpenAiHealthCheckStatus { ready, apiError, networkError, invalidResponse }

class OpenAiHealthCheckResult {
  const OpenAiHealthCheckResult({
    required this.success,
    required this.status,
    required this.message,
  });

  final bool success;
  final OpenAiHealthCheckStatus status;
  final String message;
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
    return const OpenAiTextResult(
      success: false,
      error: 'OpenAI-compatible API unavailable on this platform.',
    );
  }

  Future<OpenAiHealthCheckResult> checkConnection({
    required String baseUrl,
    required String apiKey,
    required String model,
    String providerName = 'OpenAI-compatible provider',
    Duration timeout = const Duration(seconds: 20),
  }) async {
    return const OpenAiHealthCheckResult(
      success: false,
      status: OpenAiHealthCheckStatus.networkError,
      message: 'Провайдер не отвечает.',
    );
  }
}
