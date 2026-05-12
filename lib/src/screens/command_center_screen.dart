import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai_operator_app.dart';
import '../data/seed_free_credits.dart';
import '../models/ai_agent.dart';
import '../models/ai_tool.dart';
import '../models/routing_recommendation.dart';
import '../models/workflow_template.dart';
import '../services/graph_repository.dart';
import '../services/router_service.dart';
import '../services/url_service.dart';
import '../state/app_settings.dart';

enum _WorkMode { agents, text, design, video, audio, toolkit }

enum _ActiveEntity { none, workflow, agent, tool }

T? _firstOrNull<T>(List<T> items) => items.isEmpty ? null : items.first;

Future<void> _copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Скопировано в буфер')));
}

extension _WorkModeUi on _WorkMode {
  String get label {
    return switch (this) {
      _WorkMode.agents => 'GPT Агенты',
      _WorkMode.text => 'Текст',
      _WorkMode.design => 'Дизайн',
      _WorkMode.video => 'Видео',
      _WorkMode.audio => 'Аудио',
      _WorkMode.toolkit => 'Тул-кит',
    };
  }

  String get title {
    return switch (this) {
      _WorkMode.agents => 'Agent Workforce',
      _WorkMode.text => 'Text Operator',
      _WorkMode.design => 'Design Router',
      _WorkMode.video => 'Video Director',
      _WorkMode.audio => 'Audio Studio',
      _WorkMode.toolkit => 'AI Tool Router',
    };
  }

  String get description {
    return switch (this) {
      _WorkMode.agents =>
        'Запускай специализированных агентов и собирай рабочую команду под задачу.',
      _WorkMode.text =>
        'Собирай тексты, промпты, исследования и рабочие брифы в одном потоке.',
      _WorkMode.design =>
        'Выбирай визуальный стек, референсы и промпты для изображений и дизайна.',
      _WorkMode.video =>
        'Планируй AI-видео: сцены, кадры, инструменты, free/pro/local путь.',
      _WorkMode.audio =>
        'Готовь промо трека, озвучку, voiceover и аудио-пайплайн.',
      _WorkMode.toolkit =>
        'Маршрутизируй задачу по базе нейросетей, агентов и workflow.',
    };
  }

