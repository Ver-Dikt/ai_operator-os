import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/browser_ai_tool.dart';
import '../models/execution_job.dart';
import '../models/generation/generation_provider.dart';
import '../state/app_settings.dart';
import 'execution_queue.dart';

class ExecutionProviderRef {
  const ExecutionProviderRef({
    required this.id,
    required this.name,
    required this.mode,
    this.url,
    this.requiresApiKey = false,
    this.localEndpoint,
    this.settingsProviderId,
  });

  final String id;
  final String name;
  final ExecutionJobMode mode;
  final String? url;
  final bool requiresApiKey;
  final String? localEndpoint;
  final String? settingsProviderId;

  factory ExecutionProviderRef.fromGenerationProvider(
    GenerationProvider provider,
  ) {
    return ExecutionProviderRef(
      id: provider.id,
      name: provider.name,
      mode: _modeForGenerationProvider(provider),
      url: provider.launchUrl,
      requiresApiKey: provider.requiresApiKey,
      localEndpoint: provider.localEndpoint,
      settingsProviderId: settingsProviderIdFor(provider.id),
    );
  }

  factory ExecutionProviderRef.fromBrowserTool(BrowserAiTool tool) {
    return ExecutionProviderRef(
      id: tool.id,
      name: tool.name,
      mode: _modeForBrowserTool(tool),
      url: tool.url,
      requiresApiKey: tool.status == BrowserProviderStatus.apiKeyRequired,
      settingsProviderId: tool.id,
    );
  }
}

abstract class ProviderExecutor {
  const ProviderExecutor();

  bool canExecute(ExecutionProviderRef provider, AppSettings settings);

  Future<ExecutionJob> prepare(ExecutionJob job);

  Future<ExecutionJob> start(ExecutionJob job);

  Future<ExecutionJob> cancel(ExecutionJob job);

  ExecutionJob getStatus(ExecutionJob job);
}

class ManualExecutor extends ProviderExecutor {
  const ManualExecutor({this.queue});

  final ExecutionQueue? queue;

  @override
  bool canExecute(ExecutionProviderRef provider, AppSettings settings) => true;

