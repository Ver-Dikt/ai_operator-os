import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../state/app_settings.dart';
import '../widgets/cards/os_card.dart';
import '../widgets/responsive_page.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return ResponsivePage(
      title: 'Settings',
      subtitle:
          'Local settings for Phase 1. API keys are placeholders and are not used by a backend yet.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OsCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.compactCards,
                  onChanged: settings.setCompactCards,
                  title: const Text('Compact cards'),
                  subtitle: const Text('Denser grids for desktop screens.'),
                ),
                const Divider(height: 1),
                _DestinationTile(settings: settings),
                const Divider(height: 1),
                _ModeTile(settings: settings),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Local Mode',
                  subtitle: 'Prepared for Ollama and local adapters.',
                ),
                TextFormField(
                  initialValue: settings.ollamaBaseUrl,
                  decoration: const InputDecoration(
                    labelText: 'Ollama base URL',
                    hintText: 'http://localhost:11434',
                  ),
                  onFieldSubmitted: settings.setOllamaBaseUrl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'API Keys Placeholder',
                  subtitle:
                      'Do not store production secrets in this frontend build. Backend encryption comes later.',
                ),
                for (final key in [
                  'OpenAI',
                  'OpenRouter',
                  'Kling',
                  'Runway',
                  'ElevenLabs',
                  'Google',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: '$key API key',
                        hintText: 'Backend required for secure storage',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Theme Accent',
                  subtitle: 'Stored locally for future theme variants.',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final accent in ['cyan', 'amber', 'rose'])
                      ChoiceChip(
                        label: Text(accent),
                        selected: settings.themeAccent == accent,
                        onSelected: (_) => settings.setThemeAccent(accent),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final dropdown = DropdownButton<AppDestination>(
      value: settings.startupDestination,
      isExpanded: compact,
      onChanged: (value) {
        if (value != null) settings.setStartupDestination(value);
      },
      items: [
        for (final destination in AppDestination.values)
          DropdownMenuItem(value: destination, child: Text(destination.label)),
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Startup screen',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            dropdown,
          ],
        ),
      );
    }

    return ListTile(
      title: const Text('Startup screen'),
      subtitle: const Text('Where AI Operator OS opens next time.'),
      trailing: SizedBox(width: 220, child: dropdown),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Default mode'),
      subtitle: const Text('Local / cloud / hybrid routing preference.'),
      trailing: DropdownButton<OperatorMode>(
        value: settings.operatorMode,
        onChanged: (value) {
          if (value != null) settings.setOperatorMode(value);
        },
        items: [
          for (final mode in OperatorMode.values)
            DropdownMenuItem(value: mode, child: Text(mode.name)),
        ],
      ),
    );
  }
}
