import 'package:flutter/material.dart';

import '../../ai_operator_app.dart';
import '../../data/seed_tools.dart';
import '../../models/ai_tool.dart';
import '../../services/graph_repository.dart';
import '../../services/url_service.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/chips/status_badge.dart';
import '../../widgets/responsive_page.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _query = TextEditingController();
  String _quickFilter = 'all';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final tools = _filtered(settings.visibleTools);

    return ResponsivePage(
      title: 'Инструменты',
      subtitle:
          'База нейросетей: задачи, платформы, цена, API, локальный режим и production-подход.',
      actions: [
        OutlinedButton.icon(
          onPressed: settings.resetCatalogFilters,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Сбросить'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _query,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Ищи: видео, локально, без карты, кодинг...',
            ),
            onChanged: settings.setQuery,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Все'),
                selected: _quickFilter == 'all',
                onSelected: (_) => setState(() => _quickFilter = 'all'),
              ),
              for (final filter in defaultToolFilters)
                ChoiceChip(
                  label: Text(_quickFilterLabel(filter)),
                  selected: _quickFilter == filter,
                  onSelected: (_) => setState(() => _quickFilter = filter),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in settings.categories)
                ChoiceChip(
                  label: Text(category),
                  selected: settings.selectedCategory == category,
                  onSelected: (_) => settings.setCategory(category),
                ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 3
                  : constraints.maxWidth >= 720
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tools.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 346,
                ),
                itemBuilder: (context, index) =>
                    _ToolV2Card(tool: tools[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  List<AiTool> _filtered(List<AiTool> tools) {
    return tools.where((tool) {
      return switch (_quickFilter) {
        'all' => true,
        'free' => tool.isFreePath,
        'api' => tool.hasApi,
        'video' =>
          tool.category == ToolCategory.video || tool.tags.contains('video'),
        'music' => tool.category == ToolCategory.music,
        'local' => tool.isLocal || tool.pricingType == PricingType.local,
        'no credit card' => tool.isFreePath && !tool.tags.contains('paid'),
        'fast' => tool.tags.contains('fast'),
        'professional' => tool.tags.contains('professional'),
        _ => true,
      };
    }).toList();
  }

  String _quickFilterLabel(String filter) {
    return switch (filter) {
      'free' => 'Бесплатно',
      'api' => 'API',
      'video' => 'Видео',
      'music' => 'Музыка',
      'local' => 'Local',
      'no credit card' => 'Без карты',
      'fast' => 'Быстро',
      'professional' => 'Профи',
      _ => filter,
    };
  }
}

class _ToolV2Card extends StatelessWidget {
  const _ToolV2Card({required this.tool});

  final AiTool tool;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isFavorite = settings.isFavorite(tool.id);
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tool.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Убрать из избранного' : 'Сохранить',
                onPressed: () => settings.toggleFavorite(tool.id),
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(label: tool.category.label),
              StatusBadge(
                label: tool.pricingType.label,
                color: tool.pricingType == PricingType.local
                    ? const Color(0xFFFFB86B)
                    : const Color(0xFF6BE4C9),
              ),
              if (tool.hasApi) const StatusBadge(label: 'API'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tool.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFC8D2E1), height: 1.35),
          ),
          const SizedBox(height: 10),
          Text(
            'Лучше всего для: ${tool.bestFor}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8B97A8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => const UrlService().open(tool.url),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Открыть'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Подробнее',
                onPressed: () => _showDetails(context, tool),
                icon: const Icon(Icons.notes_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, AiTool tool) {
    final graph = const GraphRepository();
    final agents = graph.agentsByIds(tool.agentIds);
    final workflows = graph.workflowsByIds(tool.workflowIds);
    final useCases = [
      ...graph.useCasesByIds(tool.useCaseIds),
      ...graph.useCasesForTool(tool.id),
    ];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tool.name),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tool.description),
                const SizedBox(height: 12),
                Text('Бесплатные лимиты: ${tool.freeCreditsInfo}'),
                const SizedBox(height: 8),
                Text('Ограничения: ${tool.limitations}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in tool.tags) Chip(label: Text(tag)),
                  ],
                ),
                const SizedBox(height: 12),
                _LinkedSection(
                  title: 'Агенты, которые могут использовать',
                  items: agents.map((agent) => agent.name).toList(),
                ),
                _LinkedSection(
                  title: 'Сценарии',
                  items: workflows.map((workflow) => workflow.title).toList(),
                ),
                _LinkedSection(
                  title: 'Кейсы',
                  items: useCases
                      .map((useCase) => useCase.title)
                      .toSet()
                      .toList(),
                ),
                _LinkedSection(
                  title: 'Альтернативы',
                  items: graph
                      .toolsByIds(tool.alternativeToolIds)
                      .map((item) => item.name)
                      .toList(),
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
            onPressed: () => const UrlService().open(tool.url),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Открыть инструмент'),
          ),
        ],
      ),
    );
  }
}

class _LinkedSection extends StatelessWidget {
  const _LinkedSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
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
