import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../data/seed_agents.dart';
import '../data/seed_free_credits.dart';
import '../data/seed_tools.dart';
import '../data/seed_workflows.dart';
import '../models/routing_recommendation.dart';
import '../services/graph_repository.dart';
import '../services/router_service.dart';
import '../state/app_settings.dart';
import '../widgets/cards/os_card.dart';
import '../widgets/chips/status_badge.dart';
import '../widgets/responsive_page.dart';
import '../widgets/section_header.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key, required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  final TextEditingController _taskController = TextEditingController(
    text: 'Сделать 10 Reels для музыкального трека',
  );
  var _recommendation = const RouterService().recommend(
    'Сделать 10 Reels для музыкального трека',
  );

  static const _quickGoals = <({String icon, String label, String task})>[
    (
      icon: '🎬',
      label: 'Сделать AI-видео',
      task: 'Сделать кинематографичное AI-видео для соцсетей',
    ),
    (
      icon: '🎵',
      label: 'Продвинуть музыку',
      task: 'Сделать 10 Reels для музыкального трека',
    ),
    (
      icon: '💰',
      label: 'Найти AI-фриланс',
      task: 'Найти AI-фриланс задачи и собрать путь к первым клиентам',
    ),
    (
      icon: '🤖',
      label: 'Запустить агента',
      task: 'Подобрать агента, который разложит задачу на шаги',
    ),
    (
      icon: '🌍',
      label: 'Локализовать видео',
      task: 'Локализовать видео: перевод, озвучка, субтитры и публикация',
    ),
    (
      icon: '📸',
      label: 'Оживить фото',
      task: 'Оживить старые фото как клиентскую услугу',
    ),
    (
      icon: '⚡',
      label: 'Автоматизировать задачу',
      task: 'Построить n8n workflow для повторяющейся AI-задачи',
    ),
    (
      icon: '🧠',
      label: 'Исследовать рынок',
      task: 'Сделать анализ конкурентов и найти AI-возможности',
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
    return ResponsivePage(
      title: 'AI Operator OS',
      subtitle: 'Единый центр для нейросетей, агентов, сценариев и AI-работы.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _taskController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.terminal_rounded),
                    labelText: 'Что хочешь сделать?',
                    hintText:
                        'Например: сделать 10 Reels для трека, найти AI-фриланс, оживить старые фото...',
                  ),
                  onSubmitted: (_) => _routeTask(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _routeTask,
                      icon: const Icon(Icons.route_rounded),
                      label: const Text('Собрать план'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => widget.onNavigate(AppDestination.tools),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Найти нейросеть'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => widget.onNavigate(AppDestination.agents),
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: const Text('Запустить агента'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          widget.onNavigate(AppDestination.workflows),
                      icon: const Icon(Icons.schema_rounded),
                      label: const Text('Собрать сценарий'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Быстрые цели',
            subtitle:
                'Выбери направление, и OS сразу соберёт агентов, сценарий и инструменты.',
          ),
          _QuickGoalsGrid(
            goals: _quickGoals,
            onSelected: (task) {
              _taskController.text = task;
              _routeTask();
            },
          ),
          const SizedBox(height: 20),
          _RecommendationPanel(
            recommendation: _recommendation,
            onNavigate: widget.onNavigate,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 820;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: twoColumns
                        ? (constraints.maxWidth - 14) / 2
                        : constraints.maxWidth,
                    child: _StatusPanel(settings: settings),
                  ),
                  SizedBox(
                    width: twoColumns
                        ? (constraints.maxWidth - 14) / 2
                        : constraints.maxWidth,
                    child: _ProjectsPanel(onNavigate: widget.onNavigate),
                  ),
                  SizedBox(
                    width: twoColumns
                        ? (constraints.maxWidth - 14) / 2
                        : constraints.maxWidth,
                    child: _WorkflowsPanel(onNavigate: widget.onNavigate),
                  ),
                  SizedBox(
                    width: twoColumns
                        ? (constraints.maxWidth - 14) / 2
                        : constraints.maxWidth,
                    child: _QuickActionsPanel(onNavigate: widget.onNavigate),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'Активные агенты',
            subtitle: 'Выбери специалиста, если хочешь идти от роли к задаче.',
          ),
          _AgentsStrip(onNavigate: widget.onNavigate),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'Бесплатные возможности сегодня',
            subtitle:
                'Локальные и freemium-варианты, с которых можно начать без бюджета.',
          ),
          _FreeTodayPanel(onNavigate: widget.onNavigate),
        ],
      ),
    );
  }

  void _routeTask() {
    setState(() {
      _recommendation = const RouterService().recommend(_taskController.text);
    });
  }
}

class _QuickGoalsGrid extends StatelessWidget {
  const _QuickGoalsGrid({required this.goals, required this.onSelected});

