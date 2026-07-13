class ElevenLabsTtsResult {
  const ElevenLabsTtsResult({required this.success, this.localPath, this.error});

  final bool success;
  final String? localPath;
  final String? error;
}

class ElevenLabsTtsService {
  const ElevenLabsTtsService();

  Future<ElevenLabsTtsResult> generate({
    required String baseUrl,
    required String apiKey,
    required String voiceId,
    required String text,
  }) async {
    return const ElevenLabsTtsResult(
      success: false,
      error:
          'Прямой ElevenLabs API доступен только в Windows-приложении, чтобы не раскрывать API-ключ.',
    );
  }
}
