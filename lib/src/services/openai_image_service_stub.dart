class OpenAiImageResult {
  const OpenAiImageResult({
    required this.success,
    this.localPaths = const [],
    this.error,
  });

  final bool success;
  final List<String> localPaths;
  final String? error;
}

class OpenAiImageService {
  const OpenAiImageService();

  Future<OpenAiImageResult> generate({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required String size,
    required String quality,
    required int count,
  }) async {
    return const OpenAiImageResult(
      success: false,
      error:
          'Прямой OpenAI API отключён в web-сборке. Используйте Windows-приложение, чтобы не раскрывать API-ключ.',
    );
  }
}
