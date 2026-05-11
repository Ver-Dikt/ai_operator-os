import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../data/catalog.dart';
import '../widgets/documentary_hero.dart';
import '../widgets/responsive_page.dart';
import '../widgets/stat_tile.dart';
import '../widgets/workflow_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenCatalog});

  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final categoriesCount = toolsCatalog
        .map((tool) => tool.category)
        .toSet()
        .length;

    return ResponsivePage(
      title: 'Главная',
      subtitle:
          'Короткий обзор базы. Для работы открывай каталог: выбирай категорию, смотри группы доступа и запускай нужный сервис.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DocumentaryHero(
            toolsCount: toolsCatalog.length,
            favoriteCount: settings.favoriteIds.length,
            onOpenCatalog: onOpenCatalog,
          ),
          const SizedBox(height: 18),
          const _HowItWorksPanel(),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatTile(
                label: 'Инструменты',
                value: toolsCatalog.length.toString(),
              ),
              StatTile(label: 'Категории', value: categoriesCount.toString()),
              StatTile(
                label: 'Избранное',
                value: settings.favoriteIds.length.toString(),
              ),
              const StatTile(label: 'Платформа', value: 'Web + Desktop'),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Рабочие цепочки',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
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
                itemCount: workflowsCatalog.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 260,
                ),
                itemBuilder: (context, index) =>
                    WorkflowCard(workflow: workflowsCatalog[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HowItWorksPanel extends StatelessWidget {
  const _HowItWorksPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11130F),
        border: Border.all(color: const Color(0xFF34382E)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.route_outlined, color: Color(0xFFE8DCC2)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Как пользоваться: каталог показывает инструменты по выбранной категории. Внутри они разделены на бесплатные, с бесплатным лимитом, локальные и платные. В каждой группе сверху стоят более сильные варианты. Звезда сохраняет инструмент в избранное.',
              style: TextStyle(color: Color(0xFFC7BEA8), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
