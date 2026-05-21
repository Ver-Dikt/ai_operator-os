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

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  final _registry = const GenerationProviderRegistry();
  final _mock = const MockGenerationService();
  final List<GenerationJob> _jobs = [];
  final List<String> _references = [];
  GenerationCapability _capability = GenerationCapability.textToImage;
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
    return _StudioWorkspace(
      eyebrow: 'Генерация изображений',
      title: 'Image Studio',
      subtitle:
          'Создавай кадры, постеры, концепты и вариации по референсам из одного focused prompt workflow.',
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
    setState(() => _references.add('reference-${_references.length + 1}.png'));
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

class _StudioWorkspace extends StatelessWidget {
  const _StudioWorkspace({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.modeSelector,
    required this.promptBar,
    required this.canvas,
    required this.history,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
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
            colors: [Color(0xFF14212A), Color(0xFF05070B)],
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
                  _WorkspaceHeader(
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle,
                    modeSelector: modeSelector,
                  ),
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
          colors: [Color(0xFF14212A), Color(0xFF05070B)],
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
                        _WorkspaceHeader(
                          eyebrow: eyebrow,
                          title: title,
                          subtitle: subtitle,
                          modeSelector: modeSelector,
                        ),
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
        modeSelector,
      ],
    );
  }
}
