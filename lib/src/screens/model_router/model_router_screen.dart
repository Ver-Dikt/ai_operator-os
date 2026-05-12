import 'package:flutter/material.dart';

import '../../services/router_service.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/responsive_page.dart';

class ModelRouterScreen extends StatefulWidget {
  const ModelRouterScreen({super.key});

  @override
  State<ModelRouterScreen> createState() => _ModelRouterScreenState();
}

class _ModelRouterScreenState extends State<ModelRouterScreen> {
  final TextEditingController _task = TextEditingController(
    text: 'Сделать кинематографичное AI-видео для музыкального релиза',
  );
  late var _recommendation = const RouterService().recommend(_task.text);

  @override
  void dispose() {
    _task.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      title: 'Маршрутизатор моделей',
      subtitle:
          'Демо-маршрутизация без API: лучший платный путь, бесплатный путь, Local-вариант и план работы.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _task,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.route_rounded),
              hintText: 'Опиши задачу...',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => setState(() {
              _recommendation = const RouterService().recommend(_task.text);
            }),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Подобрать стек'),
          ),
          const SizedBox(height: 18),
          OsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recommendation.task,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                _Line('Лучшее качество', _recommendation.bestPaidTools),
                _Line('Бесплатный тест', _recommendation.bestFreeTools),
                _Line('Local', _recommendation.localOptions),
                _TextLine('План работы', _recommendation.recommendedWorkflow),
                _TextLine('Стоимость', _recommendation.estimatedCost),
                const SizedBox(height: 8),
                for (final note in _recommendation.notes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline_rounded),
                    title: Text(note),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.values);

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(label: Text(label)),
          for (final value in values) Chip(label: Text(value)),
        ],
      ),
    );
  }
}

class _TextLine extends StatelessWidget {
  const _TextLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value'),
    );
  }
}
