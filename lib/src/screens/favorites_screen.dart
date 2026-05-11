import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../data/seed_agents.dart';
import '../data/seed_prompts.dart';
import '../data/seed_workflows.dart';
import '../widgets/cards/os_card.dart';
import '../widgets/empty_states/empty_state.dart';
import '../widgets/responsive_page.dart';
import '../widgets/section_header.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tools = settings.favoriteTools;
    final agents = seedAgents
        .where((agent) => settings.favoriteAgentIds.contains(agent.id))
        .toList();
    final workflows = seedWorkflows
        .where((workflow) => settings.favoriteWorkflowIds.contains(workflow.id))
        .toList();
    final prompts = seedPrompts
        .where((prompt) => settings.favoritePromptIds.contains(prompt.id))
        .toList();

    final empty =
        tools.isEmpty && agents.isEmpty && workflows.isEmpty && prompts.isEmpty;

    return ResponsivePage(
      title: 'Избранное',
      subtitle:
          'Сохранённые инструменты, агенты, сценарии и промпты для повторной AI-работы.',
      child: empty
          ? const EmptyState(
              icon: Icons.star_border_rounded,
              title: 'Избранное пока пустое',
              message:
                  'Сохраняй инструменты, агентов, сценарии и промпты из соответствующих разделов.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tools.isNotEmpty) ...[
                  const SectionHeader(
                    title: 'Инструменты',
                    subtitle: 'Сохранённые AI-сервисы.',
                  ),
                  _ChipPanel(items: tools.map((tool) => tool.name).toList()),
                  const SizedBox(height: 18),
                ],
                if (agents.isNotEmpty) ...[
                  const SectionHeader(
                    title: 'Агенты',
                    subtitle: 'Сохранённые mock-исполнители.',
                  ),
                  _ChipPanel(items: agents.map((agent) => agent.name).toList()),
                  const SizedBox(height: 18),
                ],
                if (workflows.isNotEmpty) ...[
                  const SectionHeader(
                    title: 'Сценарии',
                    subtitle: 'Сохранённые production-цепочки.',
                  ),
                  _ChipPanel(
                    items: workflows.map((workflow) => workflow.title).toList(),
                  ),
                  const SizedBox(height: 18),
                ],
                if (prompts.isNotEmpty) ...[
                  const SectionHeader(
                    title: 'Промпты',
                    subtitle: 'Сохранённые шаблоны промптов.',
                  ),
                  _ChipPanel(
                    items: prompts.map((prompt) => prompt.title).toList(),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ChipPanel extends StatelessWidget {
  const _ChipPanel({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            Chip(
              avatar: const Icon(Icons.star_rounded, size: 16),
              label: Text(item),
            ),
        ],
      ),
    );
  }
}
