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
    return const OllamaHealthResult(
      available: false,
      error: 'Ollama unavailable',
    );
  }

  Future<OllamaExecutionResult> generate({
    required String endpoint,
    required String model,
    required String prompt,
  }) async {
    return const OllamaExecutionResult(
      success: false,
      error: 'Ollama unavailable',
    );
  }
}
