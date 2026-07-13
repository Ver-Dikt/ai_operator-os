import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ai_operator_app.dart';
import '../../models/execution_job.dart';
import '../../models/generation/generation_job.dart';
import '../../models/generation/generation_provider.dart';
import '../../models/generation/generation_request.dart';
import '../../models/manual_result_asset.dart';
import '../../services/comfyui_execution_service.dart';
import '../../services/comfyui_health_service.dart';
import '../../services/execution_queue.dart';
import '../../services/generation/generation_provider_registry.dart';
import '../../services/generation/mock_generation_service.dart';
import '../../services/manual_result_service.dart';
import '../../services/ollama_prompt_brain_service.dart';
import '../../services/openai_image_service.dart';
import '../../services/provider_executor.dart';
import '../../widgets/current_session_strip.dart';
import '../../widgets/generation/manual_result_dialog.dart';
import '../../widgets/generation/render_history_rail.dart';
import '../../widgets/generation/result_media.dart';
import '../../widgets/generation/studio_workflow_steps.dart';

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  static final List<GenerationJob> _cachedJobs = [];
  static String? _cachedSelectedJobId;

  final _registry = const GenerationProviderRegistry();
  final _mock = const MockGenerationService();
  final _promptController = TextEditingController();
  final _negativeController = TextEditingController();
  final List<GenerationJob> _jobs = [];
  final List<String> _references = [];
  GenerationCapability _capability = GenerationCapability.textToImage;
  GenerationProviderType _providerType = GenerationProviderType.api;
  late String _providerId;
  String _currentPrompt = '';
  String _aspectRatio = '1:1';
  int _outputCount = 1;
  String _quality = 'Standard';
  String _style = 'Cinematic';
  String _lighting = 'Soft';
  String _composition = 'Medium Shot';
  String _lens = '50mm';
  String _colorMood = 'Warm';
  _ImagePromptSource _promptSource = _ImagePromptSource.unknown;
  bool _handoffVisible = false;
  bool? _comfyUiAvailable;
  bool _checkingComfyUi = false;
  String _comfyUiStatus = 'Не проверено';
  bool _runtimeWorkspaceOpened = false;
  GenerationJob? _selectedJob;

  @override
  void initState() {
    super.initState();
    _providerId = _providersForCurrentMode().first.id;
    _promptController.addListener(() {
      if (_currentPrompt == _promptController.text) return;
      setState(() {
        _currentPrompt = _promptController.text;
        if (_currentPrompt.trim().isNotEmpty &&
            _promptSource == _ImagePromptSource.unknown) {
          _promptSource = _ImagePromptSource.imageStudio;
        }
      });
    });
    _jobs.addAll(_cachedJobs);
    if (_cachedSelectedJobId != null) {
      for (final job in _jobs) {
        if (job.id == _cachedSelectedJobId) {
          _selectedJob = job;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _negativeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_runtimeWorkspaceOpened) {
      _runtimeWorkspaceOpened = true;
      unawaited(
        FlutenRuntimeScope.read(context).updateCurrentWorkspace('image'),
      );
    }
    final settings = AppSettingsScope.of(context);
    final draft = settings.pendingImagePromptDraft;
    if (draft == null || draft.trim().isEmpty) return;
    setState(() {
      _currentPrompt = draft.trim();
      _promptController.text = draft.trim();
      _promptSource = _ImagePromptSource.aiChat;
      _handoffVisible = true;
    });
    unawaited(
      FlutenRuntimeScope.read(context).setActivePromptDraft(draft.trim()),
    );
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'image',
        title: 'Prompt получен из промпт-чата',
        detail: 'Изображения',
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) settings.clearImagePromptDraft();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allProviders = _registry.forCapability(_capability);
    final providers = _providersForCurrentMode();
    final selectedProvider = _registry.byId(_providerId);
    return _StudioWorkspace(
      eyebrow: 'Генерация изображений',
      title: 'Изображения',
      subtitle:
          'Подготовьте кадр, постер или концепт, выберите сервис и сохраните результат.',
      modeSelector: SegmentedButton<GenerationCapability>(
        segments: const [
          ButtonSegment(
            value: GenerationCapability.textToImage,
            icon: Icon(Icons.text_fields_rounded),
            label: Text('Текст → изображение'),
          ),
          ButtonSegment(
            value: GenerationCapability.imageToImage,
            icon: Icon(Icons.image_search_outlined),
            label: Text('Референс → кадр'),
          ),
        ],
        selected: {_capability},
        onSelectionChanged: (value) => setState(() {
          _capability = value.first;
          _syncProviderForCapability();
          _references.clear();
        }),
      ),
      promptBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StudioWorkflowSteps(
            steps: ['Идея', 'Prompt', 'Сервис', 'Сохранение'],
            activeStep: 1,
          ),
          const SizedBox(height: 8),
          if (_handoffVisible &&
              _promptSource == _ImagePromptSource.aiChat) ...[
            _ImageHandoffBanner(
              onUseBase: _useHandoffAsBase,
              onCopy: _copyBasePrompt,
              onClear: _clearHandoff,
            ),
            const SizedBox(height: 8),
          ],
          _ImagePromptComposer(
            controller: _promptController,
            source: _promptSource,
            onImprove: _improvePromptLocally,
            onPrepare: _prepareImagePrompt,
            onCopy: _copyImagePrompt,
            onOpen: _openSelectedProvider,
            onSaveManualResult: _saveManualResult,
            onClear: _clearPrompt,
          ),
          const SizedBox(height: 8),
          _ImageControlPanel(
            aspectRatio: _aspectRatio,
            outputCount: _outputCount,
            quality: _quality,
            style: _style,
            lighting: _lighting,
            composition: _composition,
            lens: _lens,
            colorMood: _colorMood,
            negativeController: _negativeController,
            onAspectRatio: (value) => setState(() => _aspectRatio = value),
            onOutputCount: (value) => setState(() => _outputCount = value),
            onQuality: (value) => setState(() => _quality = value),
            onStyle: (value) => setState(() => _style = value),
            onLighting: (value) => setState(() => _lighting = value),
            onComposition: (value) => setState(() => _composition = value),
            onLens: (value) => setState(() => _lens = value),
            onColorMood: (value) => setState(() => _colorMood = value),
          ),
          if (selectedProvider.id == 'local-comfyui') ...[
            const SizedBox(height: 8),
            _ComfyUiLocalRouteCard(
              status: _comfyUiStatus,
              checking: _checkingComfyUi,
              available: _comfyUiAvailable,
              endpoint: AppSettingsScope.of(context).localEndpoint(
                'comfyui',
                fallback:
                    selectedProvider.localEndpoint ?? 'http://127.0.0.1:8188',
              ),
              workflowPath: AppSettingsScope.of(
                context,
              ).localWorkflowPath('comfyui'),
              outputFolder: AppSettingsScope.of(
                context,
              ).localOutputFolder('comfyui'),
              onCheck: _checkComfyUi,
              onCopy: _copyImagePrompt,
              onPrepareWorkflow: _generateWithComfyUi,
              onOpen: _openComfyUi,
            ),
          ],
        ],
      ),
      canvas: _ImageWorkspacePreview(
        prompt: _currentPrompt,
        composedPrompt: _composedImagePrompt,
        provider: selectedProvider,
        job: _selectedJob,
      ),
      providerPanel: _ImageProviderPanel(
        providers: providers,
        selectedProviderId: _providerId,
        selectedProvider: selectedProvider,
        selectedProviderType: _providerType,
        availableProviderTypes: allProviders.map((item) => item.type).toSet(),
        onProviderChanged: _selectProvider,
        onProviderTypeChanged: _changeProviderType,
        onCopy: _copyImagePrompt,
        onPrepare: _prepareImagePrompt,
        onOpen: _openSelectedProvider,
        onSaveManualResult: _saveManualResult,
      ),
      history: RenderHistoryRail(
        jobs: _jobs,
        selectedJobId: _selectedJob?.id,
        onSelect: (job) {
          setState(() => _selectedJob = job);
          _persistHistory();
        },
      ),
    );
  }

  // ignore: unused_element
  void _addReference() {
    setState(() => _references.add('reference-${_references.length + 1}.png'));
  }

  // ignore: unused_element
  void _generate(GenerationRequest request) {
    final provider = _registry.byId(request.providerId);
    if (provider.type == GenerationProviderType.browser ||
        provider.type == GenerationProviderType.externalLink) {
      unawaited(_prepareImagePrompt());
      _showMessage(
        'Промпт подготовлен. Скопируйте его и откройте сервис в browser handoff panel.',
      );
      return;
    }
    if (provider.type == GenerationProviderType.local) {
      _showMessage('Локальный runtime будет подключён позже.');
      return;
    }
    if (provider.type == GenerationProviderType.api &&
        provider.requiresApiKey) {
      _showMessage(
        'API для этой модели пока не подключён. Используйте Browser route.',
      );
      return;
    }
    final job = _mock.createMockJob(request);
    setState(() {
      _jobs.insert(0, job);
      _selectedJob = job;
    });
    _persistHistory();
    unawaited(
      FlutenRuntimeScope.read(context).addGenerationJob(
        workspaceType: 'image',
        providerId: provider.id,
        routeType: 'mock',
        prompt: request.prompt,
        status: 'completed',
        resultLabel: job.title,
        resultUrl: job.outputUrl,
      ),
    );
  }

  String get _composedImagePrompt {
    final base = _currentPrompt.trim().isEmpty
        ? 'Напишите, что хотите создать, или используйте prompt из промпт-чата.'
        : _currentPrompt.trim();
    final negative = _negativeController.text.trim();
    return '''
Composed image prompt
Base prompt: $base
Aspect ratio: $_aspectRatio
Style: $_style
Lighting: $_lighting
Composition: $_composition
Camera / lens: $_lens
Color mood: $_colorMood
Quality: $_quality
Output count: $_outputCount
Negative prompt: ${negative.isEmpty ? 'low quality, blurry, artifacts, distorted anatomy, unreadable text' : negative}
Execution note: prompt preparation only. Open the selected image service and paste manually.
''';
  }

  void _improvePromptLocally() {
    unawaited(_improvePromptWithBrain());
  }

  Future<void> _improvePromptWithBrain() async {
    final source = _currentPrompt.trim();
    if (source.isEmpty) {
      _showMessage('Сначала опиши изображение.');
      return;
    }
    final fallback =
        'Subject: $source\n'
        'Environment: detailed scene with clear foreground, midground, and background.\n'
        'Visual style: $_style, production-ready visual language.\n'
        'Composition: $_composition, strong focal subject, clean silhouette.\n'
        'Lighting: $_lighting, motivated highlights and readable shadows.\n'
        'Mood: $_colorMood color mood, coherent atmosphere.\n'
        'Camera / lens: $_lens perspective.\n'
        'Detail / quality: $_quality quality, crisp details, coherent anatomy.\n'
        'Negative prompt: ${_negativeController.text.trim().isEmpty ? 'blurry, low quality, distorted anatomy, random artifacts' : _negativeController.text.trim()}.';
    final instruction =
        '''
You are FLUTEN Visual Engine. Improve this image generation prompt.
Use subject, environment, visual style, composition, lighting, mood, camera/lens, detail/quality, and negative prompt.
Keep the user's idea intact. Return a production-ready image prompt only.

Prompt:
$source

Current controls:
Style: $_style
Lighting: $_lighting
Composition: $_composition
Lens: $_lens
Color mood: $_colorMood
Quality: $_quality
''';
    final result = await const OllamaPromptBrainService().improve(
      settings: AppSettingsScope.of(context),
      workspace: ExecutionJobWorkspace.image,
      source: source,
      instruction: instruction,
      fallback: fallback,
      capability: 'imagePromptImprove',
    );
    if (!mounted) return;
    final improved = result.text;
    setState(() {
      _currentPrompt = improved;
      _promptController.text = improved;
      _promptController.selection = TextSelection.collapsed(
        offset: improved.length,
      );
      _promptSource = _ImagePromptSource.imageStudio;
    });
    final runtime = FlutenRuntimeScope.read(context);
    unawaited(runtime.setActivePromptDraft(improved));
    unawaited(
      runtime.addEvent(
        type: 'image',
        title: result.usedOllama
            ? 'Prompt improved through Ollama'
            : 'Fallback template used',
        detail: result.message,
      ),
    );
    _showMessage(result.message);
  }

  Future<void> _prepareImagePrompt() async {
    final provider = _registry.byId(_providerId);
    if (provider.id == 'local-comfyui') {
      await _prepareComfyUiPrompt(provider);
      return;
    }
    final job = await const ProviderExecutionService().prepare(
      workspace: ExecutionJobWorkspace.image,
      provider: ExecutionProviderRef.fromGenerationProvider(provider),
      capability: _capability.name,
      inputPrompt: _currentPrompt.trim(),
      composedPrompt: _composedImagePrompt.trim(),
      settings: AppSettingsScope.of(context),
    );
    if (!mounted) return;
    _recordExecutionJob(job);
    _showMessage(_messageForExecutionJob(job));
  }

  Future<void> _prepareComfyUiPrompt(GenerationProvider provider) async {
    final settings = AppSettingsScope.of(context);
    final endpoint = settings.localEndpoint(
      'comfyui',
      fallback: provider.localEndpoint ?? 'http://127.0.0.1:8188',
    );
    final workflow = settings.localWorkflowPath('comfyui').trim();
    final health = settings.isLocalProviderEnabled('comfyui')
        ? await const ComfyUiHealthService().check(endpoint: endpoint)
        : const ComfyUiHealthResult(
            available: false,
            error: 'ComfyUI disabled',
          );
    if (!mounted) return;
    setState(() {
      _comfyUiAvailable = health.available;
      _comfyUiStatus = health.available
          ? 'ComfyUI доступна'
          : 'ComfyUI не отвечает';
    });
    final status = !health.available
        ? ExecutionJobStatus.localUnavailable
        : workflow.isEmpty
        ? ExecutionJobStatus.needsWorkflow
        : ExecutionJobStatus.prepared;
    final message = switch (status) {
      ExecutionJobStatus.localUnavailable => 'ComfyUI не подключена.',
      ExecutionJobStatus.needsWorkflow =>
        'ComfyUI доступна. Выберите workflow перед локальным запуском.',
      _ =>
        'ComfyUI готова к запуску API-workflow.',
    };
    final job = _createComfyUiExecutionJob(
      provider: provider,
      endpoint: endpoint,
      workflow: workflow,
      status: status,
      errorMessage: status == ExecutionJobStatus.localUnavailable
          ? message
          : null,
    );
    ExecutionQueue.instance.add(job);
    _recordExecutionJob(job);
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'image',
        title: status == ExecutionJobStatus.needsWorkflow
            ? 'ComfyUI workflow missing'
            : 'ComfyUI route prepared',
        detail: message,
      ),
    );
    _showMessage(message);
  }

  ExecutionJob _createComfyUiExecutionJob({
    required GenerationProvider provider,
    required String endpoint,
    required String workflow,
    required ExecutionJobStatus status,
    String? errorMessage,
  }) {
    final now = DateTime.now();
    final outputFolder = AppSettingsScope.of(
      context,
    ).localOutputFolder('comfyui').trim();
    return ExecutionJob(
      id: 'comfyui-${now.microsecondsSinceEpoch}',
      workspace: ExecutionJobWorkspace.image,
      providerId: provider.id,
      providerName: provider.name,
      capability: _capability.name,
      inputPrompt: _currentPrompt.trim(),
      composedPrompt: _composedImagePrompt.trim(),
      status: status,
      executionMode: ExecutionJobMode.local,
      createdAt: now,
      updatedAt: now,
      errorMessage: errorMessage,
      metadata: {
        'settingsProviderId': 'comfyui',
        'endpoint': endpoint,
        if (workflow.isNotEmpty) 'workflow': workflow,
        if (outputFolder.isNotEmpty) 'outputFolder': outputFolder,
      },
    );
  }

  Future<void> _copyImagePrompt() async {
    await Clipboard.setData(ClipboardData(text: _composedImagePrompt.trim()));
    if (!mounted) return;
    _showMessage('Prompt скопирован.');
  }

  Future<void> _copyBasePrompt() async {
    await Clipboard.setData(ClipboardData(text: _currentPrompt.trim()));
    if (!mounted) return;
    _showMessage('Prompt скопирован');
  }

  void _useHandoffAsBase() {
    unawaited(
      FlutenRuntimeScope.read(context).setActivePromptDraft(_currentPrompt),
    );
    _showMessage('Prompt используется как основа.');
  }

  void _clearHandoff() {
    setState(() {
      _handoffVisible = false;
      _promptSource = _currentPrompt.trim().isEmpty
          ? _ImagePromptSource.unknown
          : _ImagePromptSource.imageStudio;
    });
  }

  Future<void> _openSelectedProvider() async {
    final provider = _registry.byId(_providerId);
    if (provider.id == 'api-gpt-image') {
      await _generateWithOpenAi(provider);
      return;
    }
    if (provider.id == 'local-comfyui') {
      await _generateWithComfyUi();
      return;
    }
    final job = await const ProviderExecutionService().start(
      workspace: ExecutionJobWorkspace.image,
      provider: ExecutionProviderRef.fromGenerationProvider(provider),
      capability: _capability.name,
      inputPrompt: _currentPrompt.trim(),
      composedPrompt: _composedImagePrompt.trim(),
      settings: AppSettingsScope.of(context),
    );
    if (!mounted) return;
    _recordExecutionJob(job);
    _showMessage(_messageForExecutionJob(job));
  }

  Future<void> _generateWithOpenAi(GenerationProvider provider) async {
    if (_currentPrompt.trim().isEmpty) {
      _showMessage('Сначала опишите изображение.');
      return;
    }
    final settings = AppSettingsScope.of(context);
    final apiKey = settings.providerApiKey('openai').trim();
    final configuredModel = settings.providerModel('openai').trim();
    final imageModel = configuredModel.startsWith('gpt-image')
        ? configuredModel
        : 'gpt-image-2';
    if (apiKey.isEmpty) {
      final now = DateTime.now();
      final missingKeyJob = ExecutionJob(
        id: 'openai-image-${now.microsecondsSinceEpoch}',
        workspace: ExecutionJobWorkspace.image,
        providerId: provider.id,
        providerName: provider.name,
        capability: _capability.name,
        inputPrompt: _currentPrompt.trim(),
        composedPrompt: _apiImagePrompt,
        status: ExecutionJobStatus.requiresApiKey,
        executionMode: ExecutionJobMode.api,
        createdAt: now,
        updatedAt: now,
        errorMessage: 'Добавьте API-ключ OpenAI в настройках.',
        metadata: const {'settingsProviderId': 'openai'},
      );
      ExecutionQueue.instance.add(missingKeyJob);
      _recordExecutionJob(missingKeyJob);
      _showMessage('Добавьте API-ключ OpenAI в настройках.');
      return;
    }

    final now = DateTime.now();
    var executionJob = ExecutionJob(
      id: 'openai-image-${now.microsecondsSinceEpoch}',
      workspace: ExecutionJobWorkspace.image,
      providerId: provider.id,
      providerName: provider.name,
      capability: _capability.name,
      inputPrompt: _currentPrompt.trim(),
      composedPrompt: _apiImagePrompt,
      status: ExecutionJobStatus.running,
      executionMode: ExecutionJobMode.api,
      createdAt: now,
      updatedAt: now,
      metadata: {
        'settingsProviderId': 'openai',
        'model': imageModel,
        'size': _openAiImageSize,
      },
    );
    ExecutionQueue.instance.add(executionJob);
    final runtime = FlutenRuntimeScope.read(context);
    final runtimeJob = await runtime.addGenerationJob(
      workspaceType: 'image',
      providerId: provider.id,
      routeType: 'api',
      prompt: _apiImagePrompt,
      status: 'running',
      resultLabel: '${provider.name}: выполняется',
    );
    if (!mounted) return;
    _showMessage('GPT Image: генерация запущена…');

    final result = await const OpenAiImageService().generate(
      baseUrl: settings.providerBaseUrl(
        'openai',
        fallback: 'https://api.openai.com/v1',
      ),
      apiKey: apiKey,
      model: imageModel,
      prompt: _apiImagePrompt,
      size: _openAiImageSize,
      quality: _openAiImageQuality,
      count: _outputCount,
    );
    if (!mounted) return;

    if (!result.success) {
      executionJob = executionJob.copyWith(
        status: ExecutionJobStatus.failed,
        updatedAt: DateTime.now(),
        errorMessage: result.error,
      );
      ExecutionQueue.instance.update(executionJob);
      await runtime.updateGenerationJob(
        runtimeJob.id,
        status: 'failed',
        resultLabel: result.error ?? 'Ошибка GPT Image',
      );
      if (!mounted) return;
      _showMessage(result.error ?? 'Не удалось создать изображение.');
      return;
    }

    final completedAt = DateTime.now();
    executionJob = executionJob.copyWith(
      status: ExecutionJobStatus.completed,
      updatedAt: completedAt,
      resultAssets: result.localPaths,
    );
    ExecutionQueue.instance.update(executionJob);
    final request = GenerationRequest(
      prompt: _currentPrompt.trim(),
      providerId: provider.id,
      capability: _capability,
      aspectRatio: _aspectRatio,
      modelId: imageModel,
      negativePrompt: _negativeController.text.trim(),
      quality: _quality,
      referencePaths: List<String>.from(_references),
    );
    final visibleJob = GenerationJob(
      id: executionJob.id,
      title: _imageJobTitle,
      request: request,
      providerName: provider.name,
      status: GenerationJobStatus.completed,
      createdAt: now,
      updatedAt: completedAt,
      progress: 1,
      previewUrl: result.localPaths.first,
      outputUrl: result.localPaths.first,
    );
    setState(() {
      _jobs.insert(0, visibleJob);
      _selectedJob = visibleJob;
    });
    _persistHistory();
    await runtime.updateGenerationJob(
      runtimeJob.id,
      status: 'completed',
      resultLabel: '${provider.name}: готово',
      resultUrl: result.localPaths.first,
    );
    for (var index = 0; index < result.localPaths.length; index++) {
      await runtime.addAsset(
        type: 'image',
        title: result.localPaths.length == 1
            ? _imageJobTitle
            : '$_imageJobTitle ${index + 1}',
        jobId: runtimeJob.id,
        localPath: result.localPaths[index],
        prompt: _apiImagePrompt,
        providerId: provider.id,
        providerName: provider.name,
        sourceProvider: provider.name,
        sourceWorkspace: 'image',
        status: 'completed',
      );
    }
    if (!mounted) return;
    _showMessage(
      'Готово: ${result.localPaths.length} изображение(я) сохранено в библиотеке.',
    );
  }

  String get _apiImagePrompt {
    final negative = _negativeController.text.trim();
    return '''
${_currentPrompt.trim()}

Visual direction: $_style. Lighting: $_lighting. Composition: $_composition.
Camera / lens: $_lens. Color mood: $_colorMood. Quality: $_quality.
${negative.isEmpty ? '' : 'Avoid: $negative.'}
'''.trim();
  }

  String get _openAiImageSize => switch (_aspectRatio) {
    '16:9' => '1536x864',
    '9:16' => '864x1536',
    '4:5' => '1024x1280',
    '3:2' => '1536x1024',
    _ => '1024x1024',
  };

  String get _openAiImageQuality => switch (_quality.toLowerCase()) {
    'high' || 'высокое' => 'high',
    'low' || 'низкое' => 'low',
    'auto' => 'auto',
    _ => 'medium',
  };

  String get _imageJobTitle {
    final prompt = _currentPrompt.trim();
    if (prompt.length <= 42) return prompt;
    return '${prompt.substring(0, 42)}…';
  }

  Future<void> _generateWithComfyUi() async {
    if (_currentPrompt.trim().isEmpty) {
      _showMessage('Сначала опишите изображение.');
      return;
    }
    final provider = _registry.byId('local-comfyui');
    final settings = AppSettingsScope.of(context);
    final endpoint = settings.localEndpoint(
      'comfyui',
      fallback: provider.localEndpoint ?? 'http://127.0.0.1:8188',
    );
    final workflow = settings.localWorkflowPath('comfyui').trim();
    if (workflow.isEmpty) {
      await _prepareComfyUiPrompt(provider);
      return;
    }
    final now = DateTime.now();
    var executionJob = _createComfyUiExecutionJob(
      provider: provider,
      endpoint: endpoint,
      workflow: workflow,
      status: ExecutionJobStatus.running,
    );
    ExecutionQueue.instance.add(executionJob);
    final runtime = FlutenRuntimeScope.read(context);
    final runtimeJob = await runtime.addGenerationJob(
      workspaceType: 'image',
      providerId: provider.id,
      routeType: 'local',
      prompt: _apiImagePrompt,
      status: 'running',
      resultLabel: 'ComfyUI: выполняется',
    );
    if (!mounted) return;
    setState(() {
      _comfyUiAvailable = true;
      _comfyUiStatus = 'Workflow выполняется…';
    });
    _showMessage('ComfyUI: workflow отправлен…');
    final dimensions = _imageDimensions;
    final result = await const ComfyUiExecutionService().generate(
      endpoint: endpoint,
      workflowPath: workflow,
      outputFolder: settings.localOutputFolder('comfyui'),
      prompt: _currentPrompt.trim(),
      negativePrompt: _negativeController.text.trim(),
      width: dimensions.$1,
      height: dimensions.$2,
    );
    if (!mounted) return;
    if (!result.success) {
      executionJob = executionJob.copyWith(
        status: ExecutionJobStatus.failed,
        updatedAt: DateTime.now(),
        errorMessage: result.error,
      );
      ExecutionQueue.instance.update(executionJob);
      await runtime.updateGenerationJob(
        runtimeJob.id,
        status: 'failed',
        resultLabel: result.error ?? 'Ошибка ComfyUI',
      );
      if (!mounted) return;
      setState(() {
        _comfyUiAvailable = false;
        _comfyUiStatus = 'Ошибка workflow';
      });
      _showMessage(result.error ?? 'Не удалось выполнить workflow ComfyUI.');
      return;
    }
    final completedAt = DateTime.now();
    executionJob = executionJob.copyWith(
      status: ExecutionJobStatus.completed,
      updatedAt: completedAt,
      resultAssets: result.localPaths,
      metadata: {
        ...executionJob.metadata,
        if (result.promptId != null) 'promptId': result.promptId!,
      },
    );
    ExecutionQueue.instance.update(executionJob);
    final visibleJob = GenerationJob(
      id: executionJob.id,
      title: _imageJobTitle,
      request: GenerationRequest(
        prompt: _currentPrompt.trim(),
        providerId: provider.id,
        capability: _capability,
        aspectRatio: _aspectRatio,
        negativePrompt: _negativeController.text.trim(),
        quality: _quality,
        referencePaths: List<String>.from(_references),
      ),
      providerName: provider.name,
      status: GenerationJobStatus.completed,
      createdAt: now,
      updatedAt: completedAt,
      progress: 1,
      previewUrl: result.localPaths.first,
      outputUrl: result.localPaths.first,
    );
    setState(() {
      _jobs.insert(0, visibleJob);
      _selectedJob = visibleJob;
      _comfyUiAvailable = true;
      _comfyUiStatus = 'Workflow завершён';
    });
    _persistHistory();
    await runtime.updateGenerationJob(
      runtimeJob.id,
      status: 'completed',
      resultLabel: 'ComfyUI: готово',
      resultUrl: result.localPaths.first,
    );
    for (var index = 0; index < result.localPaths.length; index++) {
      await runtime.addAsset(
        type: 'image',
        title: result.localPaths.length == 1
            ? _imageJobTitle
            : '$_imageJobTitle ${index + 1}',
        jobId: runtimeJob.id,
        localPath: result.localPaths[index],
        prompt: _apiImagePrompt,
        providerId: provider.id,
        providerName: provider.name,
        sourceProvider: provider.name,
        sourceWorkspace: 'image',
        status: 'completed',
      );
    }
    if (!mounted) return;
    _showMessage('ComfyUI: результат сохранён в библиотеке.');
  }

  (int, int) get _imageDimensions => switch (_aspectRatio) {
    '16:9' => (1344, 768),
    '9:16' => (768, 1344),
    '4:5' => (1024, 1280),
    '3:2' => (1216, 832),
    _ => (1024, 1024),
  };

  Future<void> _checkComfyUi() async {
    final settings = AppSettingsScope.of(context);
    final endpoint = settings.localEndpoint(
      'comfyui',
      fallback: 'http://127.0.0.1:8188',
    );
    setState(() {
      _checkingComfyUi = true;
      _comfyUiStatus = 'Проверяется...';
    });
    final runtime = FlutenRuntimeScope.read(context);
    unawaited(
      runtime.addEvent(
        type: 'image',
        title: 'ComfyUI health check started',
        detail: endpoint,
      ),
    );
    final result = await const ComfyUiHealthService().check(endpoint: endpoint);
    if (!mounted) return;
    setState(() {
      _checkingComfyUi = false;
      _comfyUiAvailable = result.available;
      _comfyUiStatus = result.available
          ? 'ComfyUI доступна'
          : 'ComfyUI не отвечает';
    });
    unawaited(
      runtime.addEvent(
        type: 'image',
        title: result.available ? 'ComfyUI available' : 'ComfyUI unavailable',
        detail: result.info ?? result.error ?? endpoint,
      ),
    );
    _showMessage(
      result.available
          ? 'ComfyUI доступна.'
          : 'ComfyUI не отвечает. Запустите ComfyUI на 127.0.0.1:8188.',
    );
  }

  Future<void> _openComfyUi() async {
    final endpoint = AppSettingsScope.of(
      context,
    ).localEndpoint('comfyui', fallback: 'http://127.0.0.1:8188');
    final opened = await launchUrl(
      Uri.parse(endpoint),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    _showMessage(
      opened
          ? 'ComfyUI открыт во внешнем браузере.'
          : 'Не удалось открыть ComfyUI. Endpoint скопирован.',
    );
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: endpoint));
    }
  }

  void _clearPrompt() {
    setState(() {
      _currentPrompt = '';
      _promptController.clear();
      _promptSource = _ImagePromptSource.unknown;
      _handoffVisible = false;
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<GenerationProvider> _providersForCurrentMode() {
    final providers = _registry
        .forCapability(_capability)
        .where((provider) => provider.type == _providerType)
        .toList(growable: false);
    if (providers.isNotEmpty) return providers;
    final all = _registry.forCapability(_capability);
    _providerType = all.first.type;
    return all.where((provider) => provider.type == _providerType).toList();
  }

  void _syncProviderForCapability() {
    final all = _registry.forCapability(_capability);
    final sameMode = all
        .where((provider) => provider.type == _providerType)
        .toList(growable: false);
    final next = sameMode.isNotEmpty ? sameMode.first : all.first;
    _providerType = next.type;
    _providerId = next.id;
  }

  void _changeProviderType(GenerationProviderType type) {
    final providers = _registry
        .forCapability(_capability)
        .where((provider) => provider.type == type)
        .toList(growable: false);
    if (providers.isEmpty) return;
    setState(() {
      _providerType = type;
      _providerId = providers.first.id;
    });
    _recordProviderSelected(providers.first);
  }

  void _selectProvider(String providerId) {
    final provider = _registry.byId(providerId);
    setState(() {
      _providerId = provider.id;
      _providerType = provider.type;
    });
    _recordProviderSelected(provider);
  }

  void _recordProviderSelected(GenerationProvider provider) {
    unawaited(
      FlutenRuntimeScope.read(
        context,
      ).setActiveProvider(provider.id, route: provider.type.name),
    );
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'image',
        title: 'Image provider selected',
        detail: provider.name,
      ),
    );
  }

  void _recordExecutionJob(ExecutionJob job) {
    unawaited(
      FlutenRuntimeScope.read(context).addGenerationJob(
        workspaceType: job.workspace.name,
        providerId: job.providerId,
        routeType: job.executionMode.name,
        prompt: job.composedPrompt,
        status: job.status.name,
        resultLabel: '${job.providerName}: ${job.status.label}',
        resultUrl: job.metadata['url'],
      ),
    );
  }

  String _messageForExecutionJob(ExecutionJob job) {
    return switch (job.status) {
      ExecutionJobStatus.requiresApiKey =>
        'Нужен API-ключ ${job.providerName}.',
      ExecutionJobStatus.localUnavailable =>
        'Локальная ${job.providerName} не подключена.',
      ExecutionJobStatus.needsWorkflow =>
        '${job.providerName} доступна. Выберите workflow перед локальным запуском.',
      ExecutionJobStatus.manualOnly =>
        'Prompt подготовлен. Откройте ${job.providerName} и вставьте его вручную.',
      ExecutionJobStatus.prepared =>
        'Prompt подготовлен. Откройте ${job.providerName} и вставьте его вручную.',
      ExecutionJobStatus.failed => job.errorMessage ?? 'Execution не выполнен.',
      _ => 'Задача добавлена в очередь подготовки.',
    };
  }

  Future<void> _saveManualResult() async {
    final provider = _registry.byId(_providerId);
    final latestJob = _latestExecutionJob(provider.id);
    final request = await showManualResultDialog(
      context: context,
      initialType: ManualResultType.image,
      sourceWorkspace: 'image',
      prompt: _composedImagePrompt.trim(),
      providerId: provider.id,
      providerName: provider.name,
      externalUrl: provider.launchUrl,
      linkedExecutionJobId: latestJob?.id,
    );
    if (request == null || !mounted) return;
    await const ManualResultService().save(context, request);
    if (!mounted) return;
    _showMessage('Результат сохранён в библиотеке.');
  }

  ExecutionJob? _latestExecutionJob(String providerId) {
    for (final job in ExecutionQueue.instance.listJobs(
      workspace: ExecutionJobWorkspace.image,
    )) {
      if (job.providerId == providerId) return job;
    }
    return null;
  }

  void _persistHistory() {
    _cachedJobs
      ..clear()
      ..addAll(_jobs);
    _cachedSelectedJobId = _selectedJob?.id;
  }
}

