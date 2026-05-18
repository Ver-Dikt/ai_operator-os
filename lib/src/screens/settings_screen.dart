import 'package:flutter/material.dart';

import '../ai_operator_app.dart';
import '../models/ai_provider.dart';
import '../models/execution_mode.dart';
import '../services/provider_registry.dart';
import '../state/app_settings.dart';
import '../widgets/cards/os_card.dart';
import '../widgets/responsive_page.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, TextEditingController> _keyControllers = {};
  final Set<String> _mockConnected = {};

  @override
  void dispose() {
    for (final controller in _keyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(AiProvider provider) {
    return _keyControllers.putIfAbsent(provider.id, TextEditingController.new);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final providers = const ProviderRegistry().getAllProviders();

    return ResponsivePage(
      title: 'Настройки',
      subtitle: 'Локальные настройки runtime, провайдеров и режима оператора.',
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
                  title: Text('Provider Manager'),
                  subtitle: Text(
                    'Runtime providers, manual fallback, local endpoints and API key placeholders.',
                  ),
                  trailing: Icon(Icons.hub_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProviderManagerPanel(
            providers: providers,
            mockConnected: _mockConnected,
            controllerFor: _controllerFor,
            onConnect: (provider) => setState(() {
              if (provider.apiKeyRequired &&
                  _controllerFor(provider).text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${provider.name}: добавь mock key локально'),
                  ),
                );
                return;
              }
              _mockConnected.add(provider.id);
            }),
            onDisconnect: (provider) =>
                setState(() => _mockConnected.remove(provider.id)),
            onClear: (provider) => setState(() {
              _controllerFor(provider).clear();
              _mockConnected.remove(provider.id);
            }),
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

class _ProviderManagerPanel extends StatelessWidget {
  const _ProviderManagerPanel({
    required this.providers,
    required this.mockConnected,
    required this.controllerFor,
    required this.onConnect,
    required this.onDisconnect,
    required this.onClear,
  });

  final List<AiProvider> providers;
  final Set<String> mockConnected;
  final TextEditingController Function(AiProvider provider) controllerFor;
  final ValueChanged<AiProvider> onConnect;
  final ValueChanged<AiProvider> onDisconnect;
  final ValueChanged<AiProvider> onClear;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Provider / API Manager',
            subtitle:
                'Операторская карта runtime-провайдеров. Реальные API и health checks пока не подключены.',
          ),
          const SizedBox(height: 8),
          const _FallbackNotice(),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              if (compact) {
                return Column(
                  children: [
                    for (final provider in providers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProviderCard(
                          provider: provider,
                          connected: mockConnected.contains(provider.id),
                          controller: controllerFor(provider),
                          onConnect: () => onConnect(provider),
                          onDisconnect: () => onDisconnect(provider),
                          onClear: () => onClear(provider),
                        ),
                      ),
                  ],
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final provider in providers)
                    SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: _ProviderCard(
                        provider: provider,
                        connected: mockConnected.contains(provider.id),
                        controller: controllerFor(provider),
                        onConnect: () => onConnect(provider),
                        onDisconnect: () => onDisconnect(provider),
                        onClear: () => onClear(provider),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.connected,
    required this.controller,
    required this.onConnect,
    required this.onDisconnect,
    required this.onClear,
  });

  final AiProvider provider;
  final bool connected;
  final TextEditingController controller;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final showKeyField = provider.apiKeyRequired;
    final showLocalPanel =
        provider.type == AiProviderType.local ||
        provider.id == 'n8n' ||
        provider.localEndpoint != null;
    final statusLabel = connected ? 'Mock Connected' : provider.status.label;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RuntimeChip(statusLabel),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _RuntimeChip(provider.type.label),
                for (final workspace in provider.supportedWorkspaces)
                  _RuntimeChip(workspace.toUpperCase()),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final mode in provider.executionModes)
                  _RuntimeChip(_modeLabel(mode)),
              ],
            ),
            if (showLocalPanel) ...[
              const SizedBox(height: 12),
              _ProviderInfoLine(
                label: 'Endpoint',
                value: provider.localEndpoint ?? provider.baseUrl ?? 'Not set',
              ),
              _ProviderInfoLine(
                label: 'Runtime',
                value: provider.type == AiProviderType.local
                    ? 'Local runtime'
                    : 'Hybrid runtime',
              ),
            ],
            if (showKeyField) ...[
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '${provider.name} API Key',
                  hintText: 'Mock local field only',
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onConnect,
                  child: const Text('Connect'),
                ),
                TextButton(
                  onPressed: onDisconnect,
                  child: const Text('Disconnect'),
                ),
                TextButton(onPressed: onClear, child: const Text('Clear')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.open_in_browser_rounded, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Fallback: Manual Browser Launch остаётся безопасным маршрутом, если API или local runtime не настроены.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuntimeChip extends StatelessWidget {
  const _RuntimeChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _ProviderInfoLine extends StatelessWidget {
  const _ProviderInfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _modeLabel(ExecutionMode mode) {
  return switch (mode) {
    ExecutionMode.demo => 'manual',
    ExecutionMode.manual => 'manual',
    ExecutionMode.browserLaunch => 'browserLaunch',
    ExecutionMode.api => 'api',
    ExecutionMode.local => 'local',
  };
}
