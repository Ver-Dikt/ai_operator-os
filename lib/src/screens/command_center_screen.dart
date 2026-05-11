import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../data/seed_agents.dart';
import '../data/seed_free_credits.dart';
import '../data/seed_tools.dart';
import '../data/seed_workflows.dart';
import '../models/ai_tool.dart';
import '../models/routing_recommendation.dart';
import '../services/graph_repository.dart';
import '../services/router_service.dart';
import '../state/app_settings.dart';
import '../widgets/chips/status_badge.dart';

enum _WorkMode { video, design, audio, research, automation }

extension _WorkModeUi on _WorkMode {
  String get label {
    return switch (this) {
      _WorkMode.video => 'Видео',
      _WorkMode.design => 'Дизайн',
      _WorkMode.audio => 'Аудио',
      _WorkMode.research => 'Research',
      _WorkMode.automation => 'Automation',
    };
  }

  IconData get icon {
    return switch (this) {
      _WorkMode.video => Icons.movie_creation_outlined,
      _WorkMode.design => Icons.auto_awesome_mosaic_outlined,
      _WorkMode.audio => Icons.graphic_eq_rounded,
      _WorkMode.research => Icons.travel_explore_rounded,
      _WorkMode.automation => Icons.bolt_rounded,
    };
  }

  String get model {
    return switch (this) {
      _WorkMode.video => 'Director Agent + Kling/Veo',
      _WorkMode.design => 'Prompt Engineer + Image stack',
      _WorkMode.audio => 'Music Promo + Voice stack',
      _WorkMode.research => 'Research Agent + Perplexity',
      _WorkMode.automation => 'Automation Agent + n8n',
    };
  }

  List<String> get settings {
    return switch (this) {
      _WorkMode.video => [
        'Формат: 9:16',
        'Длина: 30-45 сек',
        'Камера: стабильная',
        'Качество: draft -> pro',
      ],
      _WorkMode.design => [
        'Стиль: cinematic clean',
        'Референсы: включены',
        'Палитра: тёмная',
        'Вариации: 4',
      ],
      _WorkMode.audio => [
        'Задача: промо трека',
        'Голос: опционально',
        'Музыка: mood-first',
        'Публикация: batch',
      ],
      _WorkMode.research => [
        'Глубина: быстрая',
        'Источники: вручную/API позже',
        'Сравнение: free/pro/local',
        'Вывод: план действий',
      ],
      _WorkMode.automation => [
        'Слой: mock workflow',
        'Инструменты: n8n/Make',
        'Проверка: вручную',
        'Логи: Phase 3',
      ],
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
  _WorkMode _mode = _WorkMode.video;
  late RoutingRecommendation _recommendation;

  static const _sampleTask = 'Сделать 10 Reels для музыкального трека';

  static const _quickGoals = <({IconData icon, String label, String task})>[
    (
      icon: Icons.movie_creation_outlined,
      label: 'AI-видео',
      task: 'Сделать кинематографичное AI-видео для соцсетей',
    ),
    (
      icon: Icons.music_note_rounded,
      label: 'Музыка',
      task: 'Сделать 10 Reels для музыкального трека',
    ),
    (
      icon: Icons.payments_outlined,
      label: 'AI-фриланс',
      task: 'Найти AI-фриланс задачи и путь к первым клиентам',
    ),
    (
      icon: Icons.translate_rounded,
      label: 'Локализация',
      task: 'Локализовать видео: перевод, озвучка, субтитры',
    ),
    (
      icon: Icons.photo_camera_back_outlined,
      label: 'Оживить фото',
      task: 'Оживить старые фото как клиентскую услугу',
    ),
    (
      icon: Icons.bolt_rounded,
      label: 'Автоматизация',
      task: 'Построить n8n workflow для повторяющейся AI-задачи',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _taskController.text = _sampleTask;
    _recommendation = const RouterService().recommend(_sampleTask);
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10141C), Color(0xFF070A0F)],
          ),
        ),
        child: SafeArea(
          child: isWide
              ? Row(
                  children: [
                    _SessionRail(onNavigate: widget.onNavigate),
                    Expanded(child: _WorkspaceCore(state: this)),
                    _ContextPanel(
                      mode: _mode,
                      settings: settings,
                      onNavigate: widget.onNavigate,
                    ),
                  ],
                )
              : _MobileWorkspace(
                  state: this,
                  settings: settings,
                  onNavigate: widget.onNavigate,
                ),
        ),
      ),
    );
  }

  void _setMode(_WorkMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  void _routeTask([String? task]) {
    final nextTask = task ?? _taskController.text;
    if (task != null) {
      _taskController.text = task;
    }
    setState(() {
      _recommendation = const RouterService().recommend(nextTask);
    });
  }
}

class _WorkspaceCore extends StatelessWidget {
  const _WorkspaceCore({required this.state});

