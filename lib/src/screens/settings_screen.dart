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
      title: 'Настройки',
      subtitle:
          'Локальные настройки Phase 1. API-ключи пока только заглушки и не используются backend-ом.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OsCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.darkMode,
                  onChanged: settings.setDarkMode,
                  title: const Text('Тёмная тема'),
                  subtitle: const Text(
                    'Переключает состояние UI и сохраняется локально. Тёмная тема остаётся режимом по умолчанию.',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.compactCards,
                  onChanged: settings.setCompactCards,
                  title: const Text('Компактные карточки'),
                  subtitle: const Text(
                    'Более плотные сетки для desktop-экранов.',
                  ),
                ),
                const Divider(height: 1),
                _DestinationTile(settings: settings),
                const Divider(height: 1),
                _ModeTile(settings: settings),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Local tools later'),
                  subtitle: Text(
                    'Ollama, ComfyUI и локальный runtime будут подключаться на Integration Layer.',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('API keys later'),
                  subtitle: Text(
                    'Ключи не сохраняются во frontend; безопасное хранение появится позже.',
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
                  title: 'Локальный режим',
                  subtitle: 'Подготовлено для Ollama и локальных адаптеров.',
                ),
                TextFormField(
                  initialValue: settings.ollamaBaseUrl,
                  decoration: const InputDecoration(
                    labelText: 'Базовый URL Ollama',
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
                  title: 'Заглушки API-ключей',
                  subtitle:
                      'Не храни production-секреты во frontend-сборке. Шифрование на backend появится позже.',
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
                        labelText: '$key API-ключ',
                        hintText: 'Для безопасного хранения нужен backend',
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
                  title: 'Акцент темы',
                  subtitle: 'Сохраняется локально для будущих вариантов темы.',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final accent in [
                      ('cyan', 'Голубой'),
                      ('amber', 'Янтарный'),
                      ('rose', 'Розовый'),
                    ])
                      ChoiceChip(
                        label: Text(accent.$2),
                        selected: settings.themeAccent == accent.$1,
                        onSelected: (_) => settings.setThemeAccent(accent.$1),
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
              'Стартовый экран',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            dropdown,
          ],
        ),
      );
    }

    return ListTile(
      title: const Text('Стартовый экран'),
      subtitle: const Text('Где AI Operator OS откроется в следующий раз.'),
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
      title: const Text('Режим по умолчанию'),
      subtitle: const Text(
        'Предпочтение маршрутизации: local / cloud / hybrid.',
      ),
      trailing: DropdownButton<OperatorMode>(
        value: settings.operatorMode,
        onChanged: (value) {
          if (value != null) settings.setOperatorMode(value);
        },
        items: [
          for (final mode in OperatorMode.values)
            DropdownMenuItem(value: mode, child: Text(mode.label)),
        ],
      ),
    );
  }
}
