import 'package:flutter/material.dart';

import '../../ai_operator_app.dart';
import '../../data/seed_workflows.dart';
import '../../models/workflow_template.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/chips/status_badge.dart';
import '../../widgets/responsive_page.dart';

class WorkflowsScreen extends StatefulWidget {
  const WorkflowsScreen({super.key});

  @override
  State<WorkflowsScreen> createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends State<WorkflowsScreen> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...seedWorkflows.map((w) => w.category).toSet()];
    final workflows = seedWorkflows
        .where(
          (workflow) => _category == 'All' || workflow.category == _category,
        )
        .toList();
    return ResponsivePage(
      title: 'Workflows',
      subtitle:
          'Production-ready templates with steps, prompts, tools and mock execution mode.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final workflow in workflows) ...[
            _WorkflowCard(workflow: workflow),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.workflow});

  final WorkflowTemplate workflow;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final favorite = settings.isFavoriteWorkflow(workflow.id);
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  workflow.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: () => settings.toggleFavoriteWorkflow(workflow.id),
                icon: Icon(
                  favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
          Text(workflow.description),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(label: workflow.category),
              StatusBadge(label: workflow.difficulty.name),
              StatusBadge(label: workflow.costLevel.name),
              StatusBadge(label: workflow.estimatedTime),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tool in workflow.requiredTools.take(5))
                Chip(label: Text(tool)),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WorkflowRunScreen(workflow: workflow),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Workflow'),
          ),
        ],
      ),
    );
  }
}

class WorkflowRunScreen extends StatefulWidget {
  const WorkflowRunScreen({super.key, required this.workflow});

  final WorkflowTemplate workflow;

  @override
  State<WorkflowRunScreen> createState() => _WorkflowRunScreenState();
}

class _WorkflowRunScreenState extends State<WorkflowRunScreen> {
  final Set<String> _done = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.workflow.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.workflow.description,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          for (final step in widget.workflow.steps)
            OsCard(
              padding: const EdgeInsets.all(12),
              child: CheckboxListTile(
                value: _done.contains(step.id),
                onChanged: (value) => setState(() {
                  if (value ?? false) {
                    _done.add(step.id);
                  } else {
                    _done.remove(step.id);
                  }
                }),
                title: Text(step.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.instruction),
                    const SizedBox(height: 6),
                    SelectableText(step.promptTemplate),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
        ],
      ),
    );
  }
}
