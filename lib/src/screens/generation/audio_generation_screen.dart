import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ai_operator_app.dart';
import '../../data/seed_browser_ai_tools.dart';
import '../../models/browser_ai_tool.dart';
import '../../models/execution_job.dart';
import '../../services/ollama_prompt_brain_service.dart';
import '../../services/provider_executor.dart';
import '../../widgets/current_session_strip.dart';

enum _AudioMode { music, voice, soundDesign }

extension _AudioModeLabel on _AudioMode {
  String get label {
    return switch (this) {
      _AudioMode.music => 'Music',
      _AudioMode.voice => 'Voice',
      _AudioMode.soundDesign => 'Sound Design',
    };
  }
}

class AudioGenerationScreen extends StatefulWidget {
  const AudioGenerationScreen({super.key});

  @override
  State<AudioGenerationScreen> createState() => _AudioGenerationScreenState();
}

class _AudioGenerationScreenState extends State<AudioGenerationScreen> {
  static final List<_AudioHistoryItem> _history = <_AudioHistoryItem>[];

  final _promptController = TextEditingController();
  final _negativeController = TextEditingController();
  final _referenceController = TextEditingController();
  final _scriptController = TextEditingController();

  _AudioMode _mode = _AudioMode.music;
  late BrowserAiTool _provider;
  bool _runtimeWorkspaceOpened = false;

  String _genre = 'Cinematic pop';
  String _mood = 'Emotional';
  String _tempo = 'Medium';
  String _musicDuration = '30s';
  String _vocals = 'Instrumental';
  String _structure = 'Intro / verse / chorus';

  String _voiceType = 'Warm narrator';
  String _emotion = 'Confident';
  String _language = 'Russian';
  String _pacing = 'Medium';
  String _voiceStyle = 'Narration';

  String _soundType = 'Atmosphere';
  String _environment = 'Night city';
  String _intensity = 'Medium';
  String _soundDuration = '10s';
  String _texture = 'Airy';
  String _useCase = 'Video';

  List<BrowserAiTool> get _audioProviders => browserAiTools
      .where((tool) => tool.category == BrowserAiCategory.audio)
      .toList(growable: false);

  String get _prompt => _promptController.text.trim();
  String get _negativePrompt => _negativeController.text.trim();
  String get _referenceNote => _referenceController.text.trim();
  String get _script => _scriptController.text.trim();

  String get _composedPrompt {
    final base = _prompt.isEmpty
        ? 'Audio idea is not described yet.'
        : _prompt;
    final modeBlock = switch (_mode) {
      _AudioMode.music =>
        'Mode: music. Genre: $_genre. Mood: $_mood. Tempo: $_tempo. '
            'Duration: $_musicDuration. Vocals: $_vocals. '
            'Structure: $_structure.'
            '${_referenceNote.isEmpty ? '' : ' Reference note: $_referenceNote.'}',
      _AudioMode.voice =>
        'Mode: voice. Voice type: $_voiceType. Emotion: $_emotion. '
            'Language: $_language. Pacing: $_pacing. Output style: $_voiceStyle.'
            '${_script.isEmpty ? '' : ' Script: $_script.'}',
      _AudioMode.soundDesign =>
        'Mode: sound design. Sound type: $_soundType. '
            'Environment: $_environment. Intensity: $_intensity. '
            'Duration: $_soundDuration. Texture: $_texture. Use case: $_useCase.',
    };
    final negative = _negativePrompt.isEmpty
        ? ''
        : '\nNegative prompt: $_negativePrompt.';
    return '$base\n\n$modeBlock\nExecution note: prepare this prompt for an external audio service. FLUTEN does not generate audio internally yet.$negative';
  }