  @override
  Future<ExecutionJob> prepare(ExecutionJob job) async {
    await Clipboard.setData(ClipboardData(text: job.composedPrompt));
    return _update(
      job.copyWith(
        status: ExecutionJobStatus.manualOnly,
        executionMode: ExecutionJobMode.manual,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ExecutionJob> start(ExecutionJob job) => prepare(job);

  @override
  Future<ExecutionJob> cancel(ExecutionJob job) async {
    return _update(
      job.copyWith(
        status: ExecutionJobStatus.cancelled,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  ExecutionJob getStatus(ExecutionJob job) => job;

  ExecutionJob _update(ExecutionJob job) {
    return (queue ?? ExecutionQueue.instance).update(job);
  }
}

class BrowserExecutor extends ProviderExecutor {
  const BrowserExecutor({this.queue});

  final ExecutionQueue? queue;

  @override
  bool canExecute(ExecutionProviderRef provider, AppSettings settings) {
    return provider.url != null && provider.url!.trim().isNotEmpty;
  }

  @override
  Future<ExecutionJob> prepare(ExecutionJob job) async {
    await Clipboard.setData(ClipboardData(text: job.composedPrompt));
    return _update(
      job.copyWith(
        status: ExecutionJobStatus.prepared,
        executionMode: ExecutionJobMode.browser,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ExecutionJob> start(ExecutionJob job) async {
    await Clipboard.setData(ClipboardData(text: job.composedPrompt));
    final url = job.metadata['url'];
    if (url == null || url.trim().isEmpty) {
      return _update(
        job.copyWith(
          status: ExecutionJobStatus.manualOnly,
          errorMessage: 'URL провайдера не задан. Prompt скопирован.',
          updatedAt: DateTime.now(),
        ),
      );
    }
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    return _update(
      job.copyWith(
        status: opened
            ? ExecutionJobStatus.prepared
            : ExecutionJobStatus.manualOnly,
        executionMode: ExecutionJobMode.browser,
        errorMessage: opened
            ? null
            : 'Не удалось открыть сайт. Prompt скопирован.',
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ExecutionJob> cancel(ExecutionJob job) async {
    return _update(
      job.copyWith(
        status: ExecutionJobStatus.cancelled,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  ExecutionJob getStatus(ExecutionJob job) => job;

  ExecutionJob _update(ExecutionJob job) {
    return (queue ?? ExecutionQueue.instance).update(job);
  }
}

class DisabledApiExecutor extends ProviderExecutor {
  const DisabledApiExecutor({this.queue});

  final ExecutionQueue? queue;

  @override
  bool canExecute(ExecutionProviderRef provider, AppSettings settings) {
    final id = provider.settingsProviderId ?? provider.id;
    return settings.hasProviderApiKey(id);
  }

  @override
  Future<ExecutionJob> prepare(ExecutionJob job) async {
    await Clipboard.setData(ClipboardData(text: job.composedPrompt));
    return _update(
      job.copyWith(
        status: job.metadata['hasApiKey'] == 'true'
            ? ExecutionJobStatus.failed
            : ExecutionJobStatus.requiresApiKey,
        executionMode: ExecutionJobMode.api,
        errorMessage: job.metadata['hasApiKey'] == 'true'
            ? 'API execution not implemented yet.'
            : 'Нужен API-ключ ${job.providerName}.',
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ExecutionJob> start(ExecutionJob job) => prepare(job);

  @override
  Future<ExecutionJob> cancel(ExecutionJob job) async {
    return _update(
      job.copyWith(
        status: ExecutionJobStatus.cancelled,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  ExecutionJob getStatus(ExecutionJob job) => job;

  ExecutionJob _update(ExecutionJob job) {
    return (queue ?? ExecutionQueue.instance).update(job);
  }
}

class DisabledLocalExecutor extends ProviderExecutor {
  const DisabledLocalExecutor({this.queue});

  final ExecutionQueue? queue;

  @override
  bool canExecute(ExecutionProviderRef provider, AppSettings settings) {
    return settings.isLocalProviderEnabled(provider.settingsProviderId ?? provider.id);
  }

  @override
  Future<ExecutionJob> prepare(ExecutionJob job) async {
    await Clipboard.setData(ClipboardData(text: job.composedPrompt));
    return _update(
      job.copyWith(
        status: ExecutionJobStatus.localUnavailable,
        executionMode: ExecutionJobMode.local,
        errorMessage: 'Локальный runtime ${job.providerName} не подключен.',
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ExecutionJob> start(ExecutionJob job) => prepare(job);

  @override
  Future<ExecutionJob> cancel(ExecutionJob job) async {
    return _update(
      job.copyWith(
        status: ExecutionJobStatus.cancelled,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  ExecutionJob getStatus(ExecutionJob job) => job;

  ExecutionJob _update(ExecutionJob job) {
    return (queue ?? ExecutionQueue.instance).update(job);
  }
}

class ProviderExecutionService {
  const ProviderExecutionService({this.queue});

  final ExecutionQueue? queue;

  Future<ExecutionJob> prepare({
    required ExecutionJobWorkspace workspace,
    required ExecutionProviderRef provider,
    required String capability,
    required String inputPrompt,
    required String composedPrompt,
    required AppSettings settings,
  }) async {
    final job = _createJob(
      workspace: workspace,
      provider: provider,
      capability: capability,
      inputPrompt: inputPrompt,
      composedPrompt: composedPrompt,
      settings: settings,
    );
    (queue ?? ExecutionQueue.instance).add(job);
    return _executorFor(provider).prepare(job);
  }

  Future<ExecutionJob> start({
    required ExecutionJobWorkspace workspace,
    required ExecutionProviderRef provider,
    required String capability,
    required String inputPrompt,
    required String composedPrompt,
    required AppSettings settings,
  }) async {
    final job = _createJob(
      workspace: workspace,
      provider: provider,
      capability: capability,
      inputPrompt: inputPrompt,
      composedPrompt: composedPrompt,
      settings: settings,
    );
    (queue ?? ExecutionQueue.instance).add(job);
    return _executorFor(provider).start(job);
  }

  ExecutionJob _createJob({
    required ExecutionJobWorkspace workspace,
    required ExecutionProviderRef provider,
    required String capability,
    required String inputPrompt,
    required String composedPrompt,
    required AppSettings settings,
  }) {
    final now = DateTime.now();
    final settingsId = provider.settingsProviderId ?? provider.id;
    return ExecutionJob(
      id: 'exec-${now.microsecondsSinceEpoch}',
      workspace: workspace,
      providerId: provider.id,
      providerName: provider.name,
      capability: capability,
      inputPrompt: inputPrompt,
      composedPrompt: composedPrompt,
      status: ExecutionJobStatus.queued,
      executionMode: provider.mode,
      createdAt: now,
      updatedAt: now,
      metadata: {
        if (provider.url != null) 'url': provider.url!,
        if (provider.localEndpoint != null) 'endpoint': provider.localEndpoint!,
        'settingsProviderId': settingsId,
        'hasApiKey': settings.hasProviderApiKey(settingsId).toString(),
      },
    );
  }

  ProviderExecutor _executorFor(ExecutionProviderRef provider) {
    return switch (provider.mode) {
      ExecutionJobMode.api => DisabledApiExecutor(queue: queue),
      ExecutionJobMode.browser => BrowserExecutor(queue: queue),
      ExecutionJobMode.local => DisabledLocalExecutor(queue: queue),
      ExecutionJobMode.manual => ManualExecutor(queue: queue),
    };
  }
}

ExecutionJobMode _modeForGenerationProvider(GenerationProvider provider) {
  return switch (provider.type) {
    GenerationProviderType.api => ExecutionJobMode.api,
    GenerationProviderType.browser => ExecutionJobMode.browser,
    GenerationProviderType.local => ExecutionJobMode.local,
    GenerationProviderType.externalLink => ExecutionJobMode.manual,
  };
}

ExecutionJobMode _modeForBrowserTool(BrowserAiTool tool) {
  return switch (tool.executionMode) {
    BrowserExecutionMode.api => ExecutionJobMode.api,
    BrowserExecutionMode.browser => ExecutionJobMode.browser,
    BrowserExecutionMode.local => ExecutionJobMode.local,
    BrowserExecutionMode.manual ||
    BrowserExecutionMode.unavailable => ExecutionJobMode.manual,
  };
}

String settingsProviderIdFor(String providerId) {
  return switch (providerId) {
    'api-gpt-image' => 'openai',
    'api-gemini-image' || 'api-veo' => 'gemini',
    'api-flux' => 'stability',
    'local-comfyui' || 'local-comfyui-video' || 'comfyui-local' => 'comfyui',
    'browser-kling' => 'kling',
    'external-runway' => 'runway',
    'browser-recraft' => 'recraft',
    'external-leonardo' => 'leonardo',
    'browser-midjourney' => 'midjourney',
    'browser-ideogram' => 'ideogram',
    'browser-freepik' => 'freepik',
    _ => providerId,
  };
}
