import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../data/catalog.dart';
import '../models/tool_item.dart';
import '../widgets/filter_bar.dart';
import '../widgets/responsive_page.dart';
import '../widgets/tool_grid.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    if (_searchController.text != settings.query) {
      _searchController.text = settings.query;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }

    return ResponsivePage(
      title: 'Каталог',
      subtitle:
          'Быстро подбирай сервис под задачу. Категории отвечают за направление, теги уточняют сценарий, группы доступа помогают выбрать: бесплатно, локально или premium.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CatalogCommandPanel(
            visibleCount: settings.visibleTools.length,
            totalCount: toolsCatalog.length,
            selectedCategory: settings.selectedCategory,
            selectedTag: settings.selectedTag,
            favoritesCount: settings.favoriteIds.length,
            onReset: () {
              settings.resetCatalogFilters();
              _searchController.clear();
            },
          ),
          const SizedBox(height: 14),
          SearchBar(
            controller: _searchController,
            hintText:
                'Найти сервис, сценарий или тег: video, local, tts, Flux, n8n...',
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (settings.query.isNotEmpty)
                IconButton(
                  tooltip: 'Очистить поиск',
                  onPressed: () {
                    _searchController.clear();
                    settings.setQuery('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
            onChanged: settings.setQuery,
          ),
          const SizedBox(height: 12),
          FilterBar(
            categories: settings.categories,
            selectedCategory: settings.selectedCategory,
            tags: defaultTags,
            selectedTag: settings.selectedTag,
            onCategoryChanged: settings.setCategory,
            onTagChanged: settings.setTag,
          ),
          const SizedBox(height: 18),
          _GroupedToolResults(tools: settings.visibleTools),
        ],
      ),
    );
  }
}

class _CatalogCommandPanel extends StatelessWidget {
  const _CatalogCommandPanel({
    required this.visibleCount,
    required this.totalCount,
    required this.selectedCategory,
    required this.selectedTag,
    required this.favoritesCount,
    required this.onReset,
  });

  final int visibleCount;
  final int totalCount;
  final String selectedCategory;
  final String selectedTag;
  final int favoritesCount;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final activeTag = selectedTag == 'all' ? 'все теги' : selectedTag;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxMetricWidth = screenWidth < 560 ? screenWidth - 56 : 320.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC0E131C),
        border: Border.all(color: const Color(0xFF263244)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 12,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                icon: Icons.grid_view_rounded,
                label: 'Показано',
                value: '$visibleCount / $totalCount',
                maxWidth: maxMetricWidth,
              ),
              _MetricPill(
                icon: Icons.category_outlined,
                label: 'Категория',
                value: selectedCategory,
                maxWidth: maxMetricWidth,
              ),
              _MetricPill(
                icon: Icons.sell_outlined,
                label: 'Тег',
                value: activeTag,
                maxWidth: maxMetricWidth,
              ),
              _MetricPill(
                icon: Icons.star_rounded,
                label: 'Избранное',
                value: '$favoritesCount',
                maxWidth: maxMetricWidth,
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.maxWidth,
  });

  final IconData icon;
  final String label;
  final String value;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111722),
          border: Border.all(color: const Color(0xFF263244)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: const Color(0xFF6BE4C9)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B97A8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8EEF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedToolResults extends StatelessWidget {
  const _GroupedToolResults({required this.tools});

  final List<ToolItem> tools;

  @override
  Widget build(BuildContext context) {
    if (tools.isEmpty) {
      return const ToolGrid(tools: []);
    }

    final grouped = <ToolAccess, List<ToolItem>>{};
    for (final tool in tools) {
      grouped.putIfAbsent(tool.access, () => <ToolItem>[]).add(tool);
    }

    final accessOrder = ToolAccess.values.toList()
      ..sort((a, b) => a.sortWeight.compareTo(b.sortWeight));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final access in accessOrder)
          if (grouped[access]?.isNotEmpty ?? false) ...[
            _AccessSectionHeader(
              access: access,
              count: grouped[access]!.length,
            ),
            const SizedBox(height: 10),
            ToolGrid(tools: grouped[access]!),
            const SizedBox(height: 24),
          ],
      ],
    );
  }
}

class _AccessSectionHeader extends StatelessWidget {
  const _AccessSectionHeader({required this.access, required this.count});

  final ToolAccess access;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x990E131C),
        border: Border.all(color: const Color(0xFF263244)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _accessColor(access),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              access.groupTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFF8FBFF),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF111722),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFFA7B1C1),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _accessColor(ToolAccess access) {
  return switch (access) {
    ToolAccess.free => const Color(0xFF6BE4C9),
    ToolAccess.freemium => const Color(0xFF9FB7FF),
    ToolAccess.paid => const Color(0xFFFFB86B),
    ToolAccess.local => const Color(0xFFB894FF),
    ToolAccess.sensitive => const Color(0xFFFF6B8A),
  };
}