  final _CommandCenterScreenState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        children: [
          _TopModeBar(mode: state._mode, onModeChanged: state._setMode),
          const SizedBox(height: 26),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: _CommandThread(
                  recommendation: state._recommendation,
                  mode: state._mode,
                  onNavigate: state.widget.onNavigate,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: _CommandComposer(
              controller: state._taskController,
              goals: _CommandCenterScreenState._quickGoals,
              onSubmit: state._routeTask,
              onGoal: state._routeTask,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileWorkspace extends StatelessWidget {
  const _MobileWorkspace({
    required this.state,
    required this.settings,
    required this.onNavigate,
  });

  final _CommandCenterScreenState state;
  final AppSettings settings;
  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
      children: [
        _TopModeBar(mode: state._mode, onModeChanged: state._setMode),
        const SizedBox(height: 16),
        _CommandThread(
          recommendation: state._recommendation,
          mode: state._mode,
          onNavigate: onNavigate,
          compact: true,
        ),
        const SizedBox(height: 14),
        _CommandComposer(
          controller: state._taskController,
          goals: _CommandCenterScreenState._quickGoals,
          onSubmit: state._routeTask,
          onGoal: state._routeTask,
        ),
        const SizedBox(height: 14),
        _ContextPanelContent(
          mode: state._mode,
          settings: settings,
          onNavigate: onNavigate,
        ),
      ],
    );
  }
}

class _SessionRail extends StatelessWidget {
  const _SessionRail({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        color: Color(0xE6070A0F),
        border: Border(right: BorderSide(color: Color(0xFF1E2734))),
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  border: Border.all(color: const Color(0xFF273346)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.blur_on_rounded,
                  color: Color(0xFF6BE4C9),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Operator OS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'рабочая станция',
                      style: TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => onNavigate(AppDestination.projects),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Новая сессия'),
          ),
          const SizedBox(height: 18),
          const _RailTitle('Проекты'),
          _RailItem(
            selected: true,
            title: '10 Reels для трека',
            subtitle: 'video workflow',
            onTap: () {},
          ),
          _RailItem(
            title: 'AI-фриланс разведка',
            subtitle: 'research',
            onTap: () => onNavigate(AppDestination.useCases),
          ),
          _RailItem(
            title: 'Оживление фото',
            subtitle: 'client service',
            onTap: () => onNavigate(AppDestination.workflows),
          ),
          const SizedBox(height: 14),
          const _RailTitle('История'),
          for (final workflow in seedWorkflows.take(4))
            _RailItem(
              title: workflow.title,
              subtitle: workflow.category,
              dense: true,
              onTap: () => onNavigate(AppDestination.workflows),
            ),
          const Spacer(),
          _RailShortcut(
            icon: Icons.grid_view_rounded,
            label: 'База инструментов',
            onTap: () => onNavigate(AppDestination.tools),
          ),
          _RailShortcut(
            icon: Icons.smart_toy_outlined,
            label: 'Агенты',
            onTap: () => onNavigate(AppDestination.agents),
          ),
          _RailShortcut(
            icon: Icons.star_outline_rounded,
            label: 'Избранное',
            onTap: () => onNavigate(AppDestination.favorites),
          ),
        ],
      ),
    );
  }
}

class _TopModeBar extends StatelessWidget {
  const _TopModeBar({required this.mode, required this.onModeChanged});

