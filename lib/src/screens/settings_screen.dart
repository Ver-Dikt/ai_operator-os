import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../state/app_settings.dart';
import '../widgets/responsive_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 560;

    return ResponsivePage(
      title: 'Настройки',
      subtitle:
          'Параметры сохраняются локально и работают в web-preview и Windows desktop.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            SwitchListTile(
              value: settings.compactCards,
              onChanged: settings.setCompactCards,
              title: const Text('Компактные карточки'),
              subtitle: const Text(
                'Плотная сетка для больших desktop-экранов.',
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              value: settings.showSensitiveTools,
              onChanged: settings.setShowSensitiveTools,
              title: const Text('Показывать экспериментальные инструменты'),
              subtitle: const Text(
                'По умолчанию такие карточки скрыты из каталога.',
              ),
            ),
            const Divider(height: 1),
            isCompact
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Стартовый экран',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Куда приложение откроется при следующем запуске.',
                          style: TextStyle(color: Color(0xFFA7B1C1)),
                        ),
                        const SizedBox(height: 10),
                        _StartupDropdown(settings: settings),
                      ],
                    ),
                  )
                : ListTile(
                    title: const Text('Стартовый экран'),
                    subtitle: const Text(
                      'Куда приложение откроется при следующем запуске.',
                    ),
                    trailing: _StartupDropdown(settings: settings),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StartupDropdown extends StatelessWidget {
  const _StartupDropdown({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<AppDestination>(
      value: settings.startupDestination,
      isExpanded: MediaQuery.sizeOf(context).width < 560,
      onChanged: (value) {
        if (value != null) {
          settings.setStartupDestination(value);
        }
      },
      items: const [
        DropdownMenuItem(
          value: AppDestination.dashboard,
          child: Text('Пульт'),
        ),
        DropdownMenuItem(
          value: AppDestination.catalog,
          child: Text('Каталог'),
        ),
        DropdownMenuItem(
          value: AppDestination.favorites,
          child: Text('Избранное'),
        ),
        DropdownMenuItem(
          value: AppDestination.settings,
          child: Text('Настройки'),
        ),
      ],
    );
  }
}
