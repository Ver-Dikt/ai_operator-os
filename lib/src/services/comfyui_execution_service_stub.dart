class ComfyUiExecutionResult {
  const ComfyUiExecutionResult({
    required this.success,
    this.localPaths = const [],
    this.promptId,
    this.error,
  });

  final bool success;
  final List<String> localPaths;
  final String? promptId;
  final String? error;
}

class ComfyUiExecutionService {
  const ComfyUiExecutionService();

  Future<ComfyUiExecutionResult> generate({
    required String endpoint,
    required String workflowPath,
    required String outputFolder,
    required String prompt,
    required String negativePrompt,
    required int width,
    required int height,
  }) async {
    return const ComfyUiExecutionResult(
      success: false,
      error: 'Локальный запуск ComfyUI доступен только в Windows-приложении.',
    );
  }
}
