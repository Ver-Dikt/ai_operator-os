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
    text: 'Make a cinematic AI video for a music release',
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
      title: 'Model Router',
      subtitle:
          'Rule-based routing for Phase 1: best paid, best free, local, fast and workflow path.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _task,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.route_rounded),
              hintText: 'Describe your task...',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => setState(() {
              _recommendation = const RouterService().recommend(_task.text);
            }),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Recommend stack'),
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
                _Line('Best quality', _recommendation.bestPaidTools),
                _Line('Free test', _recommendation.bestFreeTools),
                _Line('Local', _recommendation.localOptions),
                _TextLine('Workflow', _recommendation.recommendedWorkflow),
                _TextLine('Cost', _recommendation.estimatedCost),
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