  final _WorkMode mode;
  final ValueChanged<_WorkMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'AI Operator OS',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        Flexible(
          flex: 4,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                for (final item in _WorkMode.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      avatar: Icon(item.icon, size: 16),
                      label: Text(item.label),
                      selected: mode == item,
                      onSelected: (_) => onModeChanged(item),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommandThread extends StatelessWidget {
  const _CommandThread({
    required this.recommendation,
    required this.mode,
    required this.onNavigate,
    this.compact = false,
  });

  final RoutingRecommendation recommendation;
  final _WorkMode mode;
  final ValueChanged<AppDestination> onNavigate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _WorkPanel(
      padding: EdgeInsets.all(compact ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Column(
              children: [
                Icon(mode.icon, color: const Color(0xFF6BE4C9), size: 38),
                const SizedBox(height: 12),
                const Text(
                  'Новая рабочая сессия',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Опиши задачу. Станция подберёт агентов, инструменты и порядок действий.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9AA6B8), height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _AssistantPlan(
            recommendation: recommendation,
            onNavigate: onNavigate,
          ),
        ],
      ),
    );
  }
}

class _CommandComposer extends StatelessWidget {
  const _CommandComposer({
    required this.controller,
    required this.goals,
    required this.onSubmit,
    required this.onGoal,
  });

  final TextEditingController controller;
  final List<({IconData icon, String label, String task})> goals;
  final VoidCallback onSubmit;
  final ValueChanged<String> onGoal;

  @override
  Widget build(BuildContext context) {
    return _WorkPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.terminal_rounded),
              hintText:
                  'Например: сделать 10 Reels для трека, найти AI-фриланс, оживить старые фото...',
              suffixIcon: IconButton(
                tooltip: 'Собрать план',
                onPressed: onSubmit,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const ValueKey('build-plan-button'),
                onPressed: onSubmit,
                icon: const Icon(Icons.route_rounded),
                label: const Text('Собрать план'),
              ),
              for (final goal in goals)
                ActionChip(
                  avatar: Icon(goal.icon, size: 16),
                  label: Text(goal.label),
                  onPressed: () => onGoal(goal.task),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssistantPlan extends StatelessWidget {
  const _AssistantPlan({
    required this.recommendation,
    required this.onNavigate,
  });

  final RoutingRecommendation recommendation;
  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final graph = const GraphRepository();
    final agents = graph.agentsByIds(recommendation.agentIds);
    final tools = graph.toolsByIds(recommendation.toolIds);
    final useCases = graph.useCasesByIds(recommendation.useCaseIds);

    return Container(
      key: const ValueKey('recommended-plan'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D111A),
        border: Border.all(color: const Color(0xFF263244)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFF132A2A),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF6BE4C9),
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Рекомендованный план',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Flexible(
                child: StatusBadge(label: recommendation.automationPotential),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PlanLine('Сценарий', [recommendation.recommendedWorkflow]),
          _PlanLine('Агенты', agents.map((item) => item.name).toList()),
          _PlanLine('Инструменты', tools.map((item) => item.name).toList()),
          _PlanLine('Кейсы', useCases.map((item) => item.title).toList()),
          _PlanLine('Бесплатный путь', recommendation.freePath),
          _PlanLine('Pro-путь', recommendation.proPath),
          _PlanLine('Вручную', recommendation.manualSteps),
          const SizedBox(height: 10),
          Text(
            'Монетизация: ${recommendation.monetizationIdea}',
            style: const TextStyle(color: Color(0xFFFFB86B), height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => onNavigate(AppDestination.workflows),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Открыть сценарий'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.tools),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Инструменты'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.agents),
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('Агенты'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({
    required this.mode,
    required this.settings,
    required this.onNavigate,
  });

  final _WorkMode mode;
  final AppSettings settings;
  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 306,
      decoration: const BoxDecoration(
        color: Color(0xD8070A0F),
        border: Border(left: BorderSide(color: Color(0xFF1E2734))),
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: _ContextPanelContent(
        mode: mode,
        settings: settings,
        onNavigate: onNavigate,
      ),
    );
  }
}

class _ContextPanelContent extends StatelessWidget {
  const _ContextPanelContent({
    required this.mode,
    required this.settings,
    required this.onNavigate,
  });

  final _WorkMode mode;
  final AppSettings settings;
  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final freeTools = seedTools.where((tool) => tool.isFreePath).take(3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PanelSection(
          title: 'Контекст режима',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingLine('Режим', mode.label),
              _SettingLine('Стек', mode.model),
              for (final item in mode.settings) _SettingLine(null, item),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PanelSection(
          title: 'Активные агенты',
          child: Column(
            children: [
              for (final agent in seedAgents.take(3))
                _CompactRow(
                  icon: Icons.smart_toy_outlined,
                  title: agent.name,
                  subtitle: agent.status.name,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PanelSection(
          title: 'Бесплатно сейчас',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final tool in freeTools)
                _CompactRow(
                  icon: Icons.savings_outlined,
                  title: tool.name,
                  subtitle: tool.pricingType.label,
                ),
              for (final offer in seedFreeCredits.take(1))
                _CompactRow(
                  icon: Icons.local_offer_outlined,
                  title: offer.service,
                  subtitle: offer.freeType,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PanelSection(
          title: 'Система',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingLine('Mode', settings.operatorMode.name),
              _SettingLine('Ollama', settings.ollamaBaseUrl),
              const _SettingLine('API', 'заглушки, backend позже'),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => onNavigate(AppDestination.settings),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Настройки'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkPanel extends StatelessWidget {
  const _WorkPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xD20D111A),
        border: Border.all(color: const Color(0xFF263244)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _WorkPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine(this.title, this.items);

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8B97A8),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in items.take(5))
                Chip(label: Text(item), visualDensity: VisualDensity.compact),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingLine extends StatelessWidget {
  const _SettingLine(this.label, this.value);

  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            SizedBox(
              width: 64,
              child: Text(
                label!,
                style: const TextStyle(
                  color: Color(0xFF8B97A8),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 7, right: 8),
              child: Icon(Icons.circle, size: 5, color: Color(0xFF6BE4C9)),
            ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFFC8D2E1), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B97A8), size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8B97A8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailTitle extends StatelessWidget {
  const _RailTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8B97A8),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.dense = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFF111C22) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: dense ? 8 : 10,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? const Color(0xFF2A5D59) : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8B97A8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailShortcut extends StatelessWidget {
  const _RailShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    );
  }
}