  IconData get icon {
    return switch (this) {
      _WorkMode.agents => Icons.smart_toy_outlined,
      _WorkMode.text => Icons.notes_rounded,
      _WorkMode.design => Icons.auto_awesome_mosaic_outlined,
      _WorkMode.video => Icons.movie_creation_outlined,
      _WorkMode.audio => Icons.graphic_eq_rounded,
      _WorkMode.toolkit => Icons.grid_view_rounded,
    };
  }
}

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key, required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  final TextEditingController _taskController = TextEditingController();
  _WorkMode _mode = _WorkMode.design;
  RoutingRecommendation? _recommendation;
  _ActiveEntity _activeEntity = _ActiveEntity.none;
  String? _activeEntityId;
  String _historyTab = 'все';
  String _model = 'Auto Router';
  String _aspect = '9:16';
  String _quality = 'Balanced';

  static const _quickGoals = <({String label, String task})>[
    (
      label: 'AI-видео',
      task: 'Сделать кинематографичное AI-видео для соцсетей',
    ),
    (label: 'Музыка', task: 'Сделать 10 Reels для музыкального трека'),
    (
      label: 'Фриланс',
      task: 'Найти AI-фриланс задачи и путь к первым клиентам',
    ),
    (label: 'Оживить фото', task: 'Оживить старые фото как услугу'),
    (
      label: 'Локализация',
      task: 'Локализовать видео: перевод, озвучка и субтитры',
    ),
    (
      label: 'Автоматизация',
      task: 'Построить n8n workflow для повторяющейся задачи',
    ),
  ];

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.25,
            colors: [Color(0xFF171820), Color(0xFF050608)],
          ),
        ),
        child: SafeArea(
          child: isWide
              ? _DesktopStation(
                  mode: _mode,
                  historyTab: _historyTab,
                  taskController: _taskController,
                  recommendation: _recommendation,
                  activeEntity: _activeEntity,
                  activeEntityId: _activeEntityId,
                  model: _model,
                  aspect: _aspect,
                  quality: _quality,
                  settings: settings,
                  onMode: (mode) => setState(() => _mode = mode),
                  onHistoryTab: (tab) => setState(() => _historyTab = tab),
                  onSubmit: _buildPlan,
                  onQuickGoal: _quickGoal,
                  onOpenWorkflow: _openWorkflow,
                  onOpenAgent: _openAgent,
                  onOpenTool: _openTool,
                  onModel: (value) => setState(() => _model = value),
                  onAspect: (value) => setState(() => _aspect = value),
                  onQuality: (value) => setState(() => _quality = value),
                  onReset: _resetParameters,
                  onNavigate: widget.onNavigate,
                )
              : _MobileStation(
                  mode: _mode,
                  taskController: _taskController,
                  recommendation: _recommendation,
                  activeEntity: _activeEntity,
                  activeEntityId: _activeEntityId,
                  model: _model,
                  aspect: _aspect,
                  quality: _quality,
                  settings: settings,
                  onMode: (mode) => setState(() => _mode = mode),
                  onSubmit: _buildPlan,
                  onQuickGoal: _quickGoal,
                  onOpenWorkflow: _openWorkflow,
                  onOpenAgent: _openAgent,
                  onOpenTool: _openTool,
                  onModel: (value) => setState(() => _model = value),
                  onAspect: (value) => setState(() => _aspect = value),
                  onQuality: (value) => setState(() => _quality = value),
                  onReset: _resetParameters,
                ),
        ),
      ),
    );
  }

  void _quickGoal(String task) {
    _taskController.text = task;
    _buildPlan();
  }

  void _buildPlan() {
    final task = _taskController.text.trim().isEmpty
        ? 'Собрать AI workflow'
        : _taskController.text.trim();
    setState(() {
      _recommendation = const RouterService().recommend(task);
      _activeEntity = _ActiveEntity.none;
      _activeEntityId = null;
    });
  }

  void _openWorkflow(String? id) {
    setState(() {
      _activeEntity = _ActiveEntity.workflow;
      _activeEntityId = id;
    });
  }

  void _openAgent(String? id) {
    setState(() {
      _activeEntity = _ActiveEntity.agent;
      _activeEntityId = id;
    });
  }

  void _openTool(String? id) {
    setState(() {
      _activeEntity = _ActiveEntity.tool;
      _activeEntityId = id;
    });
  }

  void _resetParameters() {
    setState(() {
      _model = 'Auto Router';
      _aspect = '9:16';
      _quality = 'Balanced';
    });
  }
}

class _DesktopStation extends StatelessWidget {
  const _DesktopStation({
    required this.mode,
    required this.historyTab,
    required this.taskController,
    required this.recommendation,
    required this.activeEntity,
    required this.activeEntityId,
    required this.model,
    required this.aspect,
    required this.quality,
    required this.settings,
    required this.onMode,
    required this.onHistoryTab,
    required this.onSubmit,
    required this.onQuickGoal,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onModel,
    required this.onAspect,
    required this.onQuality,
    required this.onReset,
    required this.onNavigate,
  });

  final _WorkMode mode;
  final String historyTab;
  final TextEditingController taskController;
  final RoutingRecommendation? recommendation;
  final _ActiveEntity activeEntity;
  final String? activeEntityId;
  final String model;
  final String aspect;
  final String quality;
  final AppSettings settings;
  final ValueChanged<_WorkMode> onMode;
  final ValueChanged<String> onHistoryTab;
  final VoidCallback onSubmit;
  final ValueChanged<String> onQuickGoal;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final ValueChanged<String> onModel;
  final ValueChanged<String> onAspect;
  final ValueChanged<String> onQuality;
  final VoidCallback onReset;
  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _TopBar(mode: mode, onMode: onMode),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(286, 18, 336, 118),
                child: _CenterStage(
                  mode: mode,
                  recommendation: recommendation,
                  activeEntity: activeEntity,
                  activeEntityId: activeEntityId,
                  onOpenWorkflow: onOpenWorkflow,
                  onOpenAgent: onOpenAgent,
                  onOpenTool: onOpenTool,
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 22,
          top: 72,
          bottom: 24,
          width: 236,
          child: _HistoryPanel(
            tab: historyTab,
            onTab: onHistoryTab,
            onNavigate: onNavigate,
            onOpenWorkflow: onOpenWorkflow,
            onOpenAgent: onOpenAgent,
            onOpenTool: onOpenTool,
          ),
        ),
        Positioned(
          right: 22,
          top: 72,
          bottom: 24,
          width: 286,
          child: _SettingsPanel(
            model: model,
            aspect: aspect,
            quality: quality,
            mode: mode,
            settings: settings,
            onModel: onModel,
            onAspect: onAspect,
            onQuality: onQuality,
            onReset: onReset,
            onOpenWorkflow: onOpenWorkflow,
          ),
        ),
        Positioned(
          left: 330,
          right: 380,
          bottom: 24,
          child: _PromptComposer(
            controller: taskController,
            onSubmit: onSubmit,
            onQuickGoal: onQuickGoal,
          ),
        ),
      ],
    );
  }
}

