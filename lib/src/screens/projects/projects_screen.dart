import 'package:flutter/material.dart';

import '../../widgets/cards/os_card.dart';
import '../../widgets/empty_states/empty_state.dart';
import '../../widgets/responsive_page.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      title: 'Projects',
      subtitle:
          'Saved execution results will live here: selected use case, agents, tools, prompts and workflow progress.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          OsCard(
            child: EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'Project storage is prepared',
              message:
                  'Phase 1 keeps execution mock-only. Next phase can save generated plans and workflow progress locally.',
            ),
          ),
        ],
      ),
    );
  }
}
