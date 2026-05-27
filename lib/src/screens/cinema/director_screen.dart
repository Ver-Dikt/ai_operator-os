import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ai_operator_app.dart';
import '../../services/ollama_execution_service.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/current_session_strip.dart';
import '../../widgets/responsive_page.dart';

class DirectorScreen extends StatefulWidget {
  const DirectorScreen({super.key});

  @override
  State<DirectorScreen> createState() => _DirectorScreenState();
}

class _DirectorScreenState extends State<DirectorScreen> {
  final _idea = TextEditingController(
    text: 'luxury perfume ad in rainy night city',
  );
  final _mood = TextEditingController(text: 'sensual, mysterious, premium');
  final _product = TextEditingController();
  final _audience = TextEditingController();
  final _visualStyle = TextEditingController(
    text: 'neon noir, wet streets, soft reflections, cinematic closeups',
  );

  String _platform = 'Reels';
  String _duration = '15s';
  String _customDuration = '';
  String _pacing = 'medium';
  String _cameraEnergy = 'cinematic';
  String _format = 'ad';
  DirectorPlan? _plan;
  bool _improving = false;
  bool _runtimeOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_runtimeOpened) return;
    _runtimeOpened = true;
    unawaited(
      FlutenRuntimeScope.read(context).updateCurrentWorkspace('director'),
    );
  }

  @override
  void dispose() {
    _idea.dispose();
    _mood.dispose();
    _product.dispose();
    _audience.dispose();
    _visualStyle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      title: 'Cinema / Director',
      subtitle:
          'Director Engine MVP: idea -> concept -> shot plan -> production video prompt.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CurrentSessionStrip(),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;
              final inputPanel = _InputPanel(
                idea: _idea,
                mood: _mood,
                product: _product,
                audience: _audience,
                visualStyle: _visualStyle,
                platform: _platform,
                duration: _duration,
                pacing: _pacing,
                cameraEnergy: _cameraEnergy,
                format: _format,
                onPlatform: (value) => setState(() => _platform = value),
                onDuration: (value) => setState(() => _duration = value),
                onCustomDuration: (value) => _customDuration = value,
                onPacing: (value) => setState(() => _pacing = value),
                onCameraEnergy: (value) =>
                    setState(() => _cameraEnergy = value),
                onFormat: (value) => setState(() => _format = value),
                onUseSessionIdea: _useSessionIdea,
                onGenerate: _generatePlan,
              );
              final outputPanel = _plan == null
                  ? const _EmptyDirectorPlan()
                  : _DirectorPlanView(
                      plan: _plan!,
                      improving: _improving,
                      onCopy: _copyPrompt,
                      onSendVideo: _sendToVideoStudio,
                      onImprove: _improveWithOllama,
                    );
              if (compact) {
                return Column(
                  children: [
                    inputPanel,
                    const SizedBox(height: 12),
                    outputPanel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 410, child: inputPanel),
                  const SizedBox(width: 12),
                  Expanded(child: outputPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _useSessionIdea() {
    final session = FlutenRuntimeScope.read(context).getCurrentSession();
    final draft = session.activePromptDraft?.trim();
    if (draft == null || draft.isEmpty) {
      _showMessage('В текущей сессии пока нет активной идеи.');
      return;
    }
    setState(() => _idea.text = draft);
    _showMessage('Текущая идея из сессии загружена.');
  }

  void _generatePlan() {
    final source = _idea.text.trim();
    if (source.isEmpty) {
      _showMessage('Опишите идею или концепт для Director Engine.');
      return;
    }
    final plan = _buildDirectorPlan(source);
    setState(() => _plan = plan);
    final runtime = FlutenRuntimeScope.read(context);
    unawaited(runtime.setActivePromptDraft(plan.productionPrompt));
    unawaited(
      runtime.addAsset(
        type: 'text',
        title: 'Director plan: ${plan.hook}',
        description: plan.toText(),
        sourceProvider: 'director-engine-local',
      ),
    );
    unawaited(
      runtime.addEvent(
        type: 'director',
        title: 'Director plan generated',
        detail: plan.hook,
      ),
    );
  }

  DirectorPlan _buildDirectorPlan(String idea) {
    final duration = _duration == 'custom' && _customDuration.trim().isNotEmpty
        ? _customDuration.trim()
        : _duration;
    final product = _product.text.trim();
    final audience = _audience.text.trim();
    final mood = _mood.text.trim();
    final style = _visualStyle.text.trim();
    final productLine = product.isEmpty
        ? 'the hero object or emotion'
        : product;
    final audienceLine = audience.isEmpty
        ? 'attention-led short-form viewers'
        : audience;
    final shotCount = duration == '6s' || _format == 'single shot' ? 1 : 3;
    final shots = _buildShots(idea, productLine, shotCount, duration);
    final hook =
        'A precise first image: $productLine appears inside $idea before the viewer understands why it matters.';
    final core =
        '$_platform $_format built around $idea. The film sells emotion first, product second, using visual consistency and motivated camera language.';
    final emotionalArc =
        'Curiosity -> sensory attraction -> quiet desire -> final gesture that makes the scene feel intentional.';
    final cameraLogic = _cameraEnergy == 'stable'
        ? 'Mostly stable frames; movement is reserved for the emotional reveal.'
        : _cameraEnergy == 'aggressive'
        ? 'Fast energy is used only at transitions; the subject stays readable.'
        : 'Cinematic moves reveal depth, reflection, and intent instead of random motion.';
    final blocking =
        'Place the subject in layered depth. Let hands, gaze, product position, and foreground occlusion carry the story.';
    final pacing =
        'Editing time is stronger than editing space: hold the opening, accelerate only through the decision beat, then let the ending breathe.';
    final lighting =
        '${style.isEmpty ? 'cinematic practical light' : style}; mood: ${mood.isEmpty ? 'focused and premium' : mood}. Keep motivated highlights and readable shadows.';
    final sound =
        'Low atmospheric pulse, one tactile sound tied to the product/action, final soft hit on the gesture.';
    final finalGesture =
        'The character stops, reveals $productLine, and the reflected city light turns the object into the emotional answer.';
    final productionPrompt = _buildProductionPrompt(
      idea: idea,
      duration: duration,
      mood: mood,
      style: style,
      product: productLine,
      shots: shots,
      finalGesture: finalGesture,
    );
    return DirectorPlan(
      hook: hook,
      coreConcept: core,
      emotionalArc: emotionalArc,
      shots: shots,
      cameraLogic: cameraLogic,
      blockingNotes: blocking,
      pacingNotes: pacing,
      lightingMood: lighting,
      soundNotes: sound,
      finalGesture: finalGesture,
      productionPrompt: productionPrompt,
      platform: _platform,
      duration: duration,
      audience: audienceLine,
    );
  }

  List<DirectorShot> _buildShots(
    String idea,
    String product,
    int count,
    String duration,
  ) {
    if (count == 1) {
      return [
        DirectorShot(
          number: 1,
          duration: duration,
          description:
              'Single controlled shot of $idea where the subject moves from ambiguity into desire.',
          cameraMovement:
              'Slow push-in only after the emotional cue; stability carries tension.',
          lensFraming: '50mm cinematic medium closeup, deep foreground layer',
          emotion: 'curiosity becoming attraction',
          action: 'subject notices $product and makes one decisive gesture',
          transition: 'no cut; final hold',
          soundNote: 'rain texture, breath, subtle product sound',
        ),
      ];
    }
    return [
      DirectorShot(
        number: 1,
        duration: '0-${duration == '30s' ? '7' : '3'}s',
        description: 'Establish $idea with a clean, readable first image.',
        cameraMovement: 'Locked or almost locked frame; depth does the work.',
        lensFraming: 'wide-to-medium, foreground reflections',
        emotion: 'intrigue',
        action: 'subject enters the frame or product catches light',
        transition: 'match cut on movement or reflection',
        soundNote: 'atmosphere first, no musical clutter',
      ),
      DirectorShot(
        number: 2,
        duration: duration == '30s' ? '7-18s' : '3-10s',
        description:
            'Reveal the relationship between the subject and $product.',
        cameraMovement:
            'Motivated lateral slide or push as the decision forms.',
        lensFraming: 'medium closeup, hands/object/gaze in layered depth',
        emotion: 'desire and control',
        action: 'subject reaches, turns, or frames the product with intent',
        transition: 'cut on action, preserve direction',
        soundNote: 'tactile detail, soft rise',
      ),
      DirectorShot(
        number: 3,
        duration: duration == '30s' ? '18-30s' : '10-end',
        description:
            'Resolve the scene with a final gesture that reframes the idea.',
        cameraMovement: 'Hold the frame; let the gesture carry the ending.',
        lensFraming: 'close detail into hero frame',
        emotion: 'quiet confidence',
        action: 'final reveal of $product and emotional payoff',
        transition: 'final hold or clean logo-safe end frame',
        soundNote: 'single accent, then air',
      ),
    ];
  }

  String _buildProductionPrompt({
    required String idea,
    required String duration,
    required String mood,
    required String style,
    required String product,
    required List<DirectorShot> shots,
    required String finalGesture,
  }) {
    final shotText = shots
        .map(
          (shot) =>
              'Shot ${shot.number}: ${shot.description}; ${shot.cameraMovement}; ${shot.action}.',
        )
        .join(' ');
    return '''
Cinematic video prompt
Idea: $idea
Platform / format: $_platform, $_format, $duration
Visual style: ${style.isEmpty ? 'premium cinematic realism' : style}
Mood: ${mood.isEmpty ? 'focused, emotional, premium' : mood}
Pacing: $_pacing, with emotional rhythm controlling attention
Camera energy: $_cameraEnergy; camera movement only with dramatic reason
Blocking: subject, environment, and $product arranged in layered depth; blocking carries the meaning
Shot plan: $shotText
Lighting: motivated practical light, readable shadows, premium highlights
Continuity: keep subject, product, lens language, environment, and color consistent
Sound: atmospheric bed, tactile product/action detail, final soft accent
Final gesture: $finalGesture
Negative guidance: random zooms, chaotic camera, flat lighting, incoherent hands, noisy edits, generic stock look
''';
  }

  Future<void> _copyPrompt() async {
    final prompt = _plan?.productionPrompt;
    if (prompt == null) return;
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    _showMessage('Director production prompt copied.');
  }

  Future<void> _sendToVideoStudio() async {
    final plan = _plan;
    if (plan == null) return;
    AppSettingsScope.of(context).setVideoPromptDraft(plan.productionPrompt);
    await Clipboard.setData(ClipboardData(text: plan.productionPrompt));
    if (!mounted) return;
    final runtime = FlutenRuntimeScope.read(context);
    unawaited(runtime.setActivePromptDraft(plan.productionPrompt));
    unawaited(runtime.updateCurrentWorkspace('video'));
    unawaited(
      runtime.addEvent(
        type: 'director',
        title: 'Director plan sent to Video Studio',
        detail: plan.hook,
      ),
    );
    Navigator.of(context).pushNamed('/video');
  }

  Future<void> _improveWithOllama() async {
    final plan = _plan;
    if (plan == null) return;
    final settings = AppSettingsScope.of(context);
    setState(() => _improving = true);
    final result = await const OllamaExecutionService().generate(
      endpoint: settings.ollamaBaseUrl,
      model: settings.ollamaModel,
      prompt:
          'Improve this FLUTEN Director Plan. Keep the same structure, make camera logic, blocking, pacing, emotional arc, and final gesture stronger. Do not add fake API claims.\n\n${plan.toText()}',
    );
    if (!mounted) return;
    setState(() => _improving = false);
    if (!result.success || (result.response?.trim().isEmpty ?? true)) {
      _showMessage(
        'Можно улучшить через Ollama после подключения локальной модели.',
      );
      return;
    }
    final improved = plan.copyWith(productionPrompt: result.response!.trim());
    setState(() => _plan = improved);
    unawaited(
      FlutenRuntimeScope.read(
        context,
      ).setActivePromptDraft(improved.productionPrompt),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _InputPanel extends StatelessWidget {
  const _InputPanel({
    required this.idea,
    required this.mood,
    required this.product,
    required this.audience,
    required this.visualStyle,
    required this.platform,
    required this.duration,
    required this.pacing,
    required this.cameraEnergy,
    required this.format,
    required this.onPlatform,
    required this.onDuration,
    required this.onCustomDuration,
    required this.onPacing,
    required this.onCameraEnergy,
    required this.onFormat,
    required this.onUseSessionIdea,
    required this.onGenerate,
  });

  final TextEditingController idea;
  final TextEditingController mood;
  final TextEditingController product;
  final TextEditingController audience;
  final TextEditingController visualStyle;
  final String platform;
  final String duration;
  final String pacing;
  final String cameraEnergy;
  final String format;
  final ValueChanged<String> onPlatform;
  final ValueChanged<String> onDuration;
  final ValueChanged<String> onCustomDuration;
  final ValueChanged<String> onPacing;
  final ValueChanged<String> onCameraEnergy;
  final ValueChanged<String> onFormat;
  final VoidCallback onUseSessionIdea;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Director Inputs'),
          const SizedBox(height: 12),
          TextField(
            controller: idea,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Idea / concept',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 10),
          _ChoiceRow(
            label: 'Platform',
            value: platform,
            values: const ['TikTok', 'Reels', 'Shorts', 'Ad', 'Cinematic'],
            onChanged: onPlatform,
          ),
          _ChoiceRow(
            label: 'Duration',
            value: duration,
            values: const ['6s', '10s', '15s', '30s', 'custom'],
            onChanged: onDuration,
          ),
          if (duration == 'custom') ...[
            const SizedBox(height: 8),
            TextField(
              onChanged: onCustomDuration,
              decoration: const InputDecoration(labelText: 'Custom duration'),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: mood,
            decoration: const InputDecoration(labelText: 'Mood'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: visualStyle,
            decoration: const InputDecoration(labelText: 'Visual style'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: product,
            decoration: const InputDecoration(
              labelText: 'Product / brand optional',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: audience,
            decoration: const InputDecoration(labelText: 'Audience optional'),
          ),
          const SizedBox(height: 10),
          _ChoiceRow(
            label: 'Pacing',
            value: pacing,
            values: const ['slow', 'medium', 'fast'],
            onChanged: onPacing,
          ),
          _ChoiceRow(
            label: 'Camera energy',
            value: cameraEnergy,
            values: const ['stable', 'cinematic', 'aggressive'],
            onChanged: onCameraEnergy,
          ),
          _ChoiceRow(
            label: 'Format',
            value: format,
            values: const ['single shot', 'multi-shot', 'ad', 'UGC', 'trailer'],
            onChanged: onFormat,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onUseSessionIdea,
                icon: const Icon(Icons.history_rounded),
                label: const Text('Использовать текущую идею из сессии'),
              ),
              FilledButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.movie_creation_outlined),
                label: const Text('Собрать Director Plan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DirectorPlanView extends StatelessWidget {
  const _DirectorPlanView({
    required this.plan,
    required this.improving,
    required this.onCopy,
    required this.onSendVideo,
    required this.onImprove,
  });

  final DirectorPlan plan;
  final bool improving;
  final VoidCallback onCopy;
  final VoidCallback onSendVideo;
  final VoidCallback onImprove;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SectionTitle('Director Plan'),
              Chip(label: Text(plan.platform)),
              Chip(label: Text(plan.duration)),
              Chip(label: Text(plan.audience)),
            ],
          ),
          const SizedBox(height: 12),
          _PlanBlock('Hook', plan.hook),
          _PlanBlock('Core concept', plan.coreConcept),
          _PlanBlock('Emotional arc', plan.emotionalArc),
          _PlanBlock('Camera logic', plan.cameraLogic),
          _PlanBlock('Blocking notes', plan.blockingNotes),
          _PlanBlock('Pacing notes', plan.pacingNotes),
          _PlanBlock('Lighting / mood', plan.lightingMood),
          _PlanBlock('Sound notes', plan.soundNotes),
          _PlanBlock('Final gesture', plan.finalGesture),
          const SizedBox(height: 12),
          _SectionTitle('Storyboard / Shot List'),
          const SizedBox(height: 8),
          for (final shot in plan.shots) ...[
            _ShotCard(shot: shot),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          _PlanBlock('Production video prompt', plan.productionPrompt),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onSendVideo,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Отправить в Video Studio'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy prompt'),
              ),
              OutlinedButton.icon(
                onPressed: improving ? null : onImprove,
                icon: improving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Улучшить через Ollama'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyDirectorPlan extends StatelessWidget {
  const _EmptyDirectorPlan();

  @override
  Widget build(BuildContext context) {
    return const OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Director Engine'),
          SizedBox(height: 10),
          Text(
            'Enter an idea and generate a local cinematic plan. No API is required.',
            style: TextStyle(color: Color(0xFFA7B1C1), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B97A8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in values)
                ChoiceChip(
                  label: Text(item),
                  selected: value == item,
                  onSelected: (_) => onChanged(item),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanBlock extends StatelessWidget {
  const _PlanBlock(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          SelectableText(
            body,
            style: const TextStyle(color: Color(0xFFE8EEF8), height: 1.42),
          ),
        ],
      ),
    );
  }
}

class _ShotCard extends StatelessWidget {
  const _ShotCard({required this.shot});

  final DirectorShot shot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x22FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shot ${shot.number} · ${shot.duration}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(shot.description),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(label: Text(shot.cameraMovement)),
              Chip(label: Text(shot.lensFraming)),
              Chip(label: Text(shot.emotion)),
              Chip(label: Text(shot.transition)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Action: ${shot.action}'),
          Text('Sound: ${shot.soundNote}'),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    );
  }
}

class DirectorPlan {
  const DirectorPlan({
    required this.hook,
    required this.coreConcept,
    required this.emotionalArc,
    required this.shots,
    required this.cameraLogic,
    required this.blockingNotes,
    required this.pacingNotes,
    required this.lightingMood,
    required this.soundNotes,
    required this.finalGesture,
    required this.productionPrompt,
    required this.platform,
    required this.duration,
    required this.audience,
  });

  final String hook;
  final String coreConcept;
  final String emotionalArc;
  final List<DirectorShot> shots;
  final String cameraLogic;
  final String blockingNotes;
  final String pacingNotes;
  final String lightingMood;
  final String soundNotes;
  final String finalGesture;
  final String productionPrompt;
  final String platform;
  final String duration;
  final String audience;

  DirectorPlan copyWith({String? productionPrompt}) {
    return DirectorPlan(
      hook: hook,
      coreConcept: coreConcept,
      emotionalArc: emotionalArc,
      shots: shots,
      cameraLogic: cameraLogic,
      blockingNotes: blockingNotes,
      pacingNotes: pacingNotes,
      lightingMood: lightingMood,
      soundNotes: soundNotes,
      finalGesture: finalGesture,
      productionPrompt: productionPrompt ?? this.productionPrompt,
      platform: platform,
      duration: duration,
      audience: audience,
    );
  }

  String toText() {
    return '''
Hook: $hook
Core concept: $coreConcept
Emotional arc: $emotionalArc
Camera logic: $cameraLogic
Blocking notes: $blockingNotes
Pacing notes: $pacingNotes
Lighting / mood: $lightingMood
Sound notes: $soundNotes
Final gesture: $finalGesture
Production video prompt:
$productionPrompt
''';
  }
}

class DirectorShot {
  const DirectorShot({
    required this.number,
    required this.duration,
    required this.description,
    required this.cameraMovement,
    required this.lensFraming,
    required this.emotion,
    required this.action,
    required this.transition,
    required this.soundNote,
  });

  final int number;
  final String duration;
  final String description;
  final String cameraMovement;
  final String lensFraming;
  final String emotion;
  final String action;
  final String transition;
  final String soundNote;
}
