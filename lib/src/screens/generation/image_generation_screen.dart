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
import '../../widgets/generation/render_history_rail.dart';
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
    return _StudioWorkspace(
      eyebrow: 'Р“РµРЅРµСЂР°С†РёСЏ РёР·РѕР±СЂР°Р¶РµРЅРёР№',
      title: 'Image Studio',
      subtitle:
          'РЎРѕР·РґР°РІР°Р№ РєР°РґСЂС‹, РїРѕСЃС‚РµСЂС‹, РєРѕРЅС†РµРїС‚С‹ Рё РІР°СЂРёР°С†РёРё РїРѕ СЂРµС„РµСЂРµРЅСЃР°Рј РёР· РѕРґРЅРѕРіРѕ focused prompt workflow.',
      modeSelector: SegmentedButton<GenerationCapability>(
        segments: const [
          ButtonSegment(
            value: GenerationCapability.textToImage,
            icon: Icon(Icons.text_fields_rounded),
            label: Text('РўРµРєСЃС‚ в†’ РёР·РѕР±СЂР°Р¶РµРЅРёРµ'),
          ),
          ButtonSegment(
            value: GenerationCapability.imageToImage,
            icon: Icon(Icons.image_search_outlined),
            label: Text('Р РµС„РµСЂРµРЅСЃ в†’ РєР°РґСЂ'),
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
        ],
      ),
      canvas: _ImageWorkspacePreview(
        prompt: _currentPrompt,
        composedPrompt: _composedImagePrompt,
        provider: selectedProvider,
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
      _saveManualResult(saveAsset: false);
      _showMessage(
        'РџСЂРѕРјРїС‚ РїРѕРґРіРѕС‚РѕРІР»РµРЅ. РЎРєРѕРїРёСЂСѓР№С‚Рµ РµРіРѕ Рё РѕС‚РєСЂРѕР№С‚Рµ СЃРµСЂРІРёСЃ РІ browser handoff panel.',
      );
      return;
    }
    if (provider.type == GenerationProviderType.local) {
      _showMessage(
        'Р›РѕРєР°Р»СЊРЅС‹Р№ runtime Р±СѓРґРµС‚ РїРѕРґРєР»СЋС‡С‘РЅ РїРѕР·Р¶Рµ.',
      );
      return;
    }
    if (provider.type == GenerationProviderType.api &&
        provider.requiresApiKey) {
      _showMessage(
        'API РґР»СЏ СЌС‚РѕР№ РјРѕРґРµР»Рё РїРѕРєР° РЅРµ РїРѕРґРєР»СЋС‡С‘РЅ. РСЃРїРѕР»СЊР·СѓР№С‚Рµ Browser route.',
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
        ? 'РќР°РїРёС€Рё, С‡С‚Рѕ С…РѕС‡РµС€СЊ СЃРѕР·РґР°С‚СЊ, РёР»Рё РёСЃРїРѕР»СЊР·СѓР№ prompt РёР· AI Chat.'
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
    final source = _currentPrompt.trim();
    if (source.isEmpty) {
      _showMessage('РЎРЅР°С‡Р°Р»Р° РѕРїРёС€Рё РёР·РѕР±СЂР°Р¶РµРЅРёРµ.');
      return;
    }
    if (source.isEmpty) {
      _showMessage('РЎРЅР°С‡Р°Р»Р° РЅР°РїРёС€РёС‚Рµ prompt РІ Image Studio.');
      return;
    }
    final improved =
        'Subject: $source\n'
        'Environment: detailed scene with clear foreground, midground, and background.\n'
        'Visual style: $_style, production-ready visual language.\n'
        'Composition: $_composition, strong focal subject, clean silhouette.\n'
        'Lighting: $_lighting, motivated highlights and readable shadows.\n'
        'Mood: $_colorMood color mood, coherent atmosphere.\n'
        'Camera / lens: $_lens perspective.\n'
        'Detail / quality: $_quality quality, crisp details, coherent anatomy.\n'
        'Negative prompt: ${_negativeController.text.trim().isEmpty ? 'blurry, low quality, distorted anatomy, random artifacts' : _negativeController.text.trim()}.';
    setState(() {
      _currentPrompt = improved;
      _promptController.text = improved;
      _promptController.selection = TextSelection.collapsed(
        offset: improved.length,
      );
      _promptSource = _ImagePromptSource.imageStudio;
    });
    unawaited(FlutenRuntimeScope.read(context).setActivePromptDraft(improved));
    _showMessage(
      'Prompt СѓР»СѓС‡С€РµРЅ Р±РµР· API. Р­С‚Рѕ РЅРµ РіРµРЅРµСЂР°С†РёСЏ РёР·РѕР±СЂР°Р¶РµРЅРёСЏ.',
    );
  }

  Future<void> _prepareImagePrompt() async {
    final prompt = _composedImagePrompt.trim();
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    _saveManualResult(saveAsset: false);
    _showMessage(
      'Prompt РїРѕРґРіРѕС‚РѕРІР»РµРЅ Рё СЃРєРѕРїРёСЂРѕРІР°РЅ. РћС‚РєСЂРѕР№С‚Рµ РІС‹Р±СЂР°РЅРЅС‹Р№ СЃРµСЂРІРёСЃ Рё РІСЃС‚Р°РІСЊС‚Рµ РµРіРѕ РІСЂСѓС‡РЅСѓСЋ.',
    );
    _showMessage(
      'Prompt РїРѕРґРіРѕС‚РѕРІР»РµРЅ Рё СЃРєРѕРїРёСЂРѕРІР°РЅ. РћС‚РєСЂРѕР№С‚Рµ РІС‹Р±СЂР°РЅРЅС‹Р№ СЃРµСЂРІРёСЃ Рё РІСЃС‚Р°РІСЊС‚Рµ РµРіРѕ РІСЂСѓС‡РЅСѓСЋ.',
    );
  }

  Future<void> _copyImagePrompt() async {
    await Clipboard.setData(ClipboardData(text: _composedImagePrompt.trim()));
    if (!mounted) return;
    _showMessage('Prompt СЃРєРѕРїРёСЂРѕРІР°РЅ');
    _showMessage('Prompt СЃРєРѕРїРёСЂРѕРІР°РЅ.');
  }

  Future<void> _copyBasePrompt() async {
    await Clipboard.setData(ClipboardData(text: _currentPrompt.trim()));
    if (!mounted) return;
    _showMessage('Prompt СЃРєРѕРїРёСЂРѕРІР°РЅ');
  }

  void _useHandoffAsBase() {
    unawaited(
      FlutenRuntimeScope.read(context).setActivePromptDraft(_currentPrompt),
    );
    _showMessage('Prompt РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РєР°Рє РѕСЃРЅРѕРІР°.');
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
    final url = provider.launchUrl;
    if (url == null) {
      _showMessage(
        'РЈ РІС‹Р±СЂР°РЅРЅРѕРіРѕ РїСЂРѕРІР°Р№РґРµСЂР° РїРѕРєР° РЅРµС‚ СЃР°Р№С‚Р° РґР»СЏ РѕС‚РєСЂС‹С‚РёСЏ.',
      );
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
          ? 'РЎРµСЂРІРёСЃ РѕС‚РєСЂС‹С‚ РІРѕ РІРЅРµС€РЅРµРј Р±СЂР°СѓР·РµСЂРµ'
          : 'РќРµ СѓРґР°Р»РѕСЃСЊ РѕС‚РєСЂС‹С‚СЊ СЃР°Р№С‚. Prompt СЃРєРѕРїРёСЂРѕРІР°РЅ.',
    );
    _showMessage(
      opened
          ? 'Prompt СЃРєРѕРїРёСЂРѕРІР°РЅ. РЎР°Р№С‚ РїСЂРѕРІР°Р№РґРµСЂР° РѕС‚РєСЂС‹С‚.'
          : 'Prompt СЃРєРѕРїРёСЂРѕРІР°РЅ. РќРµ СѓРґР°Р»РѕСЃСЊ РѕС‚РєСЂС‹С‚СЊ СЃР°Р№С‚ РїСЂРѕРІР°Р№РґРµСЂР°.',
    );
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
      FlutenRuntimeScope.read(context).setActiveProvider(
        provider.id,
        route: provider.type.name,
      ),
    );
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'image',
        title: 'Image provider selected',
        detail: provider.name,
      ),
    );
  }

  void _saveManualResult({bool saveAsset = true}) {
    final request = GenerationRequest(
      prompt: _composedImagePrompt.trim(),
      providerId: _providerId,
      capability: _capability,
      aspectRatio: _aspectRatio,
      negativePrompt: _negativeController.text.trim().isEmpty
          ? null
          : _negativeController.text.trim(),
      quality: _quality,
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

enum _ImagePromptSource { unknown, aiChat, imageStudio }

extension _ImagePromptSourceLabel on _ImagePromptSource {
  String get label {
    return switch (this) {
      _ImagePromptSource.aiChat => 'AI Chat / Image Prompt',
      _ImagePromptSource.imageStudio => 'Image Studio',
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
            'РСЃС‚РѕС‡РЅРёРє: AI Chat / Image Prompt',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Production prompt РїСЂРёРЅСЏС‚. РњРѕР¶РЅРѕ РЅР°СЃС‚СЂРѕРёС‚СЊ СЃС‚РёР»СЊ, РєРѕРјРїРѕР·РёС†РёСЋ Рё РїРѕРґРіРѕС‚РѕРІРёС‚СЊ prompt РґР»СЏ РІС‹Р±СЂР°РЅРЅРѕРіРѕ image-СЃРµСЂРІРёСЃР°.',
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
                label: const Text(
                  'РСЃРїРѕР»СЊР·РѕРІР°С‚СЊ РєР°Рє РѕСЃРЅРѕРІСѓ',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('РЎРєРѕРїРёСЂРѕРІР°С‚СЊ prompt'),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                label: const Text('РћС‡РёСЃС‚РёС‚СЊ handoff'),
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
    required this.onClear,
  });

  final TextEditingController controller;
  final _ImagePromptSource source;
  final VoidCallback onImprove;
  final VoidCallback onPrepare;
  final VoidCallback onCopy;
  final VoidCallback onOpen;
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
            subtitle:
                'РћРїРёС€Рё РѕР±СЉРµРєС‚, СЃС†РµРЅСѓ, СЃС‚РёР»СЊ, СЃРІРµС‚ Рё РЅР°СЃС‚СЂРѕРµРЅРёРµ.',
          ),
          if (source != _ImagePromptSource.unknown) ...[
            const SizedBox(height: 6),
            Text(
              'РСЃС‚РѕС‡РЅРёРє: ${source.label}',
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
                  'РќР°РїРёС€Рё, С‡С‚Рѕ С…РѕС‡РµС€СЊ СЃРѕР·РґР°С‚СЊ, РёР»Рё РёСЃРїРѕР»СЊР·СѓР№ prompt РёР· AI Chat.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'РџРѕРєР° РіРµРЅРµСЂР°С†РёСЏ СЂР°Р±РѕС‚Р°РµС‚ С‡РµСЂРµР· РІС‹Р±СЂР°РЅРЅС‹Р№ СЃРµСЂРІРёСЃ: СЃРєРѕРїРёСЂСѓР№С‚Рµ prompt Рё РѕС‚РєСЂРѕР№С‚Рµ СЃР°Р№С‚ РїСЂРѕРІР°Р№РґРµСЂР°. API/Р»РѕРєР°Р»СЊРЅС‹Р№ Р·Р°РїСѓСЃРє РїРѕРґРєР»СЋС‡РёРј РѕС‚РґРµР»СЊРЅС‹Рј СЌС‚Р°РїРѕРј.',
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
                label: const Text(
                  'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ prompt РґР»СЏ РіРµРЅРµСЂР°С†РёРё',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onImprove,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('РЈР»СѓС‡С€РёС‚СЊ prompt Р±РµР· API'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('РЎРєРѕРїРёСЂРѕРІР°С‚СЊ prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text(
                  'РћС‚РєСЂС‹С‚СЊ РІС‹Р±СЂР°РЅРЅС‹Р№ СЃРµСЂРІРёСЃ',
                ),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('РћС‡РёСЃС‚РёС‚СЊ'),
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
            title: 'Visual controls',
            subtitle:
                'РќР°СЃС‚СЂРѕР№РєРё СЃСЂР°Р·Сѓ РІС…РѕРґСЏС‚ РІ СЃРѕР±СЂР°РЅРЅС‹Р№ image prompt.',
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
  });

  final String prompt;
  final String composedPrompt;
  final GenerationProvider provider;

  @override
  Widget build(BuildContext context) {
    final hasPrompt = prompt.trim().isNotEmpty;
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.photo_size_select_actual_outlined,
            title: 'Image workspace',
            subtitle:
                'Р—РґРµСЃСЊ Р±СѓРґРµС‚ СЂРµР·СѓР»СЊС‚Р°С‚ РёР·РѕР±СЂР°Р¶РµРЅРёСЏ.',
          ),
          const SizedBox(height: 12),
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
              child: hasPrompt
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
                            provider.type == GenerationProviderType.api ||
                                    provider.type ==
                                        GenerationProviderType.local
                                ? 'Р“РµРЅРµСЂР°С†РёСЏ РІРЅСѓС‚СЂРё FLUTEN Р±СѓРґРµС‚ РїРѕРґРєР»СЋС‡РµРЅР° РѕС‚РґРµР»СЊРЅС‹Рј СЌС‚Р°РїРѕРј.'
                                : 'РЎРєРѕРїРёСЂСѓР№С‚Рµ prompt Рё РѕС‚РєСЂРѕР№С‚Рµ РІС‹Р±СЂР°РЅРЅС‹Р№ image-СЃРµСЂРІРёСЃ.',
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
                        'Р—РґРµСЃСЊ Р±СѓРґРµС‚ СЂРµР·СѓР»СЊС‚Р°С‚ РёР·РѕР±СЂР°Р¶РµРЅРёСЏ',
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
            'РЎРѕР±СЂР°РЅРЅС‹Р№ image prompt',
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
        'References\nРЎРєРѕСЂРѕ: Р·Р°РіСЂСѓР·РєР° СЂРµС„РµСЂРµРЅСЃРѕРІ, image-to-image, style reference.',
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

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.route_rounded,
            title: 'Image provider',
            subtitle:
                'РљР°Рє Р·Р°РїСѓСЃС‚РёС‚СЊ РІС‹Р±СЂР°РЅРЅС‹Р№ image-СЃРµСЂРІРёСЃ.',
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
              Chip(
                label: Text('Р—Р°РїСѓСЃРє: ${_runModeFor(selectedProvider)}'),
              ),
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
                onPressed: selectedProvider.launchUrl == null ? null : onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('РћС‚РєСЂС‹С‚СЊ СЃР°Р№С‚'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('РЎРєРѕРїРёСЂРѕРІР°С‚СЊ prompt'),
              ),
              FilledButton.icon(
                onPressed: onPrepare,
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ prompt РґР»СЏ РіРµРЅРµСЂР°С†РёРё',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusFor(GenerationProvider provider) {
    if (provider.type == GenerationProviderType.api &&
        provider.requiresApiKey) {
      return 'РќСѓР¶РµРЅ API-РєР»СЋС‡';
    }
    return switch (provider.type) {
      GenerationProviderType.api =>
        'Р“РµРЅРµСЂР°С†РёСЏ РІРЅСѓС‚СЂРё FLUTEN РїРѕРєР° РЅРµ РїРѕРґРєР»СЋС‡РµРЅР°',
      GenerationProviderType.browser =>
        'Р“РѕС‚РѕРІРѕ: РјРѕР¶РЅРѕ РѕС‚РєСЂС‹С‚СЊ СЃР°Р№С‚',
      GenerationProviderType.local =>
        'Р›РѕРєР°Р»СЊРЅР°СЏ РјРѕРґРµР»СЊ РЅРµ РїРѕРґРєР»СЋС‡РµРЅР°',
      GenerationProviderType.externalLink =>
        'РЎРєРѕРїРёСЂСѓР№С‚Рµ prompt Рё РІСЃС‚Р°РІСЊС‚Рµ РІСЂСѓС‡РЅСѓСЋ',
    };
  }

  String _runModeFor(GenerationProvider provider) {
    return switch (provider.type) {
      GenerationProviderType.api => 'Р§РµСЂРµР· API',
      GenerationProviderType.browser => 'Р§РµСЂРµР· СЃР°Р№С‚',
      GenerationProviderType.local => 'Р›РѕРєР°Р»СЊРЅРѕ',
      GenerationProviderType.externalLink => 'Р’СЂСѓС‡РЅСѓСЋ',
    };
  }

  String _typeLabel(GenerationProviderType type) {
    return switch (type) {
      GenerationProviderType.api => 'API',
      GenerationProviderType.browser => 'Р§РµСЂРµР· СЃР°Р№С‚',
      GenerationProviderType.local => 'Р›РѕРєР°Р»СЊРЅР°СЏ РіРµРЅРµСЂР°С†РёСЏ',
      GenerationProviderType.externalLink => 'Р СѓС‡РЅРѕР№ СЂРµР¶РёРј',
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
        'РСЃС‚РѕС‡РЅРёРє: AI Chat / Image Prompt',
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
            'РќР°РїРёС€Рё, С‡С‚Рѕ С…РѕС‡РµС€СЊ СЃРѕР·РґР°С‚СЊ, РёР»Рё РёСЃРїРѕР»СЊР·СѓР№ prompt РёР· AI Chat.',
            style: TextStyle(color: Color(0xFFA7B1C1), fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'РџРѕРєР° РіРµРЅРµСЂР°С†РёСЏ СЂР°Р±РѕС‚Р°РµС‚ С‡РµСЂРµР· РІС‹Р±СЂР°РЅРЅС‹Р№ СЃРµСЂРІРёСЃ: СЃРєРѕРїРёСЂСѓР№С‚Рµ prompt Рё РѕС‚РєСЂРѕР№С‚Рµ СЃР°Р№С‚ РїСЂРѕРІР°Р№РґРµСЂР°. API/Р»РѕРєР°Р»СЊРЅС‹Р№ Р·Р°РїСѓСЃРє РїРѕРґРєР»СЋС‡РёРј РѕС‚РґРµР»СЊРЅС‹Рј СЌС‚Р°РїРѕРј.',
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
                label: const Text(
                  'РџРѕРґРіРѕС‚РѕРІРёС‚СЊ prompt РґР»СЏ РіРµРЅРµСЂР°С†РёРё',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onImprove,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('РЈР»СѓС‡С€РёС‚СЊ prompt Р±РµР· API'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('РЎРєРѕРїРёСЂРѕРІР°С‚СЊ prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text(
                  'РћС‚РєСЂС‹С‚СЊ РІС‹Р±СЂР°РЅРЅС‹Р№ СЃРµСЂРІРёСЃ',
                ),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('РћС‡РёСЃС‚РёС‚СЊ'),
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
        'РџСЂРѕРјРїС‚ РїРѕР»СѓС‡РµРЅ РёР· AI Chat',
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