class _MobileStation extends StatelessWidget {
  const _MobileStation({
    required this.mode,
    required this.taskController,
    required this.recommendation,
    required this.activeEntity,
    required this.activeEntityId,
    required this.model,
    required this.aspect,
    required this.quality,
    required this.settings,
    required this.onMode,
    required this.onSubmit,
    required this.onQuickGoal,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onModel,
    required this.onAspect,
    required this.onQuality,
    required this.onReset,
  });

  final _WorkMode mode;
  final TextEditingController taskController;
  final RoutingRecommendation? recommendation;
  final _ActiveEntity activeEntity;
  final String? activeEntityId;
  final String model;
  final String aspect;
  final String quality;
  final AppSettings settings;
  final ValueChanged<_WorkMode> onMode;
  final VoidCallback onSubmit;
  final ValueChanged<String> onQuickGoal;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final ValueChanged<String> onModel;
  final ValueChanged<String> onAspect;
  final ValueChanged<String> onQuality;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
      children: [
        _TopBar(mode: mode, onMode: onMode, compact: true),
        const SizedBox(height: 18),
        SizedBox(
          height: 420,
          child: _CenterStage(
            mode: mode,
            recommendation: recommendation,
            activeEntity: activeEntity,
            activeEntityId: activeEntityId,
            onOpenWorkflow: onOpenWorkflow,
            onOpenAgent: onOpenAgent,
            onOpenTool: onOpenTool,
          ),
        ),
        const SizedBox(height: 14),
        _PromptComposer(
          controller: taskController,
          onSubmit: onSubmit,
          onQuickGoal: onQuickGoal,
        ),
        const SizedBox(height: 14),
        _SettingsPanel(
          model: model,
          aspect: aspect,
          quality: quality,
          mode: mode,
          settings: settings,
          onModel: onModel,
          onAspect: onAspect,
          onQuality: onQuality,
          onReset: onReset,
          onOpenWorkflow: onOpenWorkflow,
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.mode,
    required this.onMode,
    this.compact = false,
  });

  final _WorkMode mode;
  final ValueChanged<_WorkMode> onMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 96 : 56,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 22),
        child: compact
            ? Column(
                children: [
                  _TopIdentity(compact: compact),
                  const SizedBox(height: 10),
                  _ModeTabs(mode: mode, onMode: onMode),
                ],
              )
            : Row(
                children: [
                  const SizedBox(width: 190, child: _TopIdentity()),
                  Expanded(
                    child: Center(
                      child: _ModeTabs(mode: mode, onMode: onMode),
                    ),
                  ),
                  const SizedBox(width: 190, child: _TopActions()),
                ],
              ),
      ),
    );
  }
}

