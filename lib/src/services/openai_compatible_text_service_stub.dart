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

class OpenAiCompatibleTextService {
  const OpenAiCompatibleTextService();

  Future<OpenAiTextResult> completeChat({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<OpenAiChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 900,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    return const OpenAiTextResult(
      success: false,
      error: 'OpenAI-compatible API unavailable on this platform.',
    );
  }
}
