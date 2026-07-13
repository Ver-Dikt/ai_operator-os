class AceStepExecutionResult {
  const AceStepExecutionResult({
    required this.success,
    this.localPaths = const [],
    this.taskId,
    this.error,
  });

  final bool success;
  final List<String> localPaths;
  final String? taskId;
  final String? error;
}

class AceStepExecutionService {
  const AceStepExecutionService();

  Future<AceStepExecutionResult> generate({
    required String endpoint,
    required String prompt,
    required String lyrics,
    required int durationSeconds,
  }) async {
    return const AceStepExecutionResult(
      success: false,
      error: 'Локальный ACE-Step доступен только в Windows-приложении.',
    );
  }
}
