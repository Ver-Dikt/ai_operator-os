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
    return const OllamaExecutionResult(
      success: false,
      error: 'Ollama unavailable',
    );
  }
}
