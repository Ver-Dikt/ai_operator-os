import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ai_operator_app.dart';
import '../../data/seed_prompts.dart';
import '../../models/prompt_template.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/responsive_page.dart';

class PromptStudioScreen extends StatefulWidget {
  const PromptStudioScreen({super.key});

  @override
  State<PromptStudioScreen> createState() => _PromptStudioScreenState();
}

class _PromptStudioScreenState extends State<PromptStudioScreen> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...seedPrompts.map((p) => p.category).toSet()];
    final prompts = seedPrompts
        .where((prompt) => _category == 'All' || prompt.category == _category)
        .toList();

    return ResponsivePage(
      title: 'Prompt Studio',
      subtitle:
          'Prompt templates with variables, recommended tools, copy actions and favorite state.',
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
          for (final prompt in prompts) ...[
            _PromptCard(prompt: prompt),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt});

  final PromptTemplate prompt;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final favorite = settings.isFavoritePrompt(prompt.id);
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prompt.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: () => settings.toggleFavoritePrompt(prompt.id),
                icon: Icon(
                  favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
          Text('${prompt.category} • ${prompt.style}'),
          const SizedBox(height: 10),
          SelectableText(prompt.template),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final variable in prompt.variables)
                Chip(label: Text('{{$variable}}')),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: prompt.template));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Copied ${prompt.title}')));
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy prompt'),
          ),
        ],
      ),
    );
  }
}
