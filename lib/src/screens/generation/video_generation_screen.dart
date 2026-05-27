import 'dart:async';

import 'package:flutter/material.dart';

import '../../ai_operator_app.dart';
import '../../models/generation/generation_job.dart';
import '../../models/generation/generation_provider.dart';
import '../../models/generation/generation_request.dart';
import '../../services/generation/generation_provider_registry.dart';
import '../../services/generation/mock_generation_service.dart';
import '../../widgets/generation/browser_workspace_panel.dart';
import '../../widgets/generation/generation_prompt_bar.dart';
import '../../widgets/generation/render_history_rail.dart';
import '../../widgets/generation/result_canvas.dart';
import '../../widgets/current_session_strip.dart';

class VideoGenerationScreen extends StatefulWidget {
  const VideoGenerationScreen({super.key});

  @override
  State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  final _registry = const GenerationProviderRegistry();
  final _mock = const MockGenerationService();
  final List<GenerationJob> _jobs = [];
  final List<String> _references = [];
  GenerationCapability _capability = GenerationCapability.textToVideo;
  GenerationProviderType _providerType = GenerationProviderType.api;
  late String _providerId;
  String _currentPrompt = '';
  String _initialPrompt = '';
  int _promptSeed = 0;
  bool _promptReceivedFromChat = false;
  bool _runtimeWorkspaceOpened = false;
  GenerationJob? _selectedJob;

  @override
  void initState() {
    super.initState();
    _providerId = _providersForCurrentMode().first.id;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_runtimeWorkspaceOpened) {
      _runtimeWorkspaceOpened = true;
      unawaited(
        FlutenRuntimeScope.read(context).updateCurrentWorkspace('video'),
      );
    }
    final settings = AppSettingsScope.of(context);
    final draft = settings.pendingVideoPromptDraft;
    if (draft == null || draft.trim().isEmpty) return;
    setState(() {
      _initialPrompt = draft.trim();
      _currentPrompt = draft.trim();
      _promptSeed++;
      _promptReceivedFromChat = true;
    });
    unawaited(
      FlutenRuntimeScope.read(context).setActivePromptDraft(draft.trim()),
    );
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'video',
        title: 'Prompt received from AI Chat',
        detail: 'Video Studio',
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) settings.clearVideoPromptDraft();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allProviders = _registry.forCapability(_capability);
    final providers = _providersForCurrentMode();
    final selectedProvider = _registry.byId(_providerId);
    final browserLike =
        _providerType == GenerationProviderType.browser ||
        _providerType == GenerationProviderType.externalLink;
    return _VideoWorkspace(
      modeSelector: SegmentedButton<GenerationCapability>(
        segments: const [
          ButtonSegment(
            value: GenerationCapability.textToVideo,
            icon: Icon(Icons.text_fields_rounded),
            label: Text('Текст → видео'),
          ),
          ButtonSegment(
            value: GenerationCapability.imageToVideo,
            icon: Icon(Icons.motion_photos_on_outlined),
            label: Text('Кадр → видео'),
          ),
          ButtonSegment(
            value: GenerationCapability.videoToVideo,
            icon: Icon(Icons.video_settings_outlined),
            label: Text('Видео → видео'),
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
          if (_promptReceivedFromChat) ...[
            const _ChatPromptNotice(),
            const SizedBox(height: 8),
          ],
          GenerationPromptBar(
            key: ValueKey('$_capability-$_promptSeed'),
            capability: _capability,
            providers: providers,
            selectedProviderId: _providerId,
            onProviderChanged: (value) => setState(() => _providerId = value),
            selectedProviderType: _providerType,
            availableProviderTypes: allProviders
                .map((item) => item.type)
                .toSet(),
            onProviderTypeChanged: _changeProviderType,
            references: _references,
            onAddReference: _addReference,
            onClearReferences: () => setState(_references.clear),
            onGenerate: _generate,
            onPromptChanged: (value) => setState(() => _currentPrompt = value),
            initialPrompt: _initialPrompt,
            showDuration: true,
          ),
        ],
      ),
      canvas: browserLike
          ? BrowserWorkspacePanel(
              provider: selectedProvider,
              mode: _providerType,
              prompt: _currentPrompt,
              onSaveManualResult: _saveManualResult,
            )
          : ResultCanvas(job: _selectedJob),
      history: RenderHistoryRail(
        jobs: _jobs,
        selectedJobId: _selectedJob?.id,
        onSelect: (job) => setState(() => _selectedJob = job),
      ),
    );
  }

  void _addReference() {
    final suffix = _capability == GenerationCapability.videoToVideo
        ? 'mp4'
        : 'png';
    setState(
      () => _references.add('reference-${_references.length + 1}.$suffix'),
    );
  }

  void _generate(GenerationRequest request) {
    final provider = _registry.byId(request.providerId);
    if (provider.type == GenerationProviderType.browser ||
        provider.type == GenerationProviderType.externalLink) {
      _saveManualResult(saveAsset: false);
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
    unawaited(
      FlutenRuntimeScope.read(context).addGenerationJob(
        workspaceType: 'video',
        providerId: provider.id,
        routeType: 'mock',
        prompt: request.prompt,
        status: 'completed',
        resultLabel: job.title,
        resultUrl: job.outputUrl,
      ),
    );
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
  }

  void _saveManualResult({bool saveAsset = true}) {
    final request = GenerationRequest(
      prompt: _currentPrompt.trim(),
      providerId: _providerId,
      capability: _capability,
      aspectRatio: 'manual',
      quality: _providerType.workflowLabel,
      durationSeconds: 5,
      referencePaths: _references,
      metadata: {'route': _providerType.name},
    );
    final job = _mock.createMockJob(request);
    setState(() {
      _jobs.insert(0, job);
      _selectedJob = job;
    });
    final provider = _registry.byId(_providerId);
    final route = provider.type == GenerationProviderType.externalLink
        ? 'external'
        : provider.type == GenerationProviderType.browser
        ? 'browser'
        : 'manual';
    unawaited(
      FlutenRuntimeScope.read(context).addGenerationJob(
        workspaceType: 'video',
        providerId: provider.id,
        routeType: route,
        prompt: request.prompt,
        status: saveAsset ? 'manual' : 'prepared',
        resultLabel: saveAsset ? 'Manual video result' : 'Video route prepared',
        resultUrl: provider.launchUrl,
      ),
    );
    if (saveAsset) {
      unawaited(
        FlutenRuntimeScope.read(context).addAsset(
          type: 'manual',
          title: 'Manual video result',
          description: request.prompt,
          sourceProvider: provider.id,
          url: provider.launchUrl,
        ),
      );
    }
  }
}