  @override
  void initState() {
    super.initState();
    _provider = _audioProviders.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_runtimeWorkspaceOpened) {
      _runtimeWorkspaceOpened = true;
      unawaited(FlutenRuntimeScope.read(context).updateCurrentWorkspace('audio'));
      unawaited(
        FlutenRuntimeScope.read(
          context,
        ).setActiveProvider(_provider.id, route: _provider.executionMode.name),
      );
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _negativeController.dispose();
    _referenceController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.25,
          colors: [Color(0xFF101821), Color(0xFF050609)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1040;
          final left = _LeftPanel(
            mode: _mode,
            promptController: _promptController,
            negativeController: _negativeController,
            referenceController: _referenceController,
            scriptController: _scriptController,
            genre: _genre,
            mood: _mood,
            tempo: _tempo,
            musicDuration: _musicDuration,
            vocals: _vocals,
            structure: _structure,
            voiceType: _voiceType,
            emotion: _emotion,
            language: _language,
            pacing: _pacing,
            voiceStyle: _voiceStyle,
            soundType: _soundType,
            environment: _environment,
            intensity: _intensity,
            soundDuration: _soundDuration,
            texture: _texture,
            useCase: _useCase,
            onModeChanged: (value) => setState(() => _mode = value),
            onGenreChanged: (value) => setState(() => _genre = value),
            onMoodChanged: (value) => setState(() => _mood = value),
            onTempoChanged: (value) => setState(() => _tempo = value),
            onMusicDurationChanged: (value) =>
                setState(() => _musicDuration = value),
            onVocalsChanged: (value) => setState(() => _vocals = value),
            onStructureChanged: (value) => setState(() => _structure = value),
            onVoiceTypeChanged: (value) => setState(() => _voiceType = value),
            onEmotionChanged: (value) => setState(() => _emotion = value),
            onLanguageChanged: (value) => setState(() => _language = value),
            onPacingChanged: (value) => setState(() => _pacing = value),
            onVoiceStyleChanged: (value) => setState(() => _voiceStyle = value),
            onSoundTypeChanged: (value) => setState(() => _soundType = value),
            onEnvironmentChanged: (value) =>
                setState(() => _environment = value),
            onIntensityChanged: (value) => setState(() => _intensity = value),
            onSoundDurationChanged: (value) =>
                setState(() => _soundDuration = value),
            onTextureChanged: (value) => setState(() => _texture = value),
            onUseCaseChanged: (value) => setState(() => _useCase = value),
            onImprove: _improvePrompt,
            onPrepare: _preparePrompt,
            onCopy: _copyPrompt,
            onOpen: _openProvider,
            onClear: _clearPrompt,
          );
          final center = _AudioWorkspace(
            mode: _mode,
            prompt: _prompt,
            composedPrompt: _composedPrompt,
            provider: _provider,
            onCopy: _copyPrompt,
            onPrepare: _preparePrompt,
            onOpen: _openProvider,
          );
          final right = _RightPanel(
            providers: _audioProviders,
            selectedProvider: _provider,
            history: _history,
            onProviderChanged: _selectProvider,
            onCopy: _copyPrompt,
            onPrepare: _preparePrompt,
            onOpen: _openProvider,
          );

          if (compact) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
              children: [
                const _AudioHeader(),
                const SizedBox(height: 12),
                const CurrentSessionStrip(),
                const SizedBox(height: 12),
                left,
                const SizedBox(height: 12),
                SizedBox(height: 560, child: center),
                const SizedBox(height: 12),
                right,
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AudioHeader(),
                const SizedBox(height: 14),
                const CurrentSessionStrip(),
                const SizedBox(height: 14),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 360, child: left),
                      const SizedBox(width: 12),
                      Expanded(child: center),
                      const SizedBox(width: 12),
                      SizedBox(width: 330, child: right),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectProvider(String id) {
    final provider = _audioProviders.firstWhere(
      (tool) => tool.id == id,
      orElse: () => _audioProviders.first,
    );
    setState(() => _provider = provider);
    unawaited(
      FlutenRuntimeScope.read(
        context,
      ).setActiveProvider(provider.id, route: provider.executionMode.name),
    );
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'audio',
        title: 'Audio provider selected',
        detail: provider.name,
      ),
    );
    _showMessage('${provider.name}: выбран audio-сервис.');
  }

