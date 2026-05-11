import 'package:flutter/material.dart';

import '../../data/seed_use_cases.dart';
import '../../models/monetization.dart';
import '../../models/use_case.dart';
import '../../services/graph_repository.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/chips/status_badge.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/section_header.dart';

class UseCasesScreen extends StatefulWidget {
  const UseCasesScreen({super.key});

  @override
  State<UseCasesScreen> createState() => _UseCasesScreenState();
}

class _UseCasesScreenState extends State<UseCasesScreen> {
  String _category = 'Все';

  @override
  Widget build(BuildContext context) {
    final categories = ['Все', ...seedUseCases.map((u) => u.category).toSet()];
    final useCases = seedUseCases
        .where((useCase) => _category == 'Все' || useCase.category == _category)
        .toList();

    return ResponsivePage(
      title: 'Кейсы',
      subtitle:
          'Библиотека задач: контент, клиентская работа, автоматизация и возможности монетизации. Без обещаний дохода: каждую идею нужно проверять.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1120
                  ? 3
                  : constraints.maxWidth >= 720
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: useCases.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 342,
                ),
                itemBuilder: (context, index) =>
                    _UseCaseCard(useCase: useCases[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UseCaseCard extends StatelessWidget {
  const _UseCaseCard({required this.useCase});

  final UseCase useCase;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      onTap: () => _showDetails(context, useCase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useCase.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(label: useCase.category),
              StatusBadge(label: useCase.monetizationPotential.label),
              if (useCase.requiresHumanReview)
                const StatusBadge(
                  label: 'проверка человеком',
                  color: Color(0xFFFFB86B),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            useCase.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.35),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _showDetails(context, useCase),
            icon: const Icon(Icons.account_tree_rounded),
            label: const Text('Рекомендованный стек'),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, UseCase useCase) {
    final graph = const GraphRepository();
    final agents = graph.agentsByIds(useCase.recommendedAgentIds);
    final tools = graph.toolsByIds(useCase.recommendedToolIds);
    final workflows = graph.workflowsByIds(useCase.recommendedWorkflowIds);
    final prompts = graph.promptsByIds(useCase.promptTemplateIds);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(useCase.title),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(useCase.description),
                const SizedBox(height: 12),
                Text(
                  'Модель дохода: ${useCase.monetizationType.label}. Только потенциал: проверь спрос до продажи.',
                  style: const TextStyle(color: Color(0xFFFFB86B)),
                ),
                const SizedBox(height: 16),
                _LinkSection(
                  title: 'Агенты',
                  items: agents.map((agent) => agent.name).toList(),
                ),
                _LinkSection(
                  title: 'Инструменты',
                  items: tools.map((tool) => tool.name).toList(),
                ),
                _LinkSection(
                  title: 'Сценарии',
                  items: workflows.map((workflow) => workflow.title).toList(),
                ),
                _LinkSection(
                  title: 'Промпты',
                  items: prompts.map((prompt) => prompt.title).toList(),
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
        ],
      ),
    );
  }
}

class _LinkSection extends StatelessWidget {
  const _LinkSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: 'Связано по ID в seed data.'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final item in items) Chip(label: Text(item))],
          ),
        ],
      ),
    );
  }
}
