import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../state/app_settings.dart';
import '../widgets/responsive_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

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
            ListTile(
              title: const Text('Стартовый экран'),
              subtitle: const Text(
                'Куда приложение откроется при следующем запуске.',
              ),
              trailing: DropdownButton<AppDestination>(
                value: settings.startupDestination,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
