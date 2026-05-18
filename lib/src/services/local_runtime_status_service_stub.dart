import '../models/ai_provider.dart';

class LocalRuntimeStatusService {
  const LocalRuntimeStatusService();

  Future<LocalRuntimeState> checkProvider(AiProvider provider) async {
    if (provider.localEndpoint == null) return LocalRuntimeState.manual;
    return LocalRuntimeState.unknown;
  }
}
