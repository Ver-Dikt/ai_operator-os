import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/seed_director_presets.dart';
import '../../models/generation/director_preset.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/responsive_page.dart';

class DirectorScreen extends StatefulWidget {
  const DirectorScreen({super.key});

  @override
  State<DirectorScreen> createState() => _DirectorScreenState();
}

class _DirectorScreenState extends State<DirectorScreen> {
  final TextEditingController _prompt = TextEditingController(
    text: 'одинокий герой входит в пустой вокзал перед рассветом',
  );
  DirectorPreset _preset = seedDirectorPresets.first;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compiled = _preset.buildPrompt(_prompt.text);
    return ResponsivePage(
      title: 'Режиссёр',
      subtitle:
          'Камера, объектив, свет и движение как reusable cinematic preset.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _prompt,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Сцена',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in seedDirectorPresets)
                ChoiceChip(
                  label: Text(preset.name),
                  selected: preset.id == _preset.id,
                  onSelected: (_) => setState(() => _preset = preset),
                ),
            ],
          ),
          const SizedBox(height: 16),
          OsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _preset.description,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(compiled),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(_preset.camera.name)),
                    Chip(label: Text('${_preset.camera.focalLength} mm')),
                    Chip(label: Text(_preset.camera.aperture)),
                    for (final tag in _preset.moodTags) Chip(label: Text(tag)),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: compiled));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Режиссёрский промпт скопирован'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать промпт'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
