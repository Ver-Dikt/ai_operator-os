import '../models/execution_job.dart';
import '../state/app_settings.dart';
import 'execution_queue.dart';
import 'ollama_execution_service.dart';

enum PromptBrainMethod { ollama, localTemplate, modelMissing, unavailable }

class PromptBrainResult {
  const PromptBrainResult({
    required this.text,
    required this.method,
    required this.message,
    this.error,
  });

  final String text;
  final PromptBrainMethod method;
  final String message;
  final String? error;

  bool get usedOllama => method == PromptBrainMethod.ollama;
}

class OllamaPromptBrainService {
  const OllamaPromptBrainService({
    this.ollama = const OllamaExecutionService(),
    this.queue,
  });

  final OllamaExecutionService ollama;
  final ExecutionQueue? queue;

  Future<PromptBrainResult> improve({
    required AppSettings settings,
    required ExecutionJobWorkspace workspace,
    required String source,
    required String instruction,
    required String fallback,
    required String capability,
  }) async {
    final endpoint = settings.localEndpoint(
      'ollama',
      fallback: settings.ollamaBaseUrl,
    );
    final model = settings.ollamaModel.trim();

    if (!settings.isLocalProviderEnabled('ollama')) {
      final result = PromptBrainResult(
        text: fallback,
        method: PromptBrainMethod.unavailable,
        message:
            'Ollama недоступна. Используется локальный шаблон.',
      );
      _recordJob(
        settings: settings,
        workspace: workspace,
        capability: capability,
        source: source,
        text: fallback,
        status: ExecutionJobStatus.prepared,
        error: result.message,
        metadata: const {'fallback': 'localTemplate', 'reason': 'disabled'},
      );
      return result;
    }

    if (model.isEmpty) {
      final result = PromptBrainResult(
        text: fallback,
        method: PromptBrainMethod.modelMissing,
        message: 'Выберите модель Ollama в настройках запуска.',
      );
      _recordJob(
        settings: settings,
        workspace: workspace,
        capability: capability,
        source: source,
        text: fallback,
        status: ExecutionJobStatus.localUnavailable,
        error: result.message,
        metadata: const {'fallback': 'localTemplate', 'reason': 'modelMissing'},
      );
      return result;
    }

    final response = await ollama.generate(
      endpoint: endpoint,
      model: model,
      prompt: instruction,
    );
    if (response.success && (response.response?.trim().isNotEmpty ?? false)) {
      final improved = response.response!.trim();
      final result = PromptBrainResult(
        text: improved,
        method: PromptBrainMethod.ollama,
        message: 'Prompt улучшен через Ollama',
      );
      _recordJob(
        settings: settings,
        workspace: workspace,
        capability: capability,
        source: source,
        text: improved,
        status: ExecutionJobStatus.completed,
        metadata: {'model': model, 'endpoint': endpoint},
      );
      return result;
    }

    final result = PromptBrainResult(
      text: fallback,
      method: PromptBrainMethod.localTemplate,
      message:
          'Ollama не отвечает. Используется локальный шаблон.',
      error: response.error,
    );
    _recordJob(
      settings: settings,
      workspace: workspace,
      capability: capability,
      source: source,
      text: fallback,
      status: ExecutionJobStatus.prepared,
      error: response.error ?? result.message,
      metadata: const {'fallback': 'localTemplate', 'reason': 'unavailable'},
    );
    return result;
  }

  void _recordJob({
    required AppSettings settings,
    required ExecutionJobWorkspace workspace,
    required String capability,
    required String source,
    required String text,
    required ExecutionJobStatus status,
    String? error,
    Map<String, String> metadata = const {},
  }) {
    final now = DateTime.now();
    (queue ?? ExecutionQueue.instance).add(
      ExecutionJob(
        id: 'ollama-${now.microsecondsSinceEpoch}',
        workspace: workspace,
        providerId: 'ollama',
        providerName: 'Ollama',
        capability: capability,
        inputPrompt: source,
        composedPrompt: text,
        status: status,
        executionMode: ExecutionJobMode.local,
        createdAt: now,
        updatedAt: now,
        errorMessage: error,
        metadata: {
          'settingsProviderId': 'ollama',
          'endpoint': settings.localEndpoint(
            'ollama',
            fallback: settings.ollamaBaseUrl,
          ),
          ...metadata,
        },
      ),
    );
  }
}