class _TopIdentity extends StatelessWidget {
  const _TopIdentity({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF101218),
            border: Border.all(color: const Color(0x14FFFFFF)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.blur_on_rounded, size: 16),
        ),
        const SizedBox(width: 8),
        const Text(
          'AI Operator OS',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.dark_mode_outlined, size: 17, color: Color(0xFF8B8F9A)),
        SizedBox(width: 12),
        _SoftBadge('Hybrid'),
        SizedBox(width: 12),
        CircleAvatar(radius: 12, backgroundColor: Color(0xFF242833)),
      ],
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onMode});

  final _WorkMode mode;
  final ValueChanged<_WorkMode> onMode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in _WorkMode.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onMode(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: mode == item
                        ? const Color(0x1AFF7A4D)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: mode == item
                          ? const Color(0xFFFF9A78)
                          : const Color(0xFFB0B4BE),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.tab,
    required this.onTab,
    required this.onNavigate,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
  });

  final String tab;
  final ValueChanged<String> onTab;
  final ValueChanged<AppDestination> onNavigate;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 16),
              suffixIcon: const Icon(Icons.close_rounded, size: 14),
              hintText: 'Поиск',
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0x12FFFFFF)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final item in ['все', 'изб', 'проекты'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _TinyTab(
                      label: item,
                      selected: tab == item,
                      onTap: () => onTab(item),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const _PanelLabel('Избранное'),
          _HistoryItem('неделя 3', 'saved stack', () {}),
          _HistoryItem('неделя 2', 'prompt route', () {}),
          _HistoryItem('идеи', 'creative queue', () {}),
          _HistoryItem(
            'Проект 1',
            'active',
            () => onNavigate(AppDestination.projects),
          ),
          const SizedBox(height: 14),
          const _PanelLabel('На этой неделе'),
          _HistoryItem(
            'AI Short Video Factory',
            'workflow',
            () => onOpenWorkflow('ai-short-video-factory'),
          ),
          _HistoryItem(
            'Music Promo Pack',
            'workflow',
            () => onOpenWorkflow('music-release-promo-pack'),
          ),
          _HistoryItem(
            'AI Freelance Scout',
            'use case',
            () => onOpenAgent('research-agent'),
          ),
          const SizedBox(height: 14),
          const _PanelLabel('Ранее'),
          _HistoryItem(
            'Photo Restoration Service',
            'client work',
            () => onOpenWorkflow('ai-tool-finder'),
          ),
          _HistoryItem(
            'Video Localization',
            'pipeline',
            () => onOpenTool('heygen'),
          ),
          _HistoryItem(
            'Automation Builder',
            'n8n idea',
            () => onOpenAgent('automation-architect-agent'),
          ),
          const SizedBox(height: 4),
          _HistoryFooter(
            onNavigate: onNavigate,
            onOpenWorkflow: onOpenWorkflow,
            onOpenAgent: onOpenAgent,
            onOpenTool: onOpenTool,
          ),
        ],
      ),
    );
  }
}

class _CenterStage extends StatelessWidget {
  const _CenterStage({
    required this.mode,
    required this.recommendation,
    required this.activeEntity,
    required this.activeEntityId,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
  });

  final _WorkMode mode;
  final RoutingRecommendation? recommendation;
  final _ActiveEntity activeEntity;
  final String? activeEntityId;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final Widget stage;
    if (activeEntity != _ActiveEntity.none) {
      stage = _EntityStage(
        entity: activeEntity,
        entityId: activeEntityId,
        recommendation: recommendation,
        onOpenWorkflow: onOpenWorkflow,
        onOpenAgent: onOpenAgent,
        onOpenTool: onOpenTool,
        key: ValueKey('${activeEntity.name}-${activeEntityId ?? 'default'}'),
      );
    } else if (recommendation == null) {
      stage = _EmptyModeStage(mode: mode, key: ValueKey(mode));
    } else {
      stage = _RouteStage(
        recommendation: recommendation!,
        onOpenWorkflow: onOpenWorkflow,
        onOpenAgent: onOpenAgent,
        onOpenTool: onOpenTool,
        key: const ValueKey('route-stage'),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: stage,
    );
  }
}

class _EmptyModeStage extends StatelessWidget {
  const _EmptyModeStage({super.key, required this.mode});

  final _WorkMode mode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                border: Border.all(color: const Color(0x14FFFFFF)),
                shape: BoxShape.circle,
              ),
              child: Icon(mode.icon, color: const Color(0xFFF2F3F5), size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              mode.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF2F3F5),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mode.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8B8F9A),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            const _CapabilityStrip(),
          ],
        ),
      ),
    );
  }
}

class _RouteStage extends StatelessWidget {
  const _RouteStage({
    super.key,
    required this.recommendation,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
  });

