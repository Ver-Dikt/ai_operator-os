class GeminiVeoResult {
  const GeminiVeoResult({
    required this.success,
    this.localPath,
    this.operationName,
    this.error,
  });

  final bool success;
  final String? localPath;
  final String? operationName;
  final String? error;
}

class GeminiVeoService {
  const GeminiVeoService();

  Future<GeminiVeoResult> generate({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required String aspectRatio,
    required int durationSeconds,
    required String resolution,
  }) async {
    return const GeminiVeoResult(
      success: false,
      error:
          'Прямой Veo API доступен только в Windows-приложении, чтобы не раскрывать API-ключ.',
    );
  }
}
