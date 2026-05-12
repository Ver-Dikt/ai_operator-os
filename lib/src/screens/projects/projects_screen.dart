import 'package:flutter/material.dart';

import '../../widgets/cards/os_card.dart';
import '../../widgets/empty_states/empty_state.dart';
import '../../widgets/responsive_page.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      title: 'Проекты',
      subtitle:
          'Здесь будут храниться сохранённые планы: кейсы, AI-помощники, инструменты, промпты и прогресс.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          OsCard(
            child: EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'Хранилище проектов подготовлено',
              message:
                  'В Phase 1 выполнение остаётся в демо-режиме. На следующем этапе можно будет сохранять планы и прогресс локально.',
            ),
          ),
        ],
      ),
    );
  }
}
