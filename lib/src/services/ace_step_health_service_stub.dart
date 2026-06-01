class AceStepHealthResult {
  const AceStepHealthResult({
    required this.apiAvailable,
    required this.uiAvailable,
    this.error,
  });

  final bool apiAvailable;
  final bool uiAvailable;
  final String? error;

  bool get available => apiAvailable || uiAvailable;

  String get statusLabel => 'ACE-Step не отвечает';
}

class AceStepHealthService {
  const AceStepHealthService();

  Future<AceStepHealthResult> check({
    required String apiEndpoint,
    required String uiEndpoint,
  }) async {
    return const AceStepHealthResult(
      apiAvailable: false,
      uiAvailable: false,
      error: 'ACE-Step unavailable',
    );
  }
}
