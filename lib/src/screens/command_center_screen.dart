import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../data/seed_agents.dart';
import '../data/seed_free_credits.dart';
import '../data/seed_tools.dart';
import '../data/seed_workflows.dart';
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
  final TextEditingController _taskController = TextEditingController();
  var _recommendation = const RouterService().recommend(
    'Make 10 Reels for a music track',
  );

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return ResponsivePage(
      title: 'Command Router',
      subtitle:
          'One input, three modes: browse the AI internet, launch the agent workforce, or assemble a workflow.',
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
                    hintText:
                        'What do you want to do? Example: оживить старые фото как услугу',
                  ),
                  onSubmitted: (_) => _routeTask(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => widget.onNavigate(AppDestination.tools),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Find AI tool'),
                    ),
                    FilledButton.icon(
                      onPressed: () => widget.onNavigate(AppDestination.agents),
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: const Text('Launch agent'),
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          widget.onNavigate(AppDestination.workflows),
                      icon: const Icon(Icons.schema_rounded),
                      label: const Text('Build workflow'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _routeTask,
                      icon: const Icon(Icons.route_rounded),
                      label: const Text('Mock route task'),
                    ),
                  ],
                ),
              ],
            ),
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
                    child: _WorkflowsPanel(onNavigate: widget.onNavigate),
                  ),
                  SizedBox(
                    width: twoColumns
                        ? (constraints.maxWidth - 14) / 2
                        : constraints.maxWidth,
                    child: _StatusPanel(settings: settings),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'Use Case Library',
            subtitle: 'Task-first entry points for monetizable opportunities.',
          ),
          _UseCasePreview(onNavigate: widget.onNavigate),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'Recommended Stack Of The Day',
            subtitle: 'A practical mix for cinematic social video.',
          ),
          _StackPanel(onNavigate: widget.onNavigate),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'Favorite Agents',
            subtitle: 'Mock runners are ready. Backend adapters come later.',
          ),
          _AgentsStrip(onNavigate: widget.onNavigate),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'Free Today',
            subtitle: 'Free/local paths you can try before spending credits.',
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

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({
    required this.recommendation,
    required this.onNavigate,
  });

  final dynamic recommendation;
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
            title: 'Task Mode Recommendation',
            subtitle:
                'Mock router output: agents pick tools, workflow orders steps.',
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(label: recommendation.recommendedWorkflow),
              StatusBadge(label: recommendation.automationPotential),
              const StatusBadge(
                label: 'human review required',
                color: Color(0xFFFFB86B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniLinkLine(
            title: 'Agents',
            items: agents.map((a) => a.name).toList(),
          ),
          _MiniLinkLine(
            title: 'Tools',
            items: tools.map((t) => t.name).toList(),
          ),
          _MiniLinkLine(
            title: 'Use cases',
            items: useCases.map((u) => u.title).toList(),
          ),
          _MiniLinkLine(title: 'Free path', items: recommendation.freePath),
          _MiniLinkLine(title: 'Pro path', items: recommendation.proPath),
          _MiniLinkLine(
            title: 'Manual steps',
            items: recommendation.manualSteps,
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.monetizationIdea,
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
                label: const Text('Open workflow'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.useCases),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open use cases'),
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
            title: 'Recent Workflows',
            subtitle: 'Start with a template instead of a blank page.',
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
    final mode = settings.operatorMode.name.toUpperCase();
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'System Status',
            subtitle: 'Phase 1 runs locally with mock execution.',
          ),
          _StatusRow('Mode', '$mode mode'),
          _StatusRow('Ollama', settings.ollamaBaseUrl),
          const _StatusRow('API keys', 'Missing / placeholders only'),
          const _StatusRow('Backend', 'Not connected in Phase 1'),
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
            width: 82,
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

class _StackPanel extends StatelessWidget {
  const _StackPanel({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final stack = ['ChatGPT', 'Kling', 'Canva', 'ElevenLabs', 'n8n'];
    return OsCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final name in stack)
            Chip(
              avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(name),
            ),
          FilledButton.icon(
            onPressed: () => onNavigate(AppDestination.workflows),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start pipeline'),
          ),
        ],
      ),
    );
  }
}

class _UseCasePreview extends StatelessWidget {
  const _UseCasePreview({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in [
            '10 Reels for a track',
            'AI freelance tasks',
            'Restore old photos',
            'Video localization',
            'n8n workflow',
          ])
            Chip(label: Text(label)),
          OutlinedButton.icon(
            onPressed: () => onNavigate(AppDestination.useCases),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Browse use cases'),
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
        children: [
          for (final tool in freeTools) Chip(label: Text(tool.name)),
          for (final offer in seedFreeCredits.take(3))
            Chip(label: Text(offer.service)),
          OutlinedButton.icon(
            onPressed: () => onNavigate(AppDestination.tools),
            icon: const Icon(Icons.savings_outlined),
            label: const Text('Browse free tools'),
          ),
        ],
      ),
    );
  }
}