  Future<void> _improvePrompt() async {
    if (_prompt.isEmpty) {
      _showMessage('Сначала опиши трек, голос или звук.');
      return;
    }
    final fallback = switch (_mode) {
      _AudioMode.music =>
        'Production music prompt: $_prompt. Build a $_genre track with $_mood mood, $_tempo tempo, $_vocals vocals, $_structure structure, clean mix, memorable hook, clear emotional rise, duration $_musicDuration.',
      _AudioMode.voice =>
        'Production voice prompt: $_prompt. Use $_voiceType voice, $_emotion emotion, $_language language, $_pacing pacing, $_voiceStyle delivery, clean articulation, natural pauses, no synthetic harshness.',
      _AudioMode.soundDesign =>
        'Production sound design prompt: $_prompt. Create $_soundType for $_environment, $_intensity intensity, $_texture texture, designed for $_useCase, duration $_soundDuration, clean start and controlled tail.',
    };
    final instruction = '''
You are FLUTEN Audio Engine. Improve this audio generation prompt.
Keep the user's idea intact and make it production-ready. Do not claim audio generation.

Prompt:
$_prompt

Mode: ${_mode.label}
Music controls: genre $_genre, mood $_mood, tempo $_tempo, duration $_musicDuration, vocals $_vocals, structure $_structure.
Voice controls: type $_voiceType, emotion $_emotion, language $_language, pacing $_pacing, style $_voiceStyle.
Sound design controls: type $_soundType, environment $_environment, intensity $_intensity, duration $_soundDuration, texture $_texture, use case $_useCase.
''';
    final result = await const OllamaPromptBrainService().improve(
      settings: AppSettingsScope.of(context),
      workspace: ExecutionJobWorkspace.audio,
      source: _prompt,
      instruction: instruction,
      fallback: fallback,
      capability: 'audioPromptImprove',
    );
    if (!mounted) return;
    final improved = result.text;
    final runtime = FlutenRuntimeScope.read(context);
    setState(() => _promptController.text = improved);
    await runtime.setActivePromptDraft(improved);
    await runtime.addEvent(
      type: 'audio',
      title: result.usedOllama
          ? 'Audio prompt improved through Ollama'
          : 'Fallback template used',
      detail: result.message,
    );
    _addHistory('Prompt improved', improved);
    _showMessage(result.message);
  }

  Future<void> _preparePrompt() async {
    if (_prompt.isEmpty) {
      _showMessage('Сначала опиши трек, голос или звук.');
      return;
    }
    final prompt = _composedPrompt;
    final job = await const ProviderExecutionService().prepare(
      workspace: ExecutionJobWorkspace.audio,
      provider: ExecutionProviderRef.fromBrowserTool(_provider),
      capability: _mode.name,
      inputPrompt: _prompt,
      composedPrompt: prompt,
      settings: AppSettingsScope.of(context),
    );
    if (!mounted) return;
    await _recordExecutionJob(job);
    _addHistory(job.status.label, prompt);
    _showMessage(_messageForExecutionJob(job));
  }

  Future<void> _recordExecutionJob(ExecutionJob job) async {
    await FlutenRuntimeScope.read(context).addGenerationJob(
      workspaceType: job.workspace.name,
      routeType: job.executionMode.name,
      prompt: job.composedPrompt,
      status: job.status.name,
      providerId: job.providerId,
      resultLabel: '${job.providerName}: ${job.status.label}',
      resultUrl: job.metadata['url'],
    );
  }

  String _messageForExecutionJob(ExecutionJob job) {
    return switch (job.status) {
      ExecutionJobStatus.requiresApiKey => 'Нужен API-ключ ${job.providerName}.',
      ExecutionJobStatus.localUnavailable =>
        'Локальная модель ${job.providerName} не подключена.',
      ExecutionJobStatus.manualOnly =>
        'Prompt подготовлен и скопирован. Вставьте его в ${job.providerName} вручную.',
      ExecutionJobStatus.prepared =>
        'Prompt подготовлен. Откройте ${job.providerName} и вставьте его вручную.',
      ExecutionJobStatus.failed => job.errorMessage ?? 'Execution не выполнен.',
      _ => 'Задача добавлена в очередь подготовки.',
    };
  }

  Future<void> _copyPrompt() async {
    if (_prompt.isEmpty) {
      _showMessage('Сначала опиши трек, голос или звук.');
      return;
    }
    final prompt = _composedPrompt;
    final runtime = FlutenRuntimeScope.read(context);
    await Clipboard.setData(ClipboardData(text: prompt));
    await runtime.setActivePromptDraft(prompt);
    await runtime.addEvent(
      type: 'audio',
      title: 'Audio prompt copied',
      detail: _provider.name,
    );
    _addHistory('Prompt copied', prompt);
    _showMessage('Prompt скопирован.');
  }

