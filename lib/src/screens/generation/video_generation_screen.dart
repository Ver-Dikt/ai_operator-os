import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ai_operator_app.dart';
import '../../models/execution_job.dart';
import '../../models/generation/generation_job.dart';
import '../../models/generation/generation_provider.dart';
import '../../models/generation/generation_request.dart';
import '../../services/generation/generation_provider_registry.dart';
import '../../services/generation/mock_generation_service.dart';
import '../../services/provider_executor.dart';
import '../../widgets/generation/browser_workspace_panel.dart';
import '../../widgets/generation/render_history_rail.dart';
import '../../widgets/generation/result_canvas.dart';
import '../../widgets/current_session_strip.dart';

class VideoGenerationScreen extends StatefulWidget {
  const VideoGenerationScreen({super.key});

  @override
  State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  static final List<GenerationJob> _cachedJobs = [];
  static String? _cachedSelectedJobId;

  final _registry = const GenerationProviderRegistry();
  final _mock = const MockGenerationService();
  final _promptController = TextEditingController();
  final _negativeController = TextEditingController();
  final List<GenerationJob> _jobs = [];
  final List<String> _references = [];
  final List<_VideoShot> _shots = [];
  GenerationCapability _capability = GenerationCapability.textToVideo;
  GenerationProviderType _providerType = GenerationProviderType.api;
  late String _providerId;
  String _currentPrompt = '';
  String _duration = '15s';
  String _aspectRatio = '9:16';
  String _motionIntensity = 'Cinematic';
  String _cameraStyle = 'Push-in';
  String _pacing = 'Medium';
  String _quality = 'Standard';
  _VideoPromptSource _promptSource = _VideoPromptSource.unknown;
  bool _handoffVisible = false;
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
        FlutenRuntimeScope.read(context).updateCurrentWorkspace('video'),
      );
    }
    final settings = AppSettingsScope.of(context);
    final draft = settings.pendingVideoPromptDraft;
    if (draft != null && draft.trim().isNotEmpty) {
      _acceptIncomingPrompt(draft.trim());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) settings.clearVideoPromptDraft();
      });
      return;
    }
    if (_currentPrompt.trim().isNotEmpty) return;
    final runtimeDraft = FlutenRuntimeScope.read(
      context,
    ).getCurrentSession().activePromptDraft;
    if (runtimeDraft != null &&
        runtimeDraft.trim().isNotEmpty &&
        _looksLikeDirectorPrompt(runtimeDraft)) {
      _acceptIncomingPrompt(runtimeDraft.trim());
    }
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
          if (_handoffVisible &&
              _promptSource != _VideoPromptSource.unknown) ...[
            _VideoHandoffBanner(
              source: _promptSource,
              onCopy: _copyProductionPrompt,
              onClear: _clearHandoff,
              onUseBase: _useHandoffAsBase,
            ),
            const SizedBox(height: 8),
          ],
          _CinematicVideoPanel(
            capability: _capability,
            providers: providers,
            selectedProviderId: _providerId,
            selectedProvider: selectedProvider,
            selectedProviderType: _providerType,
            availableProviderTypes: allProviders
                .map((item) => item.type)
                .toSet(),
            promptController: _promptController,
            negativeController: _negativeController,
            currentPrompt: _currentPrompt,
            composedPrompt: _composedPrompt,
            shots: _shots,
            duration: _duration,
            aspectRatio: _aspectRatio,
            motionIntensity: _motionIntensity,
            cameraStyle: _cameraStyle,
            pacing: _pacing,
            quality: _quality,
            onProviderChanged: _selectProvider,
            onProviderTypeChanged: _changeProviderType,
            references: _references,
            onAddReference: _addReference,
            onClearReferences: () => setState(_references.clear),
            onPromptChanged: _setPrompt,
            onImprove: _improveLocally,
            onBuildShots: _buildShotPlan,
            onCopyPrompt: _copyProductionPrompt,
            onClearPrompt: _clearPrompt,
            onCopyComposed: _copyComposedPrompt,
            onPrepareHandoff: _prepareProviderHandoff,
            onOpenProvider: _openProviderSite,
            onDurationChanged: (value) => _setControl('duration', value),
            onAspectRatioChanged: (value) => _setControl('aspect', value),
            onMotionChanged: (value) => _setControl('motion', value),
            onCameraChanged: (value) => _setControl('camera', value),
            onPacingChanged: (value) => _setControl('pacing', value),
            onQualityChanged: (value) => _setControl('quality', value),
          ),
        ],
      ),
      canvas: browserLike
          ? BrowserWorkspacePanel(
              provider: selectedProvider,
              mode: _providerType,
              prompt: _composedPrompt,
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
    final suffix = _capability == GenerationCapability.videoToVideo
        ? 'mp4'
        : 'png';
    setState(
      () => _references.add('reference-${_references.length + 1}.$suffix'),
    );
  }

  // ignore: unused_element
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

  void _acceptIncomingPrompt(String prompt) {
    final source = _looksLikeDirectorPrompt(prompt)
        ? _VideoPromptSource.director
        : _VideoPromptSource.aiChat;
    setState(() {
      _currentPrompt = prompt;
      _promptController.text = prompt;
      _promptSource = source;
      _handoffVisible = true;
    });
    unawaited(FlutenRuntimeScope.read(context).setActivePromptDraft(prompt));
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'video',
        title: source == _VideoPromptSource.director
            ? 'Director handoff accepted'
            : 'Video prompt received from AI Chat',
        detail: 'Video Studio',
      ),
    );
  }

  bool _looksLikeDirectorPrompt(String value) {
    final text = value.toLowerCase();
    return text.contains('cinematic video prompt') &&
        (text.contains('platform / format') ||
            text.contains('shot plan') ||
            text.contains('final gesture'));
  }

  void _setPrompt(String value) {
    setState(() => _currentPrompt = value);
  }

  void _setControl(String key, String value) {
    setState(() {
      switch (key) {
        case 'duration':
          _duration = value;
        case 'aspect':
          _aspectRatio = value;
        case 'motion':
          _motionIntensity = value;
        case 'camera':
          _cameraStyle = value;
        case 'pacing':
          _pacing = value;
        case 'quality':
          _quality = value;
      }
    });
    _recordEvent('Video controls changed', detail: '$key: $value');
  }

  String get _composedPrompt {
    final prompt = _currentPrompt.trim().isEmpty
        ? 'Describe the scene, action, camera, and final gesture.'
        : _currentPrompt.trim();
    final negative = _negativeController.text.trim();
    final shots = _shots.isEmpty
        ? 'Shot plan: not built yet'
        : 'Shot plan: ${_shots.map((shot) => 'Shot ${shot.number}: ${shot.action}, ${shot.cameraMovement}').join(' | ')}';
    final finalGesture = _shots.isEmpty
        ? _extractFinalGesture(prompt)
        : _shots.last.action;
    return '''
Composed cinematic video prompt
Base prompt: $prompt
Duration: $_duration
Aspect ratio: $_aspectRatio
Motion intensity: $_motionIntensity
Camera style: $_cameraStyle
Pacing: $_pacing
Output quality: $_quality
$shots
Final gesture / ending beat: $finalGesture
Negative prompt: ${negative.isEmpty ? 'random zooms, chaotic camera, incoherent motion, flat light, visual noise' : negative}
Execution note: copy/paste handoff only; no API generation is claimed.
''';
  }

  String _extractFinalGesture(String prompt) {
    final marker = RegExp(
      r'final gesture[^:]*:\s*(.+)',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (marker != null) return marker.group(1)?.trim() ?? '';
    return 'End on one clear gesture that changes how the viewer reads the scene.';
  }

  void _improveLocally() {
    final source = _currentPrompt.trim();
    if (source.isEmpty) {
      _showMessage('Add a scene idea first.');
      return;
    }
    final improved =
        'Scene: $source\n'
        'Subject/action: one readable subject performs one motivated action.\n'
        'Environment: layered foreground, midground, and background with cinematic depth.\n'
        'Camera: $_cameraStyle with $_motionIntensity motion, used only for dramatic reason.\n'
        'Lighting: motivated practical light, readable shadows, premium highlights.\n'
        'Mood: emotionally focused, cinematic, coherent.\n'
        'Pacing: $_pacing rhythm, opening clarity, controlled middle movement, final hold.\n'
        'Final gesture: ${_extractFinalGesture(source)}';
    setState(() {
      _currentPrompt = improved;
      _promptController.text = improved;
      _promptController.selection = TextSelection.collapsed(
        offset: improved.length,
      );
    });
    unawaited(FlutenRuntimeScope.read(context).setActivePromptDraft(improved));
    _recordEvent('Local video prompt improved');
    _recordEvent('Video prompt edited');
  }

  void _buildShotPlan() {
    final prompt = _currentPrompt.trim();
    if (prompt.isEmpty) {
      _showMessage('Add a video prompt before building shots.');
      return;
    }
    final count = _duration == '6s' || _duration == '10s'
        ? 3
        : _duration == '15s'
        ? 4
        : 5;
    final shots = List<_VideoShot>.generate(count, (index) {
      final number = index + 1;
      final isFinal = number == count;
      return _VideoShot(
        number: number,
        duration: _shotDurationLabel(number, count),
        action: isFinal
            ? 'Final gesture: ${_extractFinalGesture(prompt)}'
            : 'Beat $number from the prompt, staged as a readable action.',
        cameraMovement: isFinal
            ? 'Hold or slow settle; the ending beat carries the emotion.'
            : '$_cameraStyle movement with a clear dramatic reason.',
        framing: number == 1
            ? 'Opening wide/medium frame with layered depth'
            : isFinal
            ? 'Close hero frame, clean end composition'
            : 'Medium closeup, lens-like depth and subject separation',
        pacing: number == 1
            ? 'Clear setup'
            : isFinal
            ? 'Let the final frame breathe'
            : 'Controlled acceleration',
        emotion: number == 1
            ? 'curiosity'
            : isFinal
            ? 'resolution'
            : 'tension and desire',
        transition: isFinal ? 'final hold' : 'cut on action',
        soundNote: isFinal
            ? 'soft accent, then air'
            : 'atmosphere plus one tactile detail',
      );
    });
    setState(() {
      _shots
        ..clear()
        ..addAll(shots);
    });
    _recordEvent('Video shot plan generated', detail: '$count shots');
    _showMessage('План кадров собран');
  }

  String _shotDurationLabel(int number, int count) {
    final total = int.tryParse(_duration.replaceAll('s', '')) ?? 15;
    final step = total / count;
    final start = ((number - 1) * step).round();
    final end = (number * step).round();
    return '${start}s-${end}s';
  }

  Future<void> _copyProductionPrompt() async {
    await Clipboard.setData(ClipboardData(text: _currentPrompt.trim()));
    if (!mounted) return;
    _showMessage('Production prompt copied.');
    _recordEvent('Video production prompt copied');
  }

  Future<void> _copyComposedPrompt() async {
    await Clipboard.setData(ClipboardData(text: _composedPrompt.trim()));
    if (!mounted) return;
    _showMessage('Composed prompt copied.');
    _recordEvent('Composed video prompt copied');
  }

  void _clearPrompt() {
    setState(() {
      _currentPrompt = '';
      _promptController.clear();
      _shots.clear();
    });
    _recordEvent('Video prompt cleared');
  }

  void _clearHandoff() {
    setState(() {
      _handoffVisible = false;
      _promptSource = _VideoPromptSource.unknown;
    });
    _recordEvent('Director handoff cleared');
  }

  void _useHandoffAsBase() {
    unawaited(
      FlutenRuntimeScope.read(context).setActivePromptDraft(_currentPrompt),
    );
    _showMessage('Handoff prompt is now the base prompt.');
    _recordEvent('Director handoff used as base prompt');
  }

  Future<void> _prepareProviderHandoff() async {
    final provider = _registry.byId(_providerId);
    final job = await const ProviderExecutionService().prepare(
      workspace: ExecutionJobWorkspace.video,
      provider: ExecutionProviderRef.fromGenerationProvider(provider),
      capability: _capability.name,
      inputPrompt: _currentPrompt.trim(),
      composedPrompt: _composedPrompt.trim(),
      settings: AppSettingsScope.of(context),
    );
    if (!mounted) return;
    _recordExecutionJob(job);
    _showMessage(_messageForExecutionJob(job));
    _recordEvent('Video provider handoff prepared', detail: provider.name);
  }

  Future<void> _openProviderSite() async {
    final provider = _registry.byId(_providerId);
    final job = await const ProviderExecutionService().start(
      workspace: ExecutionJobWorkspace.video,
      provider: ExecutionProviderRef.fromGenerationProvider(provider),
      capability: _capability.name,
      inputPrompt: _currentPrompt.trim(),
      composedPrompt: _composedPrompt.trim(),
      settings: AppSettingsScope.of(context),
    );
    if (!mounted) return;
    _recordExecutionJob(job);
    _recordEvent('Video provider site opened', detail: provider.name);
    _showMessage(_messageForExecutionJob(job));
  }

  void _recordEvent(String title, {String? detail}) {
    unawaited(
      FlutenRuntimeScope.read(
        context,
      ).addEvent(type: 'video', title: title, detail: detail),
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
    _recordEvent('Video provider selected', detail: provider.name);
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
      ExecutionJobStatus.requiresApiKey => 'Нужен API-ключ ${job.providerName}.',
      ExecutionJobStatus.localUnavailable =>
        'Локальная ${job.providerName} не подключена.',
      ExecutionJobStatus.manualOnly =>
        'Prompt подготовлен. Откройте ${job.providerName} и вставьте его вручную.',
      ExecutionJobStatus.prepared =>
        'Prompt подготовлен. Откройте ${job.providerName} и вставьте его вручную.',
      ExecutionJobStatus.failed => job.errorMessage ?? 'Execution не выполнен.',
      _ => 'Задача добавлена в очередь подготовки.',
    };
  }

  void _saveManualResult({bool saveAsset = true, String? promptOverride}) {
    final request = GenerationRequest(
      prompt: promptOverride ?? _composedPrompt.trim(),
      providerId: _providerId,
      capability: _capability,
      aspectRatio: _aspectRatio,
      negativePrompt: _negativeController.text.trim().isEmpty
          ? null
          : _negativeController.text.trim(),
      quality: _quality,
      durationSeconds: int.tryParse(_duration.replaceAll('s', '')),
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

  void _persistHistory() {
    _cachedJobs
      ..clear()
      ..addAll(_jobs);
    _cachedSelectedJobId = _selectedJob?.id;
  }
}

enum _VideoPromptSource { unknown, aiChat, director }

extension _VideoPromptSourceLabel on _VideoPromptSource {
  String get label {
    return switch (this) {
      _VideoPromptSource.aiChat => 'AI Chat / Video Prompt',
      _VideoPromptSource.director => 'Director Engine',
      _VideoPromptSource.unknown => '',
    };
  }
}

class _VideoShot {
  const _VideoShot({
    required this.number,
    required this.duration,
    required this.action,
    required this.cameraMovement,
    required this.framing,
    required this.pacing,
    required this.emotion,
    required this.transition,
    required this.soundNote,
  });

  final int number;
  final String duration;
  final String action;
  final String cameraMovement;
  final String framing;
  final String pacing;
  final String emotion;
  final String transition;
  final String soundNote;
}

class _VideoHandoffBanner extends StatelessWidget {
  const _VideoHandoffBanner({
    required this.source,
    required this.onCopy,
    required this.onClear,
    required this.onUseBase,
  });

  final _VideoPromptSource source;
  final VoidCallback onCopy;
  final VoidCallback onClear;
  final VoidCallback onUseBase;

  @override
  Widget build(BuildContext context) {
    final director = source == _VideoPromptSource.director;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: director ? const Color(0x22FFB86B) : const Color(0x18C8FFF4),
        border: Border.all(
          color: director ? const Color(0x55FFB86B) : const Color(0x33C8FFF4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Источник: ${source.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  director
                      ? 'Production prompt принят. Можно собрать план кадров и отправить prompt в выбранный video-сервис.'
                      : 'Production prompt принят из AI Chat / Video Prompt.',
                  style: const TextStyle(
                    color: Color(0xFFC8D2E2),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать production prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onUseBase,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Использовать как основной prompt'),
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

class _CinematicVideoPanel extends StatelessWidget {
  const _CinematicVideoPanel({
    required this.capability,
    required this.providers,
    required this.selectedProviderId,
    required this.selectedProvider,
    required this.selectedProviderType,
    required this.availableProviderTypes,
    required this.promptController,
    required this.negativeController,
    required this.currentPrompt,
    required this.composedPrompt,
    required this.shots,
    required this.duration,
    required this.aspectRatio,
    required this.motionIntensity,
    required this.cameraStyle,
    required this.pacing,
    required this.quality,
    required this.onProviderChanged,
    required this.onProviderTypeChanged,
    required this.references,
    required this.onAddReference,
    required this.onClearReferences,
    required this.onPromptChanged,
    required this.onImprove,
    required this.onBuildShots,
    required this.onCopyPrompt,
    required this.onClearPrompt,
    required this.onCopyComposed,
    required this.onPrepareHandoff,
    required this.onOpenProvider,
    required this.onDurationChanged,
    required this.onAspectRatioChanged,
    required this.onMotionChanged,
    required this.onCameraChanged,
    required this.onPacingChanged,
    required this.onQualityChanged,
  });

  final GenerationCapability capability;
  final List<GenerationProvider> providers;
  final String selectedProviderId;
  final GenerationProvider selectedProvider;
  final GenerationProviderType selectedProviderType;
  final Set<GenerationProviderType> availableProviderTypes;
  final TextEditingController promptController;
  final TextEditingController negativeController;
  final String currentPrompt;
  final String composedPrompt;
  final List<_VideoShot> shots;
  final String duration;
  final String aspectRatio;
  final String motionIntensity;
  final String cameraStyle;
  final String pacing;
  final String quality;
  final ValueChanged<String> onProviderChanged;
  final ValueChanged<GenerationProviderType> onProviderTypeChanged;
  final List<String> references;
  final VoidCallback onAddReference;
  final VoidCallback onClearReferences;
  final ValueChanged<String> onPromptChanged;
  final VoidCallback onImprove;
  final VoidCallback onBuildShots;
  final VoidCallback onCopyPrompt;
  final VoidCallback onClearPrompt;
  final VoidCallback onCopyComposed;
  final VoidCallback onPrepareHandoff;
  final VoidCallback onOpenProvider;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<String> onAspectRatioChanged;
  final ValueChanged<String> onMotionChanged;
  final ValueChanged<String> onCameraChanged;
  final ValueChanged<String> onPacingChanged;
  final ValueChanged<String> onQualityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xD9080B10),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.movie_filter_rounded,
            title: 'Cinematic prompt',
            subtitle:
                'Опишите сцену, действие, камеру и финальный жест. Это подготовка prompt, не генерация видео.',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: promptController,
            minLines: 4,
            maxLines: 7,
            onChanged: onPromptChanged,
            decoration: const InputDecoration(
              hintText: 'Scene, action, camera, mood, final gesture...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onImprove,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Улучшить prompt без API'),
              ),
              OutlinedButton.icon(
                onPressed: onBuildShots,
                icon: const Icon(Icons.view_timeline_outlined),
                label: const Text('Собрать план кадров'),
              ),
              FilledButton.icon(
                onPressed: onPrepareHandoff,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Подготовить prompt для video-сервиса'),
              ),
              OutlinedButton.icon(
                onPressed: onCopyPrompt,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenProvider,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть выбранный сервис'),
              ),
              TextButton.icon(
                onPressed: onClearPrompt,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Очистить'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'FLUTEN локально расширяет prompt: камера, свет, темп, финальный жест. Видео не создается внутри этого действия.',
            style: TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            'Собрать план кадров: создаёт 3–5 кадров сцены: действие, камера, крупность, темп, эмоция.',
            style: TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
          ),
          const SizedBox(height: 12),
          _ControlGrid(
            duration: duration,
            aspectRatio: aspectRatio,
            motionIntensity: motionIntensity,
            cameraStyle: cameraStyle,
            pacing: pacing,
            quality: quality,
            negativeController: negativeController,
            onDurationChanged: onDurationChanged,
            onAspectRatioChanged: onAspectRatioChanged,
            onMotionChanged: onMotionChanged,
            onCameraChanged: onCameraChanged,
            onPacingChanged: onPacingChanged,
            onQualityChanged: onQualityChanged,
          ),
          if (references.isNotEmpty ||
              capability != GenerationCapability.textToVideo) ...[
            const SizedBox(height: 10),
            _ReferencesRow(
              references: references,
              onAdd: onAddReference,
              onClear: onClearReferences,
            ),
          ],
          if (shots.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ShotPlanView(shots: shots),
          ],
          const SizedBox(height: 12),
          _ComposedPromptCard(
            prompt: composedPrompt,
            onCopy: onCopyComposed,
            onPrepare: onPrepareHandoff,
          ),
          const SizedBox(height: 12),
          _VideoProviderPanel(
            providers: providers,
            selectedProviderId: selectedProviderId,
            selectedProvider: selectedProvider,
            selectedProviderType: selectedProviderType,
            availableProviderTypes: availableProviderTypes,
            onProviderChanged: onProviderChanged,
            onProviderTypeChanged: onProviderTypeChanged,
            onCopy: onCopyComposed,
            onPrepare: onPrepareHandoff,
            onOpen: onOpenProvider,
          ),
        ],
      ),
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
        Icon(icon, color: const Color(0xFFFFB86B), size: 20),
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

class _ControlGrid extends StatelessWidget {
  const _ControlGrid({
    required this.duration,
    required this.aspectRatio,
    required this.motionIntensity,
    required this.cameraStyle,
    required this.pacing,
    required this.quality,
    required this.negativeController,
    required this.onDurationChanged,
    required this.onAspectRatioChanged,
    required this.onMotionChanged,
    required this.onCameraChanged,
    required this.onPacingChanged,
    required this.onQualityChanged,
  });

  final String duration;
  final String aspectRatio;
  final String motionIntensity;
  final String cameraStyle;
  final String pacing;
  final String quality;
  final TextEditingController negativeController;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<String> onAspectRatioChanged;
  final ValueChanged<String> onMotionChanged;
  final ValueChanged<String> onCameraChanged;
  final ValueChanged<String> onPacingChanged;
  final ValueChanged<String> onQualityChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 720
            ? constraints.maxWidth
            : (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ChoiceField(
              width: itemWidth,
              label: 'Duration',
              value: duration,
              values: const ['6s', '10s', '15s', '30s'],
              onChanged: onDurationChanged,
            ),
            _ChoiceField(
              width: itemWidth,
              label: 'Aspect ratio',
              value: aspectRatio,
              values: const ['9:16', '16:9', '1:1'],
              onChanged: onAspectRatioChanged,
            ),
            _ChoiceField(
              width: itemWidth,
              label: 'Motion',
              value: motionIntensity,
              values: const ['Stable', 'Cinematic', 'Dynamic', 'Aggressive'],
              onChanged: onMotionChanged,
            ),
            _ChoiceField(
              width: itemWidth,
              label: 'Camera',
              value: cameraStyle,
              values: const [
                'Locked',
                'Push-in',
                'Tracking',
                'Handheld',
                'Orbit',
                'Crane',
              ],
              onChanged: onCameraChanged,
            ),
            _ChoiceField(
              width: itemWidth,
              label: 'Pacing',
              value: pacing,
              values: const ['Slow', 'Medium', 'Fast'],
              onChanged: onPacingChanged,
            ),
            _ChoiceField(
              width: itemWidth,
              label: 'Quality',
              value: quality,
              values: const ['Draft', 'Standard', 'High'],
              onChanged: onQualityChanged,
            ),
            SizedBox(
              width: constraints.maxWidth,
              child: TextField(
                controller: negativeController,
                decoration: const InputDecoration(
                  labelText: 'Negative prompt optional',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.width,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final double width;
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : values.first,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(item)),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _ReferencesRow extends StatelessWidget {
  const _ReferencesRow({
    required this.references,
    required this.onAdd,
    required this.onClear,
  });

  final List<String> references;
  final VoidCallback onAdd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add reference'),
        ),
        if (references.isNotEmpty)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_all_rounded),
            label: const Text('Clear references'),
          ),
        for (final reference in references)
          Chip(label: Text(reference), visualDensity: VisualDensity.compact),
      ],
    );
  }
}

class _ShotPlanView extends StatelessWidget {
  const _ShotPlanView({required this.shots});

  final List<_VideoShot> shots;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.view_timeline_outlined,
          title: 'Кадры сцены',
          subtitle:
              'План кадров помогает собрать более точный prompt для Kling / Runway / Seedance / других video tools.',
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 700
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final shot in shots) _ShotCard(width: width, shot: shot),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ShotCard extends StatelessWidget {
  const _ShotCard({required this.width, required this.shot});

  final double width;
  final _VideoShot shot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Кадр ${shot.number} — ${shot.duration}',
            style: const TextStyle(
              color: Color(0xFFFFD29B),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          _ShotLine(label: 'Действие', value: shot.action),
          _ShotLine(label: 'Камера', value: shot.cameraMovement),
          _ShotLine(label: 'Крупность', value: shot.framing),
          _ShotLine(label: 'Темп', value: shot.pacing),
          _ShotLine(label: 'Эмоция', value: shot.emotion),
          _ShotLine(label: 'Переход', value: shot.transition),
          _ShotLine(label: 'Звук', value: shot.soundNote),
        ],
      ),
    );
  }
}