class _VideoWorkspace extends StatelessWidget {
  const _VideoWorkspace({
    required this.modeSelector,
    required this.promptBar,
    required this.canvas,
    required this.history,
  });

  final Widget modeSelector;
  final Widget promptBar;
  final Widget canvas;
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
            colors: [Color(0xFF15131D), Color(0xFF050609)],
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
                  _WorkspaceHeader(modeSelector: modeSelector),
                  const SizedBox(height: 14),
                  const CurrentSessionStrip(),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: canvas),
                        const SizedBox(width: 12),
                        SizedBox(width: 220, child: history),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: promptBar,
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
          colors: [Color(0xFF15131D), Color(0xFF050609)],
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
                        _WorkspaceHeader(modeSelector: modeSelector),
                        const SizedBox(height: 14),
                        const CurrentSessionStrip(),
                        const SizedBox(height: 14),
                        promptBar,
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
        'Промпт получен из AI Chat',
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
  const _WorkspaceHeader({required this.modeSelector});

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
              const Text(
                'ГЕНЕРАЦИЯ ВИДЕО',
                style: TextStyle(
                  color: Color(0xFFFFB86B),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Video Studio',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Собирай шоты, motion-тесты, image-to-video сцены и видео-обработку с контролами модели рядом с промптом.',
                style: TextStyle(color: Color(0xFFA7B1C1), height: 1.4),
              ),
            ],
          ),
        ),
        modeSelector,
      ],
    );
  }
}