  final List<({String icon, String label, String task})> goals;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1020
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final goal in goals)
              SizedBox(
                width: width,
                child: OsCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => onSelected(goal.task),
                  child: Row(
                    children: [
                      Text(goal.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          goal.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({
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

    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Рекомендованный план',
            subtitle:
                'Mock-router связывает задачу с агентами, нейросетями и сценарием. Реальных API пока нет.',
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(label: recommendation.recommendedWorkflow),
              StatusBadge(label: recommendation.automationPotential),
              const StatusBadge(
                label: 'нужна проверка человеком',
                color: Color(0xFFFFB86B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniLinkLine(
            title: 'Лучший сценарий',
            items: [recommendation.recommendedWorkflow],
          ),
          _MiniLinkLine(
            title: 'Подходящие агенты',
            items: agents.map((a) => a.name).toList(),
          ),
          _MiniLinkLine(
            title: 'Нужные инструменты',
            items: tools.map((t) => t.name).toList(),
          ),
          _MiniLinkLine(
            title: 'Подходящие кейсы',
            items: useCases.map((u) => u.title).toList(),
          ),
          _MiniLinkLine(
            title: 'Бесплатный путь',
            items: recommendation.freePath,
          ),
          _MiniLinkLine(title: 'Pro-путь', items: recommendation.proPath),
          _MiniLinkLine(
            title: 'Что сделать вручную',
            items: recommendation.manualSteps,
          ),
          const SizedBox(height: 8),
          Text(
            'Потенциал монетизации: ${recommendation.monetizationIdea}',
            style: const TextStyle(color: Color(0xFFFFB86B)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => onNavigate(AppDestination.workflows),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Открыть сценарии'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.agents),
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('Посмотреть агентов'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.useCases),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Открыть кейсы'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniLinkLine extends StatelessWidget {
  const _MiniLinkLine({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$title:', style: const TextStyle(fontWeight: FontWeight.w900)),
          for (final item in items.take(5)) Chip(label: Text(item)),
        ],
      ),
    );
  }
}

class _WorkflowsPanel extends StatelessWidget {
  const _WorkflowsPanel({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Последние сценарии',
            subtitle: 'Начни с готовой цепочки вместо пустого листа.',
          ),
          for (final workflow in seedWorkflows.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schema_rounded),
              title: Text(workflow.title),
              subtitle: Text(workflow.estimatedTime),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onNavigate(AppDestination.workflows),
            ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final mode = switch (settings.operatorMode) {
      OperatorMode.local => 'Local',
      OperatorMode.cloud => 'Cloud',
      OperatorMode.hybrid => 'Hybrid',
    };
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Статус системы',
            subtitle: 'Phase 1 работает локально, выполнение пока mock.',
          ),
          _StatusRow('Режим', '$mode mode'),
          _StatusRow('Ollama', settings.ollamaBaseUrl),
          const _StatusRow('API-ключи', 'заглушки, без backend-хранения'),
          const _StatusRow('Backend', 'не подключён в Phase 1'),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B97A8),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _ProjectsPanel extends StatelessWidget {
  const _ProjectsPanel({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Последние проекты',
            subtitle: 'Здесь будут сохраняться планы, прогресс и результаты.',
          ),
          const Text(
            'Пока активен демо-проект: "10 Reels для трека". Можно открыть раздел проектов и подготовить локальное хранение на следующем этапе.',
            style: TextStyle(color: Color(0xFFC8D2E1), height: 1.35),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onNavigate(AppDestination.projects),
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Открыть проекты'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Быстрые действия',
            subtitle: 'Перейди сразу к базе, агентам или кейсам.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => onNavigate(AppDestination.tools),
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Открыть базу AI'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.useCases),
                icon: const Icon(Icons.map_rounded),
                label: const Text('Выбрать кейс'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.contentFactory),
                icon: const Icon(Icons.factory_rounded),
                label: const Text('Контент-фабрика'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgentsStrip extends StatelessWidget {
  const _AgentsStrip({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final agent in seedAgents.take(4))
          SizedBox(
            width: 230,
            child: OsCard(
              onTap: () => onNavigate(AppDestination.agents),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent.avatarEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    agent.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agent.role,
                    style: const TextStyle(color: Color(0xFF8B97A8)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Открыть агента и запустить mock-задачу',
                    style: TextStyle(color: Color(0xFFC8D2E1), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FreeTodayPanel extends StatelessWidget {
  const _FreeTodayPanel({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final freeTools = seedTools.where((tool) => tool.isFreePath).take(5);
    return OsCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final tool in freeTools) Chip(label: Text(tool.name)),
          for (final offer in seedFreeCredits.take(3))
            Chip(label: Text(offer.service)),
          OutlinedButton.icon(
            onPressed: () => onNavigate(AppDestination.tools),
            icon: const Icon(Icons.savings_outlined),
            label: const Text('Найти бесплатные инструменты'),
          ),
        ],
      ),
    );
  }
}
