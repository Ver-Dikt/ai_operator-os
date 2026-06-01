class ComfyUiHealthResult {
  const ComfyUiHealthResult({
    required this.available,
    this.info,
    this.error,
  });

  final bool available;
  final String? info;
  final String? error;
}

class ComfyUiHealthService {
  const ComfyUiHealthService();

  Future<ComfyUiHealthResult> check({required String endpoint}) async {
    return const ComfyUiHealthResult(
      available: false,
      error: 'ComfyUI unavailable',
    );
  }
}