  Future<void> _openProvider() async {
    final prompt = _prompt.isEmpty ? _provider.url : _composedPrompt;
    final runtime = FlutenRuntimeScope.read(context);
    final job = await const ProviderExecutionService().start(
      workspace: ExecutionJobWorkspace.audio,
      provider: ExecutionProviderRef.fromBrowserTool(_provider),
      capability: _mode.name,
      inputPrompt: _prompt,
      composedPrompt: prompt,
      settings: AppSettingsScope.of(context),
    );
    if (!mounted) return;
    await _recordExecutionJob(job);
    await runtime.addEvent(
      type: 'audio',
      title: 'Audio provider site opened',
      detail: _provider.name,
    );
    _addHistory(job.status.label, prompt);
    _showMessage(_messageForExecutionJob(job));
  }

  void _clearPrompt() {
    setState(() {
      _promptController.clear();
      _negativeController.clear();
      _referenceController.clear();
      _scriptController.clear();
    });
    _showMessage('Audio prompt очищен.');
  }

  void _addHistory(String title, String detail) {
    setState(() {
      _history.insert(
        0,
        _AudioHistoryItem(
          title: title,
          detail: _preview(detail),
          provider: _provider.name,
          createdAt: DateTime.now(),
        ),
      );
      if (_history.length > 16) _history.removeRange(16, _history.length);
    });
  }

