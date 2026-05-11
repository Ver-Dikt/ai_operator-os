import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../widgets/responsive_page.dart';
import '../widgets/tool_grid.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final favorites = settings.favoriteTools;

    return ResponsivePage(
      title: 'Избранное',
      subtitle: 'Локальная подборка инструментов, которые нужны чаще всего.',
      child: favorites.isEmpty
          ? const _EmptyFavorites()
          : ToolGrid(tools: favorites),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.star_border,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Пока пусто. Открой каталог и отметь нужные инструменты звездочкой.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
