import 'package:flutter/material.dart';

import '../../widgets/cards/os_card.dart';
import '../../widgets/responsive_page.dart';

class SocialIntelligenceScreen extends StatelessWidget {
  const SocialIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const modules = [
      ('Анализ hook', 'Первые 1-3 секунды, обещание, визуальный контраст.'),
      ('Retention diagnostics', 'Где зритель теряет внимание и почему.'),
      (
        'Viral patterns',
        'Повторяемые структуры роликов, темп, монтажные петли.',
      ),
      (
        'Remake suggestions',
        'Как пересобрать идею под Reels, Shorts и TikTok.',
      ),
      ('Trend radar', 'Будущий анализ трендов и ниш.'),
    ];
    return ResponsivePage(
      title: 'Соцаналитика',
      subtitle:
          'Архитектура для Reels analysis, hooks, retention и рекомендаций по ремейкам.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OsCard(
            child: ListTile(
              leading: Icon(Icons.construction_rounded),
              title: Text('Раздел в подготовке'),
              subtitle: Text(
                'Будет подключён после основного generation workflow. Сейчас это карта будущих модулей без анализа файлов или соцсетей.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final module in modules)
                SizedBox(
                  width: 340,
                  child: OsCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.query_stats_rounded),
                      title: Text(module.$1),
                      subtitle: Text(module.$2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