class _ShotLine extends StatelessWidget {
  const _ShotLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF8B97A8),
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Color(0xFFE8EEF8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposedPromptCard extends StatelessWidget {
  const _ComposedPromptCard({
    required this.prompt,
    required this.onCopy,
    required this.onPrepare,
  });

  final String prompt;
  final VoidCallback onCopy;
  final VoidCallback onPrepare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xB80B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.integration_instructions_outlined,
            title: 'Composed production prompt',
            subtitle:
                'Итоговый prompt с настройками, negative prompt и планом кадров.',
          ),
          const SizedBox(height: 8),
          SelectableText(
            prompt,
            style: const TextStyle(color: Color(0xFFE8EEF8), height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onPrepare,
                icon: const Icon(Icons.send_to_mobile_rounded),
                label: const Text('Подготовить prompt для генерации'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VideoProviderPanel extends StatelessWidget {
  const _VideoProviderPanel({
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
          const _PanelTitle(
            icon: Icons.route_rounded,
            title: 'Как запустить',
            subtitle:
                'Пока генерация работает через выбранный сервис: скопируйте prompt и откройте сайт провайдера. API/локальный запуск подключим отдельным этапом.',
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
            decoration: const InputDecoration(
              labelText: 'Выбранный video provider',
            ),
            items: [
              for (final provider in providers)
                DropdownMenuItem(
                  value: provider.id,
                  child: Text(
                    '${provider.name} · ${_typeLabel(provider.type)}',
                  ),
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
                onPressed: selectedProvider.launchUrl == null ? null : onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть сайт'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать prompt'),
              ),
              FilledButton.icon(
                onPressed: onPrepare,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Подготовить для сервиса'),
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
                        SizedBox(
                          width: 420,
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

class ChatPromptNotice extends StatelessWidget {
  const ChatPromptNotice({super.key});

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
