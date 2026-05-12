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
  String _category = 'Все';

  @override
  Widget build(BuildContext context) {
    final categories = ['Все', ...seedPrompts.map((p) => p.category).toSet()];
    final prompts = seedPrompts
        .where((prompt) => _category == 'Все' || prompt.category == _category)
        .toList();

    return ResponsivePage(
      title: 'Студия промптов',
      subtitle:
          'Шаблоны промптов с русским объяснением и рабочим RU/EN текстом для моделей.',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(label: Text(prompt.languageMode.badge)),
              Text('${prompt.category} • ${prompt.style}'),
            ],
          ),
          const SizedBox(height: 10),
          Text(prompt.descriptionRu),
          const SizedBox(height: 8),
          _PromptInfo(label: 'Когда использовать', value: prompt.whenToUseRu),
          _PromptInfo(label: 'RU объяснение', value: prompt.ruExplanation),
          const SizedBox(height: 10),
          const Text(
            'Рабочий промпт',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (prompt.languageMode == PromptLanguageMode.ruEn) ...[
                FilledButton.icon(
                  onPressed: () => _copy(context, prompt.template),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать EN-промпт'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copy(context, prompt.ruExplanation),
                  icon: const Icon(Icons.translate_rounded),
                  label: const Text('Скопировать RU-описание'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copy(context, prompt.copyAllText),
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text('Скопировать всё'),
                ),
              ] else
                FilledButton.icon(
                  onPressed: () => _copy(context, prompt.template),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать промпт'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Скопировано')));
  }
}

class _PromptInfo extends StatelessWidget {
  const _PromptInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