  String _preview(String value) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= 120) return clean;
    return '${clean.substring(0, 120)}...';
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _AudioHeader extends StatelessWidget {
  const _AudioHeader();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F7F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.graphic_eq_rounded, color: Colors.black),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Studio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Music, voice and sound design prompt workspace. No internal audio generation yet.',
                  style: TextStyle(color: Color(0xFFA7B1C1), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.mode,
    required this.promptController,
    required this.negativeController,
    required this.referenceController,
    required this.scriptController,
    required this.genre,
    required this.mood,
    required this.tempo,
    required this.musicDuration,
    required this.vocals,
    required this.structure,
    required this.voiceType,
    required this.emotion,
    required this.language,
    required this.pacing,
    required this.voiceStyle,
    required this.soundType,
    required this.environment,
    required this.intensity,
    required this.soundDuration,
    required this.texture,
    required this.useCase,
    required this.onModeChanged,
    required this.onGenreChanged,
    required this.onMoodChanged,
    required this.onTempoChanged,
    required this.onMusicDurationChanged,
    required this.onVocalsChanged,
    required this.onStructureChanged,
    required this.onVoiceTypeChanged,
    required this.onEmotionChanged,
    required this.onLanguageChanged,
    required this.onPacingChanged,
    required this.onVoiceStyleChanged,
    required this.onSoundTypeChanged,
    required this.onEnvironmentChanged,
    required this.onIntensityChanged,
    required this.onSoundDurationChanged,
    required this.onTextureChanged,
    required this.onUseCaseChanged,
    required this.onImprove,
    required this.onPrepare,
    required this.onCopy,
    required this.onOpen,
    required this.onClear,
  });

  final _AudioMode mode;
  final TextEditingController promptController;
  final TextEditingController negativeController;
  final TextEditingController referenceController;
  final TextEditingController scriptController;
  final String genre;
  final String mood;
  final String tempo;
  final String musicDuration;
  final String vocals;
  final String structure;
  final String voiceType;
  final String emotion;
  final String language;
  final String pacing;
  final String voiceStyle;
  final String soundType;
  final String environment;
  final String intensity;
  final String soundDuration;
  final String texture;
  final String useCase;
  final ValueChanged<_AudioMode> onModeChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onMoodChanged;
  final ValueChanged<String> onTempoChanged;
  final ValueChanged<String> onMusicDurationChanged;
  final ValueChanged<String> onVocalsChanged;
  final ValueChanged<String> onStructureChanged;
  final ValueChanged<String> onVoiceTypeChanged;
  final ValueChanged<String> onEmotionChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onPacingChanged;
  final ValueChanged<String> onVoiceStyleChanged;
  final ValueChanged<String> onSoundTypeChanged;
  final ValueChanged<String> onEnvironmentChanged;
  final ValueChanged<String> onIntensityChanged;
  final ValueChanged<String> onSoundDurationChanged;
  final ValueChanged<String> onTextureChanged;
  final ValueChanged<String> onUseCaseChanged;
  final VoidCallback onImprove;
  final VoidCallback onPrepare;
  final VoidCallback onCopy;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: ListView(
        children: [
          const _PanelTitle('Prompt composer'),
          const SizedBox(height: 10),
          SegmentedButton<_AudioMode>(
            segments: [
              for (final item in _AudioMode.values)
                ButtonSegment(value: item, label: Text(item.label)),
            ],
            selected: {mode},
            onSelectionChanged: (value) => onModeChanged(value.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: promptController,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Audio prompt',
              helperText: 'Опиши трек, голос или звук.',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 12),
          _ModeControls(
            mode: mode,
            referenceController: referenceController,
            scriptController: scriptController,
            genre: genre,
            mood: mood,
            tempo: tempo,
            musicDuration: musicDuration,
            vocals: vocals,
            structure: structure,
            voiceType: voiceType,
            emotion: emotion,
            language: language,
            pacing: pacing,
            voiceStyle: voiceStyle,
            soundType: soundType,
            environment: environment,
            intensity: intensity,
            soundDuration: soundDuration,
            texture: texture,
            useCase: useCase,
            onGenreChanged: onGenreChanged,
            onMoodChanged: onMoodChanged,
            onTempoChanged: onTempoChanged,
            onMusicDurationChanged: onMusicDurationChanged,
            onVocalsChanged: onVocalsChanged,
            onStructureChanged: onStructureChanged,
            onVoiceTypeChanged: onVoiceTypeChanged,
            onEmotionChanged: onEmotionChanged,
            onLanguageChanged: onLanguageChanged,
            onPacingChanged: onPacingChanged,
            onVoiceStyleChanged: onVoiceStyleChanged,
            onSoundTypeChanged: onSoundTypeChanged,
            onEnvironmentChanged: onEnvironmentChanged,
            onIntensityChanged: onIntensityChanged,
            onSoundDurationChanged: onSoundDurationChanged,
            onTextureChanged: onTextureChanged,
            onUseCaseChanged: onUseCaseChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: negativeController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Negative prompt',
              helperText: 'Что исключить: noise, harshness, artifacts.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Это не генерация аудио. FLUTEN локально собирает prompt для внешнего сервиса.',
            style: TextStyle(color: Color(0xFF9AA6B8), height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onPrepare,
                icon: const Icon(Icons.playlist_add_check_rounded),
                label: const Text('Подготовить prompt для audio-сервиса'),
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

class _ModeControls extends StatelessWidget {
  const _ModeControls({
    required this.mode,
    required this.referenceController,
    required this.scriptController,
    required this.genre,
    required this.mood,
    required this.tempo,
    required this.musicDuration,
    required this.vocals,
    required this.structure,
    required this.voiceType,
    required this.emotion,
    required this.language,
    required this.pacing,
    required this.voiceStyle,
    required this.soundType,
    required this.environment,
    required this.intensity,
    required this.soundDuration,
    required this.texture,
    required this.useCase,
    required this.onGenreChanged,
    required this.onMoodChanged,
    required this.onTempoChanged,
    required this.onMusicDurationChanged,
    required this.onVocalsChanged,
    required this.onStructureChanged,
    required this.onVoiceTypeChanged,
    required this.onEmotionChanged,
    required this.onLanguageChanged,
    required this.onPacingChanged,
    required this.onVoiceStyleChanged,
    required this.onSoundTypeChanged,
    required this.onEnvironmentChanged,
    required this.onIntensityChanged,
    required this.onSoundDurationChanged,
    required this.onTextureChanged,
    required this.onUseCaseChanged,
  });

  final _AudioMode mode;
  final TextEditingController referenceController;
  final TextEditingController scriptController;
  final String genre;
  final String mood;
  final String tempo;
  final String musicDuration;
  final String vocals;
  final String structure;
  final String voiceType;
  final String emotion;
  final String language;
  final String pacing;
  final String voiceStyle;
  final String soundType;
  final String environment;
  final String intensity;
  final String soundDuration;
  final String texture;
  final String useCase;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onMoodChanged;
  final ValueChanged<String> onTempoChanged;
  final ValueChanged<String> onMusicDurationChanged;
  final ValueChanged<String> onVocalsChanged;
  final ValueChanged<String> onStructureChanged;
  final ValueChanged<String> onVoiceTypeChanged;
  final ValueChanged<String> onEmotionChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onPacingChanged;
  final ValueChanged<String> onVoiceStyleChanged;
  final ValueChanged<String> onSoundTypeChanged;
  final ValueChanged<String> onEnvironmentChanged;
  final ValueChanged<String> onIntensityChanged;
  final ValueChanged<String> onSoundDurationChanged;
  final ValueChanged<String> onTextureChanged;
  final ValueChanged<String> onUseCaseChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: switch (mode) {
        _AudioMode.music => [
          _ChoiceField(
            label: 'Genre',
            value: genre,
            options: const [
              'Cinematic pop',
              'Electronic',
              'Hip hop',
              'Ambient',
              'Orchestral',
              'Rock',
            ],
            onChanged: onGenreChanged,
          ),
          _ChoiceField(
            label: 'Mood',
            value: mood,
            options: const ['Emotional', 'Dark', 'Bright', 'Epic', 'Intimate'],
            onChanged: onMoodChanged,
          ),
          _ChoiceField(
            label: 'Tempo',
            value: tempo,
            options: const ['Slow', 'Medium', 'Fast'],
            onChanged: onTempoChanged,
          ),
          _ChoiceField(
            label: 'Duration',
            value: musicDuration,
            options: const ['15s', '30s', '60s', '90s'],
            onChanged: onMusicDurationChanged,
          ),
          _ChoiceField(
            label: 'Vocals',
            value: vocals,
            options: const [
              'Instrumental',
              'Male vocal',
              'Female vocal',
              'Choir',
              'Rap',
              'Spoken',
            ],
            onChanged: onVocalsChanged,
          ),
          _ChoiceField(
            label: 'Structure',
            value: structure,
            options: const [
              'Intro / verse / chorus',
              'Intro / drop / outro',
              'Verse / chorus / outro',
              'Loop',
            ],
            onChanged: onStructureChanged,
          ),
          _SmallInput(
            controller: referenceController,
            label: 'Reference note',
            hint: 'Mood, instruments, mix direction.',
          ),
        ],
        _AudioMode.voice => [
          _ChoiceField(
            label: 'Voice type',
            value: voiceType,
            options: const [
              'Warm narrator',
              'Clean announcer',
              'Character voice',
              'Soft documentary',
            ],
            onChanged: onVoiceTypeChanged,
          ),
          _ChoiceField(
            label: 'Emotion',
            value: emotion,
            options: const ['Confident', 'Calm', 'Excited', 'Dramatic'],
            onChanged: onEmotionChanged,
          ),
          _ChoiceField(
            label: 'Language',
            value: language,
            options: const ['Russian', 'English', 'Spanish', 'German'],
            onChanged: onLanguageChanged,
          ),
          _ChoiceField(
            label: 'Pacing',
            value: pacing,
            options: const ['Slow', 'Medium', 'Fast'],
            onChanged: onPacingChanged,
          ),
          _ChoiceField(
            label: 'Output style',
            value: voiceStyle,
            options: const ['Narration', 'Ad', 'Dialogue', 'Character'],
            onChanged: onVoiceStyleChanged,
          ),
          _SmallInput(
            controller: scriptController,
            label: 'Script text',
            hint: 'Voiceover or dialogue text.',
            minLines: 3,
          ),
        ],
        _AudioMode.soundDesign => [
          _ChoiceField(
            label: 'Sound type',
            value: soundType,
            options: const ['Atmosphere', 'Hit', 'Riser', 'Transition', 'Foley'],
            onChanged: onSoundTypeChanged,
          ),
          _ChoiceField(
            label: 'Environment',
            value: environment,
            options: const ['Night city', 'Studio', 'Forest', 'Space', 'Room'],
            onChanged: onEnvironmentChanged,
          ),
          _ChoiceField(
            label: 'Intensity',
            value: intensity,
            options: const ['Low', 'Medium', 'High'],
            onChanged: onIntensityChanged,
          ),
          _ChoiceField(
            label: 'Duration',
            value: soundDuration,
            options: const ['3s', '6s', '10s', '30s'],
            onChanged: onSoundDurationChanged,
          ),
          _ChoiceField(
            label: 'Texture',
            value: texture,
            options: const ['Airy', 'Metallic', 'Organic', 'Glitch', 'Warm'],
            onChanged: onTextureChanged,
          ),
          _ChoiceField(
            label: 'Use case',
            value: useCase,
            options: const ['Video', 'Game', 'Transition', 'Ambient'],
            onChanged: onUseCaseChanged,
          ),
        ],
      },
    );
  }
}

class _AudioWorkspace extends StatelessWidget {
  const _AudioWorkspace({
    required this.mode,
    required this.prompt,
    required this.composedPrompt,
    required this.provider,
    required this.onCopy,
    required this.onPrepare,
    required this.onOpen,
  });

  final _AudioMode mode;
  final String prompt;
  final String composedPrompt;
  final BrowserAiTool provider;
  final VoidCallback onCopy;
  final VoidCallback onPrepare;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('Audio workspace'),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x990B0F16),
                border: Border.all(color: const Color(0x24FFFFFF)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniPill(mode.label),
                      _MiniPill(provider.name),
                      _MiniPill(provider.executionMode.label),
                    ],
                  ),
                  const Spacer(),
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.multitrack_audio_rounded,
                          color: Color(0xFF556174),
                          size: 74,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Здесь будет результат аудио',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Генерация внутри FLUTEN будет подключена отдельным этапом.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF9AA6B8),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    prompt.isEmpty
                        ? 'Собери music/voice/sound prompt и открой audio-сервис.'
                        : 'Prompt готовится для ${provider.name}.',
                    style: const TextStyle(color: Color(0xFFA7B1C1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _GlassPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelTitle('Composed audio prompt'),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 190),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      composedPrompt,
                      style: const TextStyle(
                        color: Color(0xFFE8EEF8),
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: onPrepare,
                      icon: const Icon(Icons.playlist_add_check_rounded),
                      label: const Text('Подготовить для сервиса'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Скопировать prompt'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Открыть сайт'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.providers,
    required this.selectedProvider,
    required this.history,
    required this.onProviderChanged,
    required this.onCopy,
    required this.onPrepare,
    required this.onOpen,
  });

  final List<BrowserAiTool> providers;
  final BrowserAiTool selectedProvider;
  final List<_AudioHistoryItem> history;
  final ValueChanged<String> onProviderChanged;
  final VoidCallback onCopy;
  final VoidCallback onPrepare;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: ListView(
        children: [
          const _PanelTitle('Audio providers'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: selectedProvider.id,
            decoration: const InputDecoration(labelText: 'Selected provider'),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MiniPill(selectedProvider.category.label),
              _MiniPill(selectedProvider.executionMode.label),
              _MiniPill(selectedProvider.status.label),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            selectedProvider.description,
            style: const TextStyle(color: Color(0xFF9AA6B8), height: 1.35),
          ),
          const SizedBox(height: 8),
          SelectableText(
            selectedProvider.url,
            style: const TextStyle(
              color: Color(0xFF67E8F9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть сайт'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onPrepare,
                icon: const Icon(Icons.input_rounded),
                label: const Text('Подготовить для сервиса'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _PanelTitle('Audio history'),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const Text(
              'Здесь появятся подготовленные audio prompts, copy/open events и ручные handoff-действия. Реальных аудио-рендеров пока нет.',
              style: TextStyle(color: Color(0xFF9AA6B8), height: 1.4),
            )
          else
            for (final item in history) _HistoryTile(item: item),
        ],
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}

class _SmallInput extends StatelessWidget {
  const _SmallInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.minLines = 2,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines + 2,
        decoration: InputDecoration(
          labelText: label,
          helperText: hint,
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final _AudioHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final time =
        '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Color(0xFF7B8797), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            item.provider,
            style: const TextStyle(color: Color(0xFF67E8F9), fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            item.detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9AA6B8), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xA6080B10),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE8EEF8),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AudioHistoryItem {
  const _AudioHistoryItem({
    required this.title,
    required this.detail,
    required this.provider,
    required this.createdAt,
  });

  final String title;
  final String detail;
  final String provider;
  final DateTime createdAt;
}
