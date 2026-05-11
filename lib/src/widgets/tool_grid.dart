import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../models/tool_item.dart';
import 'tool_card.dart';

class ToolGrid extends StatelessWidget {
  const ToolGrid({super.key, required this.tools});

  final List<ToolItem> tools;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    if (tools.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111722),
          border: Border.all(color: const Color(0xFF263244)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_off_rounded, color: Color(0xFF8B97A8)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ничего не найдено. Попробуй другой запрос, тег или категорию.',
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 3
            : constraints.maxWidth >= 720
            ? 2
            : 1;
        final isPhone = constraints.maxWidth < 520;
        final extent = isPhone
            ? 536.0
            : settings.compactCards
            ? 430.0
            : 506.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tools.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: extent,
          ),
          itemBuilder: (context, index) => ToolCard(tool: tools[index]),
        );
      },
    );
  }
}
