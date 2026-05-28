import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final List<GenerationJob> _jobs = [];
  final List<String> _references = [];
  GenerationCapability _capability = GenerationCapability.textToImage;
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
        type: 'image',
        title: 'Prompt received from AI Chat',
        detail: 'Image Studio',
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
      promptBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_promptReceivedFromChat) ...[
            const _ImagePromptNotice(),
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
          ),
          const SizedBox(height: 8),
          _ImageStudioActions(
            onImprove: _improvePromptLocally,
            onPrepare: _prepareImagePrompt,
            onCopy: _copyImagePrompt,
            onOpen: _openSelectedProvider,
            onClear: _clearPrompt,
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
        onSelect: (job) {
          setState(() => _selectedJob = job);
          _persistHistory();
        },
      ),
    );
  }

  void _addReference() {
    setState(() => _references.add('reference-${_references.length + 1}.png'));
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
        ? 'Напиши, что хочешь создать, или используй prompt из AI Chat.'
        : _currentPrompt.trim();
    return '''
Image production prompt
Base prompt: $base
Composition: clear subject, readable foreground/midground/background
Lighting: motivated cinematic light, controlled contrast
Style: premium visual, coherent details, production-ready image
Execution note: prompt preparation only; open the selected service and paste manually.
''';
  }

  void _improvePromptLocally() {
    final source = _currentPrompt.trim();
    if (source.isEmpty) {
      _showMessage('Сначала напишите prompt в Image Studio.');
      return;
    }
    final improved =
        'Subject: $source\n'
        'Environment: cinematic space with readable depth.\n'
        'Composition: strong focal subject, clean silhouette, balanced frame.\n'
        'Lighting: motivated cinematic light, soft contrast, premium highlights.\n'
        'Mood/style: polished, atmospheric, production-ready.\n'
        'Negative prompt: blurry, low quality, distorted anatomy, random artifacts.';
    setState(() {
      _currentPrompt = improved;
      _initialPrompt = improved;
      _promptSeed++;
    });
    unawaited(FlutenRuntimeScope.read(context).setActivePromptDraft(improved));
    _showMessage('Prompt улучшен без API. Это не генерация изображения.');
  }

  Future<void> _prepareImagePrompt() async {
    final prompt = _composedImagePrompt.trim();
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    _saveManualResult(saveAsset: false);
    _showMessage(
      'Prompt подготовлен и скопирован. Откройте выбранный сервис и вставьте его вручную.',
    );
  }

  Future<void> _copyImagePrompt() async {
    await Clipboard.setData(ClipboardData(text: _composedImagePrompt.trim()));
    if (!mounted) return;
    _showMessage('Prompt скопирован.');
  }

  Future<void> _openSelectedProvider() async {
    final provider = _registry.byId(_providerId);
    final url = provider.launchUrl;
    if (url == null) {
      _showMessage('У выбранного провайдера пока нет сайта для открытия.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: _composedImagePrompt.trim()));
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    _showMessage(
      opened
          ? 'Prompt скопирован. Сайт провайдера открыт.'
          : 'Prompt скопирован. Не удалось открыть сайт провайдера.',
    );
  }

  void _clearPrompt() {
    setState(() {
      _currentPrompt = '';
      _initialPrompt = '';
      _promptSeed++;
      _promptReceivedFromChat = false;
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
  }

  void _saveManualResult({bool saveAsset = true}) {
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
    _persistHistory();
    final provider = _registry.byId(_providerId);
    final route = provider.type == GenerationProviderType.externalLink
        ? 'external'
        : provider.type == GenerationProviderType.browser
        ? 'browser'
        : 'manual';
    unawaited(
      FlutenRuntimeScope.read(context).addGenerationJob(
        workspaceType: 'image',
        providerId: provider.id,
        routeType: route,
        prompt: request.prompt,
        status: saveAsset ? 'manual' : 'prepared',
        resultLabel: saveAsset ? 'Manual image result' : 'Image route prepared',
        resultUrl: provider.launchUrl,
      ),
    );
    if (saveAsset) {
      unawaited(
        FlutenRuntimeScope.read(context).addAsset(
          type: 'manual',
          title: 'Manual image result',
          description: request.prompt,
          sourceProvider: provider.id,
          url: provider.launchUrl,
        ),
      );
    }
  }

  void _persistHistory() {
    _cachedJobs
      ..clear()
      ..addAll(_jobs);
    _cachedSelectedJobId = _selectedJob?.id;
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
                        SizedBox(width: 220, child: history),
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
        'Источник: AI Chat / Image Prompt',
        style: TextStyle(
          color: Color(0xFFC8FFF4),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

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
            'Напиши, что хочешь создать, или используй prompt из AI Chat.',
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
                label: const Text('Улучшить prompt без API'),
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
