import 'package:flutter/material.dart';

import '../../ai_operator_app.dart';
import '../../data/seed_agents.dart';
import '../../models/ai_agent.dart';
import '../../services/agent_repository.dart';
import '../../services/graph_repository.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/chips/status_badge.dart';
import '../../widgets/responsive_page.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      title: 'AI-помощники',
      subtitle:
          'Специализированные демо AI-помощники для планирования, маршрутизации, промптов, автоматизации и QA. Backend пока не подключён.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 720
              ? 2
              : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: seedAgents.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 336,
            ),
            itemBuilder: (context, index) =>
                _AgentCard(agent: seedAgents[index]),
          );
        },
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({required this.agent});

  final AiAgent agent;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final favorite = settings.isFavoriteAgent(agent.id);
    return OsCard(
      onTap: () => _showAgent(context, agent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(agent.avatarEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      agent.role,
                      style: const TextStyle(color: Color(0xFF8B97A8)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => settings.toggleFavoriteAgent(agent.id),
                icon: Icon(
                  favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            agent.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(label: agent.status.label),
              if (agent.canUseApi) const StatusBadge(label: 'API позже'),
              if (agent.isLocalCapable) const StatusBadge(label: 'Local'),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _showAgent(context, agent),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Запустить агента'),
          ),
        ],
      ),
    );
  }

  void _showAgent(BuildContext context, AiAgent agent) {
    showDialog<void>(
      context: context,
      builder: (context) => _AgentDialog(agent: agent),
    );
  }
}

class _AgentDialog extends StatefulWidget {
  const _AgentDialog({required this.agent});

  final AiAgent agent;

  @override
  State<_AgentDialog> createState() => _AgentDialogState();
}

class _AgentDialogState extends State<_AgentDialog> {
  final TextEditingController _task = TextEditingController();
  String? _response;

  @override
  void dispose() {
    _task.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.agent.avatarEmoji} ${widget.agent.name}'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.agent.description),
              const SizedBox(height: 12),
              _AgentLinks(agent: widget.agent),
              const SizedBox(height: 12),
              TextField(
                controller: _task,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Опиши задачу для этого агента...',
                ),
              ),
              const SizedBox(height: 12),
              if (_response != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D111A),
                    border: Border.all(color: const Color(0xFF243244)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(_response!),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
        FilledButton.icon(
          onPressed: () {
            setState(() {
              _response = const AgentRepository().runMock(
                widget.agent,
                _task.text,
              );
            });
          },
          icon: const Icon(Icons.smart_toy_outlined),
          label: const Text('Запустить демо'),
        ),
      ],
    );
  }
}

class _AgentLinks extends StatelessWidget {
  const _AgentLinks({required this.agent});

  final AiAgent agent;

  @override
  Widget build(BuildContext context) {
    final graph = const GraphRepository();
    final tools = graph.toolsByIds([
      ...agent.toolIds,
      ...agent.recommendedTools,
    ]);
    final workflows = graph.workflowsByIds(agent.workflowIds);
    final useCases = graph.useCasesForAgent(agent.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DialogChips(
          title: 'Инструменты',
          items: tools.map((tool) => tool.name).toList(),
        ),
        _DialogChips(
          title: 'Сценарии',
          items: workflows.map((w) => w.title).toList(),
        ),
        _DialogChips(
          title: 'Кейсы',
          items: useCases.map((u) => u.title).toList(),
        ),
      ],
    );
  }
}

class _DialogChips extends StatelessWidget {
  const _DialogChips({required this.title, required this.items});

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
        children: [
          Chip(label: Text(title)),
          for (final item in items.take(6)) Chip(label: Text(item)),
        ],
      ),
    );
  }
}
