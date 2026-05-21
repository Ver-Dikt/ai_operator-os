import 'package:flutter/material.dart';

import '../../models/generation/generation_job.dart';
import '../../models/generation/generation_provider.dart';
import '../../models/generation/generation_request.dart';
import '../../services/generation/generation_provider_registry.dart';
import '../../services/generation/mock_generation_service.dart';
import '../../widgets/generation/browser_workspace_panel.dart';
import '../../widgets/generation/generation_prompt_bar.dart';
import '../../widgets/generation/render_history_rail.dart';
import '../../widgets/generation/result_canvas.dart';

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
  GenerationJob? _selectedJob;

  @override
  void initState() {
    super.initState();
    _providerId = _providersForCurrentMode().first.id;
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
      promptBar: GenerationPromptBar(
        key: ValueKey(_capability),
        capability: _capability,
        providers: providers,
        selectedProviderId: _providerId,
        onProviderChanged: (value) => setState(() => _providerId = value),
        selectedProviderType: _providerType,
        availableProviderTypes: allProviders.map((item) => item.type).toSet(),
        onProviderTypeChanged: _changeProviderType,
        references: _references,
        onAddReference: _addReference,
        onClearReferences: () => setState(_references.clear),
        onGenerate: _generate,
        onPromptChanged: (value) => setState(() => _currentPrompt = value),
        showDuration: true,
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
    if (_providerType != GenerationProviderType.api &&
        _providerType != GenerationProviderType.local) {
      _saveManualResult();
      return;
    }
    final job = _mock.createMockJob(request);
    setState(() {
      _jobs.insert(0, job);
      _selectedJob = job;
    });
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

  void _saveManualResult() {
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
            colors: [Color(0xFF1B1726), Color(0xFF05070B)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WorkspaceHeader(modeSelector: modeSelector),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: canvas),
                        const SizedBox(width: 14),
                        SizedBox(width: 230, child: history),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
          colors: [Color(0xFF1B1726), Color(0xFF05070B)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 28,
                compact ? 18 : 28,
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
                        const SizedBox(height: 18),
                        promptBar,
                        const SizedBox(height: 18),
                        if (compact)
                          Column(
                            children: [
                              canvas,
                              const SizedBox(height: 12),
                              SizedBox(height: 280, child: history),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: canvas),
                              const SizedBox(width: 14),
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