enum _ImagePromptSource { unknown, aiChat, imageStudio }

extension _ImagePromptSourceLabel on _ImagePromptSource {
  String get label {
    return switch (this) {
      _ImagePromptSource.aiChat => 'Промпт-чат',
      _ImagePromptSource.imageStudio => 'Изображения',
      _ImagePromptSource.unknown => '',
    };
  }
}

class _ImageHandoffBanner extends StatelessWidget {
  const _ImageHandoffBanner({
    required this.onUseBase,
    required this.onCopy,
    required this.onClear,
  });

  final VoidCallback onUseBase;
  final VoidCallback onCopy;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x18C8FFF4),
        border: Border.all(color: const Color(0x33C8FFF4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Источник: промпт-чат',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Production prompt принят. Можно настроить стиль, композицию и подготовить prompt для выбранного image-сервиса.',
            style: TextStyle(color: Color(0xFFC8D2E2), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onUseBase,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Использовать как основу'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать prompt'),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Очистить handoff'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImagePromptComposer extends StatelessWidget {
  const _ImagePromptComposer({
    required this.controller,
    required this.source,
    required this.onImprove,
    required this.onPrepare,
    required this.onCopy,
    required this.onOpen,
    required this.onSaveManualResult,
    required this.onClear,
  });

  final TextEditingController controller;
  final _ImagePromptSource source;
  final VoidCallback onImprove;
  final VoidCallback onPrepare;
  final VoidCallback onCopy;
  final VoidCallback onOpen;
  final VoidCallback onSaveManualResult;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.image_outlined,
            title: 'Image prompt',
            subtitle: 'Опиши объект, сцену, стиль, свет и настроение.',
          ),
          if (source != _ImagePromptSource.unknown) ...[
            const SizedBox(height: 6),
            Text(
              'Источник: ${source.label}',
              style: const TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              hintText:
                  'Напишите, что хотите создать, или используйте prompt из промпт-чата.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Пока генерация работает через выбранный сервис: скопируйте prompt и откройте сайт провайдера. API/локальный запуск подключим отдельным этапом.',
            style: TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onPrepare,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Подготовить prompt для генерации'),
              ),
              OutlinedButton.icon(
                onPressed: onImprove,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Улучшить prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть выбранный сервис'),
              ),
              OutlinedButton.icon(
                onPressed: onSaveManualResult,
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Сохранить результат вручную'),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Очистить'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComfyUiLocalRouteCard extends StatelessWidget {
  const _ComfyUiLocalRouteCard({
    required this.status,
    required this.checking,
    required this.available,
    required this.endpoint,
    required this.workflowPath,
    required this.outputFolder,
    required this.onCheck,
    required this.onCopy,
    required this.onPrepareWorkflow,
    required this.onOpen,
  });

  final String status;
  final bool checking;
  final bool? available;
  final String endpoint;
  final String workflowPath;
  final String outputFolder;
  final VoidCallback onCheck;
  final VoidCallback onCopy;
  final VoidCallback onPrepareWorkflow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final workflowReady = workflowPath.trim().isNotEmpty;
    final message = available == true
        ? workflowReady
              ? 'ComfyUI доступна. Можно отправить API-workflow и получить результат внутри FLUTEN.'
              : 'ComfyUI доступна, но workflow ещё не выбран.'
        : 'ComfyUI не подключена. Запустите ComfyUI и нажмите Проверить.';
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.memory_rounded,
            title: 'Локальный запуск через ComfyUI',
            subtitle:
                'Укажите API-workflow JSON с токенами {{prompt}}, {{negative_prompt}}, {{width}}, {{height}} и {{seed}}.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(label: Text(status)),
              Chip(label: Text('Endpoint: $endpoint')),
              Chip(
                label: Text(
                  workflowReady ? 'Workflow указан' : 'Workflow не выбран',
                ),
              ),
              if (outputFolder.trim().isNotEmpty)
                Chip(label: Text('Output: $outputFolder')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Color(0xFFA7B1C1), height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: checking ? null : onCheck,
                icon: const Icon(Icons.cable_rounded),
                label: Text(checking ? 'Проверяем...' : 'Проверить ComfyUI'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onPrepareWorkflow,
                icon: const Icon(Icons.account_tree_rounded),
                label: const Text('Запустить workflow'),
              ),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть ComfyUI'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageControlPanel extends StatelessWidget {
  const _ImageControlPanel({
    required this.aspectRatio,
    required this.outputCount,
    required this.quality,
    required this.style,
    required this.lighting,
    required this.composition,
    required this.lens,
    required this.colorMood,
    required this.negativeController,
    required this.onAspectRatio,
    required this.onOutputCount,
    required this.onQuality,
    required this.onStyle,
    required this.onLighting,
    required this.onComposition,
    required this.onLens,
    required this.onColorMood,
  });

  final String aspectRatio;
  final int outputCount;
  final String quality;
  final String style;
  final String lighting;
  final String composition;
  final String lens;
  final String colorMood;
  final TextEditingController negativeController;
  final ValueChanged<String> onAspectRatio;
  final ValueChanged<int> onOutputCount;
  final ValueChanged<String> onQuality;
  final ValueChanged<String> onStyle;
  final ValueChanged<String> onLighting;
  final ValueChanged<String> onComposition;
  final ValueChanged<String> onLens;
  final ValueChanged<String> onColorMood;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.tune_rounded,
            title: 'Параметры изображения',
            subtitle: 'Все настройки входят в итоговый prompt.',
          ),
          const SizedBox(height: 10),
          _ChoiceField(
            label: 'Aspect ratio',
            value: aspectRatio,
            values: const ['1:1', '4:5', '9:16', '16:9', '3:2'],
            onChanged: onAspectRatio,
          ),
          _ChoiceField<int>(
            label: 'Output count',
            value: outputCount,
            values: const [1, 2, 4],
            labelFor: (value) => '$value',
            onChanged: onOutputCount,
          ),
          _ChoiceField(
            label: 'Quality',
            value: quality,
            values: const ['Draft', 'Standard', 'High'],
            onChanged: onQuality,
          ),
          _ChoiceField(
            label: 'Style',
            value: style,
            values: const [
              'Cinematic',
              'Editorial',
              'Product',
              'Anime',
              'Realistic',
              'Concept Art',
              'Noir',
              'Minimal',
            ],
            onChanged: onStyle,
          ),
          _ChoiceField(
            label: 'Lighting',
            value: lighting,
            values: const [
              'Soft',
              'Dramatic',
              'Neon',
              'Golden Hour',
              'Studio',
              'Low Key',
            ],
            onChanged: onLighting,
          ),
          _ChoiceField(
            label: 'Composition',
            value: composition,
            values: const [
              'Close-up',
              'Medium Shot',
              'Wide Shot',
              'Symmetric',
              'Rule of Thirds',
              'Top-down',
            ],
            onChanged: onComposition,
          ),
          _ChoiceField(
            label: 'Camera / Lens',
            value: lens,
            values: const ['35mm', '50mm', '85mm', 'Macro', 'Wide Angle'],
            onChanged: onLens,
          ),
          _ChoiceField(
            label: 'Color mood',
            value: colorMood,
            values: const [
              'Warm',
              'Cold',
              'Pastel',
              'High Contrast',
              'Monochrome',
            ],
            onChanged: onColorMood,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: negativeController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Negative prompt optional',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceField<T> extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.labelFor,
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelFor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<T>(
        initialValue: values.contains(value) ? value : values.first,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in values)
            DropdownMenuItem(
              value: item,
              child: Text(labelFor?.call(item) ?? item.toString()),
            ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _ImageWorkspacePreview extends StatelessWidget {
  const _ImageWorkspacePreview({
    required this.prompt,
    required this.composedPrompt,
    required this.provider,
    required this.job,
  });

  final String prompt;
  final String composedPrompt;
  final GenerationProvider provider;
  final GenerationJob? job;

  @override
  Widget build(BuildContext context) {
    final hasPrompt = prompt.trim().isNotEmpty;
    return _GlassPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 300,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x99070A0F),
                    border: Border.all(color: const Color(0x24FFFFFF)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: job?.outputUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ResultMedia(
                            source: job!.outputUrl,
                            isVideo: false,
                          ),
                        )
                      : hasPrompt
                      ? SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Prompt preview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                prompt,
                                style: const TextStyle(
                                  color: Color(0xFFE8EEF8),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                provider.id == 'api-gpt-image'
                                    ? 'GPT Image запускается прямо в Windows-приложении и сохраняет результат в библиотеку.'
                                    : provider.type ==
                                              GenerationProviderType.api ||
                                          provider.type ==
                                              GenerationProviderType.local
                                    ? 'Для этого маршрута прямой запуск ещё не подключён.'
                                    : 'Скопируйте prompt и откройте выбранный image-сервис.',
                                style: const TextStyle(
                                  color: Color(0xFFA7B1C1),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Здесь будет результат изображения',
                            style: TextStyle(
                              color: Color(0xFF8B97A8),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              _ComposedImagePromptCard(prompt: composedPrompt),
              const SizedBox(height: 12),
              const _ReferencesPlaceholder(),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PanelTitle(
                icon: Icons.photo_size_select_actual_outlined,
                title: 'Рабочая область',
                subtitle: 'Здесь появится подготовленный prompt или результат.',
              ),
              const SizedBox(height: 12),
              if (constraints.hasBoundedHeight)
                Expanded(child: SingleChildScrollView(child: content))
              else
                content,
            ],
          );
        },
      ),
    );
  }
}

class _ComposedImagePromptCard extends StatelessWidget {
  const _ComposedImagePromptCard({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Готовый prompt для изображения',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SelectableText(
            prompt,
            style: const TextStyle(color: Color(0xFFE8EEF8), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ReferencesPlaceholder extends StatelessWidget {
  const _ReferencesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x660B0F16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'References\nСкоро: загрузка референсов, image-to-image, style reference.',
        style: TextStyle(color: Color(0xFFA7B1C1), height: 1.35),
      ),
    );
  }
}

class _ImageProviderPanel extends StatelessWidget {
  const _ImageProviderPanel({
    required this.providers,
    required this.selectedProviderId,
    required this.selectedProvider,
    required this.selectedProviderType,
    required this.availableProviderTypes,
    required this.onProviderChanged,
    required this.onProviderTypeChanged,
    required this.onCopy,
    required this.onPrepare,
    required this.onOpen,
    required this.onSaveManualResult,
  });

  final List<GenerationProvider> providers;
  final String selectedProviderId;
  final GenerationProvider selectedProvider;
  final GenerationProviderType selectedProviderType;
  final Set<GenerationProviderType> availableProviderTypes;
  final ValueChanged<String> onProviderChanged;
  final ValueChanged<GenerationProviderType> onProviderTypeChanged;
  final VoidCallback onCopy;
  final VoidCallback onPrepare;
  final VoidCallback onOpen;
  final VoidCallback onSaveManualResult;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.route_rounded,
            title: 'Сервис изображения',
            subtitle: 'Выберите способ запуска и следующий шаг.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in availableProviderTypes)
                ChoiceChip(
                  label: Text(_typeLabel(type)),
                  selected: selectedProviderType == type,
                  onSelected: (_) => onProviderTypeChanged(type),
                ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: providers.any((item) => item.id == selectedProviderId)
                ? selectedProviderId
                : providers.first.id,
            decoration: const InputDecoration(labelText: 'Provider / model'),
            items: [
              for (final provider in providers)
                DropdownMenuItem(
                  value: provider.id,
                  child: Text(provider.name),
                ),
            ],
            onChanged: (value) {
              if (value != null) onProviderChanged(value);
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Запуск: ${_runModeFor(selectedProvider)}')),
              Chip(label: Text(_statusFor(selectedProvider))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            selectedProvider.description,
            style: const TextStyle(color: Color(0xFFA7B1C1), height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onPrepare,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Подготовить prompt'),
              ),
              FilledButton.icon(
                onPressed: onOpen,
                icon: Icon(
                  selectedProvider.type == GenerationProviderType.api ||
                          selectedProvider.type == GenerationProviderType.local
                      ? Icons.auto_awesome_rounded
                      : Icons.open_in_new_rounded,
                ),
                label: Text(
                  selectedProvider.type == GenerationProviderType.api ||
                          selectedProvider.type == GenerationProviderType.local
                      ? 'Запустить генерацию'
                      : 'Открыть сервис',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onSaveManualResult,
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Сохранить результат вручную'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusFor(GenerationProvider provider) {
    if (provider.id == 'api-gpt-image') return 'API подключён';
    if (provider.id == 'local-comfyui') return 'Workflow API подключён';
    if (provider.type == GenerationProviderType.api &&
        provider.requiresApiKey) {
      return 'Нужен API-ключ';
    }
    return switch (provider.type) {
      GenerationProviderType.api =>
        'Генерация внутри FLUTEN пока не подключена',
      GenerationProviderType.browser => 'Готово: можно открыть сайт',
      GenerationProviderType.local => 'Локальная модель не подключена',
      GenerationProviderType.externalLink =>
        'Скопируйте prompt и вставьте вручную',
    };
  }

  String _runModeFor(GenerationProvider provider) {
    return switch (provider.type) {
      GenerationProviderType.api => 'Через API',
      GenerationProviderType.browser => 'Через сайт',
      GenerationProviderType.local => 'Локально',
      GenerationProviderType.externalLink => 'Вручную',
    };
  }

  String _typeLabel(GenerationProviderType type) {
    return switch (type) {
      GenerationProviderType.api => 'API',
      GenerationProviderType.browser => 'Через сайт',
      GenerationProviderType.local => 'Локальная генерация',
      GenerationProviderType.externalLink => 'Ручной режим',
    };
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xB80B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF22D3EE), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudioWorkspace extends StatelessWidget {
  const _StudioWorkspace({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.modeSelector,
    required this.promptBar,
    required this.canvas,
    required this.providerPanel,
    required this.history,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget modeSelector;
  final Widget promptBar;
  final Widget canvas;
  final Widget providerPanel;
  final Widget history;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 860;
    if (!compact) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.15,
            colors: [Color(0xFF111821), Color(0xFF050609)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WorkspaceHeader(
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle,
                    modeSelector: modeSelector,
                  ),
                  const SizedBox(height: 14),
                  const CurrentSessionStrip(),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 390,
                          child: SingleChildScrollView(child: promptBar),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: canvas),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 260,
                          child: Column(
                            children: [
                              providerPanel,
                              const SizedBox(height: 10),
                              Expanded(child: history),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.15,
          colors: [Color(0xFF111821), Color(0xFF050609)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 28,
                compact ? 14 : 20,
                compact ? 16 : 28,
                compact ? 96 : 28,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1320),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WorkspaceHeader(
                          eyebrow: eyebrow,
                          title: title,
                          subtitle: subtitle,
                          modeSelector: modeSelector,
                        ),
                        const SizedBox(height: 14),
                        const CurrentSessionStrip(),
                        const SizedBox(height: 14),
                        promptBar,
                        const SizedBox(height: 14),
                        providerPanel,
                        const SizedBox(height: 14),
                        if (compact)
                          Column(
                            children: [
                              canvas,
                              const SizedBox(height: 10),
                              SizedBox(height: 280, child: history),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: canvas),
                              const SizedBox(width: 12),
                              SizedBox(height: 520, child: history),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ImagePromptNotice extends StatelessWidget {
  const _ImagePromptNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x18C8FFF4),
        border: Border.all(color: const Color(0x33C8FFF4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Источник: промпт-чат',
        style: TextStyle(
          color: Color(0xFFC8FFF4),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ImageStudioActions extends StatelessWidget {
  const _ImageStudioActions({
    required this.onImprove,
    required this.onPrepare,
    required this.onCopy,
    required this.onOpen,
    required this.onClear,
  });

  final VoidCallback onImprove;
  final VoidCallback onPrepare;
  final VoidCallback onCopy;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Напишите, что хотите создать, или используйте prompt из промпт-чата.',
            style: TextStyle(color: Color(0xFFA7B1C1), fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'Пока генерация работает через выбранный сервис: скопируйте prompt и откройте сайт провайдера. API/локальный запуск подключим отдельным этапом.',
            style: TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onPrepare,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Подготовить prompt для генерации'),
              ),
              OutlinedButton.icon(
                onPressed: onImprove,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Улучшить prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть выбранный сервис'),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Очистить'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ChatPromptNotice extends StatelessWidget {
  const _ChatPromptNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x18C8FFF4),
        border: Border.all(color: const Color(0x33C8FFF4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Prompt получен из промпт-чата',
        style: TextStyle(
          color: Color(0xFFC8FFF4),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.modeSelector,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget modeSelector;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF22D3EE),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFA7B1C1), height: 1.4),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width - 32,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: modeSelector,
          ),
        ),
      ],
    );
  }
}