  final RoutingRecommendation recommendation;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final graph = const GraphRepository();
    final agents = graph.agentsByIds(recommendation.agentIds);
    final tools = graph.toolsByIds(recommendation.toolIds);
    final firstAgentId = recommendation.agentIds.isEmpty
        ? null
        : recommendation.agentIds.first;
    final firstToolId = recommendation.toolIds.isEmpty
        ? null
        : recommendation.toolIds.first;
    return Center(
      child: _GlassPanel(
        key: const ValueKey('recommended-plan'),
        width: 620,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelLabel('AI-маршрут'),
            const SizedBox(height: 10),
            Text(
              recommendation.task,
              style: const TextStyle(
                color: Color(0xFFF2F3F5),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            _RouteLine('Тип задачи', recommendation.estimatedCost),
            _RouteLine('Workflow', recommendation.recommendedWorkflow),
            _RouteLine('Агенты', agents.map((item) => item.name).join(' / ')),
            _RouteLine(
              'Инструменты',
              tools.map((item) => item.name).join(' / '),
            ),
            _RouteLine(
              'Следующие шаги',
              recommendation.manualSteps.take(3).join(' → '),
            ),
            const SizedBox(height: 8),
            const Text(
              'Сейчас OS работает в ручном режиме: она собирает маршрут, промпты и инструменты. На следующих этапах мы подключим OpenAI API, Ollama и автоматические агенты.',
              style: TextStyle(
                color: Color(0xFF8B8F9A),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => onOpenWorkflow(recommendation.workflowId),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Открыть сценарий'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpenAgent(firstAgentId),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Агент'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpenTool(firstToolId),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Тул-кит'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityStage extends StatelessWidget {
  const _EntityStage({
    super.key,
    required this.entity,
    required this.entityId,
    required this.recommendation,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
  });

  final _ActiveEntity entity;
  final String? entityId;
  final RoutingRecommendation? recommendation;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final graph = const GraphRepository();
    return switch (entity) {
      _ActiveEntity.workflow => _WorkflowStage(
        workflow: _firstOrNull(
          graph.workflowsByIds([
            entityId ?? recommendation?.workflowId ?? 'ai-short-video-factory',
          ]),
        ),
        onOpenAgent: onOpenAgent,
        onOpenTool: onOpenTool,
      ),
      _ActiveEntity.agent => _AgentStage(
        agent: _firstOrNull(
          graph.agentsByIds([
            entityId ??
                _firstOrNull(recommendation?.agentIds ?? const []) ??
                'tool-router-agent',
          ]),
        ),
        onOpenWorkflow: onOpenWorkflow,
        onOpenTool: onOpenTool,
      ),
      _ActiveEntity.tool => _ToolStage(
        tool: _firstOrNull(
          graph.toolsByIds([
            entityId ??
                _firstOrNull(recommendation?.toolIds ?? const []) ??
                'chatgpt',
          ]),
        ),
        onOpenAgent: onOpenAgent,
        onOpenWorkflow: onOpenWorkflow,
      ),
      _ActiveEntity.none => const SizedBox.shrink(),
    };
  }
}

class _WorkflowStage extends StatelessWidget {
  const _WorkflowStage({
    required this.workflow,
    required this.onOpenAgent,
    required this.onOpenTool,
  });

  final WorkflowTemplate? workflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    if (workflow == null) {
      return const _MissingEntityStage('Сценарий не найден');
    }

    final graph = const GraphRepository();
    final agents = graph.agentsByIds([
      ...workflow!.agentIds,
      for (final step in workflow!.steps)
        if (step.agentId != null) step.agentId!,
    ]);
    final tools = graph.toolsByIds([
      ...workflow!.requiredTools,
      ...workflow!.optionalTools,
      ...workflow!.toolIds,
      for (final step in workflow!.steps) ...step.toolIds,
    ]);
    final firstPrompt = workflow!.steps.isEmpty
        ? workflow!.description
        : workflow!.steps.first.promptTemplate;

    return Center(
      child: _GlassPanel(
        width: 680,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PanelLabel('АКТИВНЫЙ СЦЕНАРИЙ'),
              const SizedBox(height: 10),
              Text(
                workflow!.title,
                style: const TextStyle(
                  color: Color(0xFFF2F3F5),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                workflow!.description,
                style: const TextStyle(color: Color(0xFF9AA0AA), height: 1.35),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _SoftBadge(workflow!.category),
                  _SoftBadge(workflow!.estimatedTime),
                  _SoftBadge(workflow!.automationLevel.name),
                  _SoftBadge(workflow!.monetizationPotential.name),
                ],
              ),
              const SizedBox(height: 18),
              for (final step in workflow!.steps.take(5))
                _StageStep(step: step, onOpenTool: onOpenTool),
              const SizedBox(height: 12),
              _LinkedNames(
                title: 'Агенты',
                names: agents.map((item) => item.name).toList(),
              ),
              _LinkedNames(
                title: 'Инструменты',
                names: tools.map((item) => item.name).toList(),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Сценарий запущен в ручном режиме'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Начать'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copyText(context, firstPrompt),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Скопировать промпт'),
                  ),
                  OutlinedButton.icon(
                    onPressed: tools.isEmpty
                        ? null
                        : () => onOpenTool(tools.first.id),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Открыть инструмент'),
                  ),
                  OutlinedButton.icon(
                    onPressed: agents.isEmpty
                        ? null
                        : () => onOpenAgent(agents.first.id),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Агент'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Сохранено в проект')),
                      );
                    },
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentStage extends StatelessWidget {
  const _AgentStage({
    required this.agent,
    required this.onOpenWorkflow,
    required this.onOpenTool,
  });

  final AiAgent? agent;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    if (agent == null) return const _MissingEntityStage('Агент не найден');

    final graph = const GraphRepository();
    final tools = graph.toolsByIds([
      ...agent!.toolIds,
      ...agent!.recommendedTools,
    ]);
    final workflows = graph.workflowsByIds(agent!.workflowIds);

    return Center(
      child: _GlassPanel(
        width: 620,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PanelLabel('АКТИВНЫЙ АГЕНТ'),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(agent!.avatarEmoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent!.name,
                        style: const TextStyle(
                          color: Color(0xFFF2F3F5),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        agent!.role,
                        style: const TextStyle(color: Color(0xFF9AA0AA)),
                      ),
                    ],
                  ),
                ),
                _SoftBadge(agent!.status.name),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              agent!.description,
              style: const TextStyle(color: Color(0xFFE5E7EC), height: 1.35),
            ),
            const SizedBox(height: 16),
            _LinkedNames(
              title: 'Инструменты агента',
              names: tools.map((item) => item.name).toList(),
            ),
            _LinkedNames(
              title: 'Сценарии',
              names: workflows.map((item) => item.title).toList(),
            ),
            const SizedBox(height: 14),
            const _ManualModeBox(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${agent!.name}: mock output готов'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Назначить задачу'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyText(context, agent!.systemPrompt),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Промпт агента'),
                ),
                OutlinedButton.icon(
                  onPressed: tools.isEmpty
                      ? null
                      : () => onOpenTool(tools.first.id),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Инструмент'),
                ),
                OutlinedButton.icon(
                  onPressed: workflows.isEmpty
                      ? null
                      : () => onOpenWorkflow(workflows.first.id),
                  icon: const Icon(Icons.schema_outlined),
                  label: const Text('Сценарий'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolStage extends StatelessWidget {
  const _ToolStage({
    required this.tool,
    required this.onOpenAgent,
    required this.onOpenWorkflow,
  });

  final AiTool? tool;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenWorkflow;

  @override
  Widget build(BuildContext context) {
    if (tool == null) return const _MissingEntityStage('Инструмент не найден');

    final graph = const GraphRepository();
    final agents = graph.agentsByIds(tool!.agentIds);
    final workflows = graph.workflowsByIds(tool!.workflowIds);
    final prompt =
        'Задача: {{task}}\nИнструмент: ${tool!.name}\nРежим: manual\nНужно: подготовь точный промпт и шаги запуска.';

    return Center(
      child: _GlassPanel(
        width: 620,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PanelLabel('АКТИВНЫЙ ИНСТРУМЕНТ'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tool!.name,
                    style: const TextStyle(
                      color: Color(0xFFF2F3F5),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _SoftBadge(tool!.integrationType.label),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tool!.description,
              style: const TextStyle(color: Color(0xFFE5E7EC), height: 1.35),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _SoftBadge(tool!.category.label),
                _SoftBadge(tool!.pricingType.label),
                _SoftBadge(tool!.hasApi ? 'API позже' : 'manual'),
                if (tool!.isLocal) const _SoftBadge('local'),
              ],
            ),
            const SizedBox(height: 16),
            _RouteLine('Лучше для', tool!.bestFor),
            _RouteLine('Бесплатно', tool!.freeCreditsInfo),
            _RouteLine('Ограничения', tool!.limitations),
            _LinkedNames(
              title: 'Агенты',
              names: agents.map((item) => item.name).toList(),
            ),
            _LinkedNames(
              title: 'Сценарии',
              names: workflows.map((item) => item.title).toList(),
            ),
            const SizedBox(height: 14),
            const _ManualModeBox(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => const UrlService().open(tool!.url),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Открыть сайт'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyText(context, prompt),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать промпт'),
                ),
                OutlinedButton.icon(
                  onPressed: agents.isEmpty
                      ? null
                      : () => onOpenAgent(agents.first.id),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Агент'),
                ),
                OutlinedButton.icon(
                  onPressed: workflows.isEmpty
                      ? null
                      : () => onOpenWorkflow(workflows.first.id),
                  icon: const Icon(Icons.schema_outlined),
                  label: const Text('Сценарий'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageStep extends StatelessWidget {
  const _StageStep({required this.step, required this.onOpenTool});

  final WorkflowStep step;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x10FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            step.isAutomatable
                ? Icons.auto_awesome_rounded
                : Icons.touch_app_outlined,
            color: const Color(0xFF8B8F9A),
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.instruction,
                  style: const TextStyle(
                    color: Color(0xFF9AA0AA),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (step.toolIds.isNotEmpty)
            IconButton(
              onPressed: () => onOpenTool(step.toolIds.first),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              tooltip: 'Открыть инструмент',
            ),
        ],
      ),
    );
  }
}

class _LinkedNames extends StatelessWidget {
  const _LinkedNames({required this.title, required this.names});

  final String title;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _RouteLine(title, names.take(4).join(' / ')),
    );
  }
}

class _ManualModeBox extends StatelessWidget {
  const _ManualModeBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Manual Mode: OS готовит маршрут, ссылки и промпты. API Mode и Local Mode подключим позже без перестройки рабочего экрана.',
        style: TextStyle(color: Color(0xFF9AA0AA), fontSize: 12, height: 1.35),
      ),
    );
  }
}

class _MissingEntityStage extends StatelessWidget {
  const _MissingEntityStage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassPanel(
        width: 420,
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _PromptComposer extends StatelessWidget {
  const _PromptComposer({
    required this.controller,
    required this.onSubmit,
    required this.onQuickGoal,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final ValueChanged<String> onQuickGoal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassPanel(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Column(
            children: [
              TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Напишите вашу задачу...',
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(width: 10),
                      Icon(Icons.attach_file_rounded, size: 17),
                      SizedBox(width: 9),
                      Icon(Icons.image_outlined, size: 17),
                      SizedBox(width: 9),
                      Icon(Icons.lock_outline_rounded, size: 16),
                    ],
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mic_none_rounded, size: 18),
                      const SizedBox(width: 8),
                      const _SoftBadge('9:16'),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        key: const ValueKey('build-plan-button'),
                        onPressed: onSubmit,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        tooltip: 'Собрать план',
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          alignment: WrapAlignment.center,
          children: [
            for (final goal in _CommandCenterScreenState._quickGoals)
              ActionChip(
                label: Text(goal.label),
                onPressed: () => onQuickGoal(goal.task),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.model,
    required this.aspect,
    required this.quality,
    required this.mode,
    required this.settings,
    required this.onModel,
    required this.onAspect,
    required this.onQuality,
    required this.onReset,
    required this.onOpenWorkflow,
  });

  final String model;
  final String aspect;
  final String quality;
  final _WorkMode mode;
  final AppSettings settings;
  final ValueChanged<String> onModel;
  final ValueChanged<String> onAspect;
  final ValueChanged<String> onQuality;
  final VoidCallback onReset;
  final ValueChanged<String?> onOpenWorkflow;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsGroup(
            title: 'Выбор модели',
            child: Column(
              children: [
                _SelectLine(
                  value: model,
                  values: const [
                    'Auto Router',
                    'ChatGPT',
                    'Claude',
                    'Kling',
                    'Veo',
                    'Midjourney',
                    'Ollama Local',
                  ],
                  onChanged: onModel,
                ),
                const SizedBox(height: 8),
                _SelectLine(
                  value: mode.title,
                  values: _WorkMode.values.map((item) => item.title).toList(),
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          _SettingsGroup(
            title: 'Формат',
            trailing: TextButton(
              onPressed: onReset,
              child: const Text('Сбросить'),
            ),
            child: _SegmentedValues(
              value: aspect,
              values: const ['1:1', '9:16', '16:9'],
              onChanged: onAspect,
            ),
          ),
          _SettingsGroup(
            title: 'Качество',
            child: _SegmentedValues(
              value: quality,
              values: const ['Draft', 'Balanced', 'Pro'],
              onChanged: onQuality,
            ),
          ),
          _SettingsGroup(
            title: 'Стиль / Референсы',
            child: Column(
              children: const [
                _ReferenceBox(label: 'референс стиля'),
                SizedBox(height: 8),
                _ReferenceBox(label: 'референс объекта'),
              ],
            ),
          ),
          _SettingsGroup(
            title: 'Выполнение',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PathRow('Manual Mode', Icons.open_in_new_rounded),
                _PathRow('API Mode позже', Icons.api_rounded),
                _PathRow('Local Mode позже', Icons.dns_outlined),
                SizedBox(height: 6),
                Text(
                  'Сейчас OS работает в ручном режиме: она собирает маршрут, промпты и инструменты. На следующих этапах мы подключим OpenAI API, Ollama и автоматические агенты.',
                  style: TextStyle(
                    color: Color(0xFF8B8F9A),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _SettingsGroup(
            title: 'Статус',
            child: Column(
              children: [
                _MetaLine('Mode', settings.operatorMode.name),
                _MetaLine('Ollama', settings.ollamaBaseUrl),
                if (seedFreeCredits.isNotEmpty)
                  _MetaLine('Free today', seedFreeCredits.first.service),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  child: const Text('Сбросить всё'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => onOpenWorkflow(null),
                  child: const Text('Сценарий'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.padding, this.width, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xB814161C),
        border: Border.all(color: const Color(0x14FFFFFF)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _PanelLabel(title)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SelectLine extends StatelessWidget {
  const _SelectLine({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: values.contains(value) ? value : values.first,
      isDense: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _SegmentedValues extends StatelessWidget {
  const _SegmentedValues({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: _TinyTab(
                label: item,
                selected: item == value,
                onTap: () => onChanged(item),
              ),
            ),
          ),
      ],
    );
  }
}

class _TinyTab extends StatelessWidget {
  const _TinyTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x24FF7A4D) : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0x44FF9A78) : const Color(0x10FFFFFF),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? const Color(0xFFFFA07A) : const Color(0xFF9CA1AD),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem(this.title, this.subtitle, this.onTap);

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF7D828D), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter({
    required this.onNavigate,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
  });

  final ValueChanged<AppDestination> onNavigate;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniIconButton(Icons.grid_view_rounded, () => onOpenTool('chatgpt')),
        _MiniIconButton(
          Icons.smart_toy_outlined,
          () => onOpenAgent('tool-router-agent'),
        ),
        _MiniIconButton(
          Icons.schema_outlined,
          () => onOpenWorkflow('ai-short-video-factory'),
        ),
        _MiniIconButton(
          Icons.tune_rounded,
          () => onNavigate(AppDestination.settings),
        ),
      ],
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton(this.icon, this.onTap);

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        color: const Color(0xFF8B8F9A),
      ),
    );
  }
}

class _CapabilityStrip extends StatelessWidget {
  const _CapabilityStrip();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: const [
        _SoftBadge('агенты'),
        _SoftBadge('workflow'),
        _SoftBadge('free/pro/local'),
      ],
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B8F9A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFFE5E7EC), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceBox extends StatelessWidget {
  const _ReferenceBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: Color(0xFF8B8F9A)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF8B8F9A), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow(this.label, this.icon);

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8B8F9A)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF8B8F9A), fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8B8F9A),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFC8CAD1),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
