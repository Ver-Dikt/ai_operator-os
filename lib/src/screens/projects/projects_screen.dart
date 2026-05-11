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
          'Здесь будут жить сохранённые планы: кейс, агенты, инструменты, промпты и прогресс сценария.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          OsCard(
            child: EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'Хранилище проектов подготовлено',
              message:
                  'В Phase 1 выполнение остаётся mock-only. В следующем этапе можно сохранять планы и прогресс локально.',
            ),
          ),
        ],
      ),
    );
  }
}
