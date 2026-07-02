import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ai_operator_app.dart';
import '../models/ai_provider.dart';
import '../services/ace_step_health_service.dart';
import '../services/comfyui_health_service.dart';
import '../services/ollama_execution_service.dart';
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
  final _registry = const ProviderRegistry();
  final Map<String, TextEditingController> _keyControllers = {};
  final Map<String, TextEditingController> _baseUrlControllers = {};
  final Map<String, TextEditingController> _modelControllers = {};
  final Map<String, TextEditingController> _endpointControllers = {};
  final Map<String, TextEditingController> _uiEndpointControllers = {};
  final Map<String, TextEditingController> _workflowControllers = {};
  final Map<String, TextEditingController> _outputFolderControllers = {};
  final Map<String, bool> _apiEnabled = {};
  final Map<String, bool> _localEnabled = {};
  final Map<String, String> _localStatus = {};
  final Map<String, List<String>> _localModels = {};
  final Set<String> _checkingLocal = <String>{};
  bool _hydrated = false;
  bool _openedEventSent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    if (!_hydrated) {
      _hydrated = true;
      _hydrateControllers(settings);
    }
    if (!_openedEventSent) {
      _openedEventSent = true;
      unawaited(
        FlutenRuntimeScope.read(context).addEvent(
          type: 'settings',
          title: 'Provider settings opened',
          detail: 'Execution settings',
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in [
      ..._keyControllers.values,
      ..._baseUrlControllers.values,
      ..._modelControllers.values,
      ..._endpointControllers.values,
      ..._uiEndpointControllers.values,
      ..._workflowControllers.values,
      ..._outputFolderControllers.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _hydrateControllers(AppSettings settings) {
    for (final provider in _apiProviders) {
      _apiEnabled[provider.id] = settings.isProviderEnabled(provider.id);
      _keyControllers[provider.id] = TextEditingController();
      _baseUrlControllers[provider.id] = TextEditingController(
        text: settings.providerBaseUrl(
          provider.id,
          fallback: provider.baseUrl ?? '',
        ),
      );
      _modelControllers[provider.id] = TextEditingController(
        text: settings.providerModel(
          provider.id,
          fallback: _defaultModelFor(provider),
        ),
      );
    }
    for (final provider in _localProviders) {
      final endpoint = _defaultEndpointFor(provider);
      _localEnabled[provider.id] = settings.isLocalProviderEnabled(provider.id);
      _endpointControllers[provider.id] = TextEditingController(
        text: settings.localEndpoint(provider.id, fallback: endpoint),
      );
      if (provider.id == 'ollama') {
        _modelControllers[provider.id] = TextEditingController(
          text: settings.ollamaModel,
        );
        _localStatus[provider.id] = 'Не проверено';
      }
      if (provider.id == 'comfyui') {
        _workflowControllers[provider.id] = TextEditingController(
          text: settings.localWorkflowPath(provider.id),
        );
        _outputFolderControllers[provider.id] = TextEditingController(
          text: settings.localOutputFolder(provider.id),
        );
        _localStatus[provider.id] = 'Не проверено';
      }
      if (provider.id == 'ace-step') {
        _uiEndpointControllers[provider.id] = TextEditingController(
          text: settings.localUiEndpoint(
            provider.id,
            fallback: 'http://localhost:3001',
          ),
        );
        _localStatus[provider.id] = 'Не проверено';
      }
    }
  }

  List<AiProvider> get _apiProviders => _registry
      .getAllProviders()
      .where((provider) => provider.apiKeyRequired)
      .toList(growable: false);

  List<AiProvider> get _localProviders => _registry
      .getAllProviders()
      .where(
        (provider) =>
            provider.type == AiProviderType.local ||
            provider.localEndpoint != null,
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return ResponsivePage(
      title: 'Настройки запуска',
      subtitle:
          'Локальный vault для провайдеров, API-ключей, endpoint-ов и режимов выполнения. Реальные API-вызовы пока не подключены.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExecutionNotice(settings: settings),
          const SizedBox(height: 18),
          _GeneralSettings(settings: settings),
          const SizedBox(height: 18),
          _ApiProviderSettings(
            providers: _apiProviders,
            enabled: _apiEnabled,
            keyControllers: _keyControllers,
            baseUrlControllers: _baseUrlControllers,
            modelControllers: _modelControllers,
            settings: settings,
            onToggle: (provider, value) =>
                setState(() => _apiEnabled[provider.id] = value),
            onSave: _saveApiProvider,
            onClear: _clearApiProvider,
          ),
          const SizedBox(height: 18),
          _LocalProviderSettings(
            providers: _localProviders,
            enabled: _localEnabled,
            endpointControllers: _endpointControllers,
            uiEndpointControllers: _uiEndpointControllers,
            modelControllers: _modelControllers,
            workflowControllers: _workflowControllers,
            outputFolderControllers: _outputFolderControllers,
            statuses: _localStatus,
            models: _localModels,
            checking: _checkingLocal,
            onToggle: (provider, value) =>
                setState(() => _localEnabled[provider.id] = value),
            onSave: _saveLocalProvider,
            onCheck: _checkLocalProvider,
            onModelSelected: _selectLocalModel,
            onClearWorkflow: _clearLocalWorkflow,
            onOpenUi: _openLocalUi,
          ),
          const SizedBox(height: 18),
          const _BrowserManualSettings(),
          const SizedBox(height: 18),
          const _SafetySecretsPanel(),
        ],
      ),
    );
  }

  Future<void> _saveApiProvider(AiProvider provider) async {
    final settings = AppSettingsScope.of(context);
    await settings.saveProviderApiSettings(
      providerId: provider.id,
      enabled: _apiEnabled[provider.id] ?? false,
      apiKey: _keyControllers[provider.id]?.text ?? '',
      baseUrl: _baseUrlControllers[provider.id]?.text ?? provider.baseUrl ?? '',
      model: _modelControllers[provider.id]?.text ?? '',
    );
    _keyControllers[provider.id]?.clear();
    if (!mounted) return;
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'settings',
        title: 'API key saved',
        detail: provider.name,
      ),
    );
    _showMessage('${provider.name}: настройки сохранены. Ключ скрыт.');
  }

  Future<void> _clearApiProvider(AiProvider provider) async {
    final settings = AppSettingsScope.of(context);
    await settings.clearProviderApiKey(provider.id);
    _keyControllers[provider.id]?.clear();
    setState(() => _apiEnabled[provider.id] = false);
    if (!mounted) return;
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'settings',
        title: 'API key cleared',
        detail: provider.name,
      ),
    );
    _showMessage('${provider.name}: ключ очищен.');
  }

  Future<void> _saveLocalProvider(AiProvider provider) async {
    final settings = AppSettingsScope.of(context);
    final endpoint =
        _endpointControllers[provider.id]?.text ??
        _defaultEndpointFor(provider);
    await settings.saveLocalProviderSettings(
      providerId: provider.id,
      enabled: _localEnabled[provider.id] ?? false,
      endpoint: endpoint,
    );
    if (provider.id == 'ollama') {
      await settings.setOllamaModel(
        _modelControllers[provider.id]?.text.trim() ?? '',
      );
    }
    if (provider.id == 'comfyui') {
      await settings.saveLocalWorkflowSettings(
        providerId: provider.id,
        workflowPath: _workflowControllers[provider.id]?.text ?? '',
        outputFolder: _outputFolderControllers[provider.id]?.text ?? '',
      );
    }
    if (provider.id == 'ace-step') {
      await settings.saveLocalUiEndpoint(
        providerId: provider.id,
        uiEndpoint:
            _uiEndpointControllers[provider.id]?.text ??
            'http://localhost:3001',
      );
    }
    if (!mounted) return;
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'settings',
        title: 'Local endpoint saved',
        detail: provider.name,
      ),
    );
    _showMessage('${provider.name}: endpoint сохранён.');
  }

  Future<void> _checkLocalProvider(AiProvider provider) async {
    if (provider.id == 'ace-step') {
      await _checkAceStep(provider);
      return;
    }
    if (provider.id == 'comfyui') {
      await _checkComfyUi(provider);
      return;
    }
    if (provider.id != 'ollama') {
      _showMessage('Проверка будет подключена следующим этапом.');
      return;
    }
    final endpoint =
        _endpointControllers[provider.id]?.text.trim() ??
        _defaultEndpointFor(provider);
    final runtime = FlutenRuntimeScope.read(context);
    setState(() {
      _checkingLocal.add(provider.id);
      _localStatus[provider.id] = 'Проверяется...';
    });
    unawaited(
      runtime.addEvent(
        type: 'settings',
        title: 'Ollama health check started',
        detail: endpoint,
      ),
    );
    final result = await const OllamaExecutionService().checkHealth(
      endpoint: endpoint,
    );
    if (!mounted) return;
    setState(() {
      _checkingLocal.remove(provider.id);
      _localStatus[provider.id] = result.available
          ? 'Ollama доступна'
          : 'Ollama не отвечает';
      _localModels[provider.id] = result.models;
    });
    if (result.available) {
      unawaited(
        runtime.addEvent(
          type: 'settings',
          title: 'Ollama available',
          detail: result.models.isEmpty
              ? 'No models listed'
              : result.models.join(', '),
        ),
      );
      _showMessage('Ollama доступна.');
      return;
    }
    unawaited(
      runtime.addEvent(
        type: 'settings',
        title: 'Ollama unavailable',
        detail: result.error ?? endpoint,
      ),
    );
    _showMessage(
      'Ollama не отвечает. Проверьте, что она запущена на localhost:11434.',
    );
  }

  Future<void> _selectLocalModel(AiProvider provider, String model) async {
    _modelControllers[provider.id]?.text = model;
    final settings = AppSettingsScope.of(context);
    await settings.setOllamaModel(model);
    if (!mounted) return;
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(
        type: 'settings',
        title: 'Ollama model selected',
        detail: model,
      ),
    );
    _showMessage('Ollama model selected: $model');
  }

  Future<void> _checkComfyUi(AiProvider provider) async {
    final endpoint =
        _endpointControllers[provider.id]?.text.trim() ??
        _defaultEndpointFor(provider);
    final runtime = FlutenRuntimeScope.read(context);
    setState(() {
      _checkingLocal.add(provider.id);
      _localStatus[provider.id] = 'Проверяется...';
    });
    unawaited(
      runtime.addEvent(
        type: 'settings',
        title: 'ComfyUI health check started',
        detail: endpoint,
      ),
    );
    final result = await const ComfyUiHealthService().check(endpoint: endpoint);
    if (!mounted) return;
    setState(() {
      _checkingLocal.remove(provider.id);
      _localStatus[provider.id] = result.available
          ? 'ComfyUI доступна'
          : 'ComfyUI не отвечает';
    });
    if (result.available) {
      unawaited(
        runtime.addEvent(
          type: 'settings',
          title: 'ComfyUI available',
          detail: result.info ?? endpoint,
        ),
      );
      _showMessage('ComfyUI доступна.');
      return;
    }
    unawaited(
      runtime.addEvent(
        type: 'settings',
        title: 'ComfyUI unavailable',
        detail: result.error ?? endpoint,
      ),
    );
    _showMessage('ComfyUI не отвечает. Запустите ComfyUI на 127.0.0.1:8188.');
  }

  Future<void> _clearLocalWorkflow(AiProvider provider) async {
    if (provider.id != 'comfyui') return;
    _workflowControllers[provider.id]?.clear();
    await AppSettingsScope.of(context).clearLocalWorkflow(provider.id);
    if (!mounted) return;
    setState(() => _localStatus[provider.id] = 'Workflow не выбран');
    _showMessage('ComfyUI workflow очищен.');
  }

  Future<void> _checkAceStep(AiProvider provider) async {
    final apiEndpoint =
        _endpointControllers[provider.id]?.text.trim() ??
        _defaultEndpointFor(provider);
    final uiEndpoint =
        _uiEndpointControllers[provider.id]?.text.trim() ??
        'http://localhost:3001';
    final runtime = FlutenRuntimeScope.read(context);
    setState(() {
      _checkingLocal.add(provider.id);
      _localStatus[provider.id] = 'Проверяется...';
    });
    unawaited(
      runtime.addEvent(
        type: 'settings',
        title: 'ACE-Step health check started',
        detail: '$apiEndpoint / $uiEndpoint',
      ),
    );
    final result = await const AceStepHealthService().check(
      apiEndpoint: apiEndpoint,
      uiEndpoint: uiEndpoint,
    );
    if (!mounted) return;
    setState(() {
      _checkingLocal.remove(provider.id);
      _localStatus[provider.id] = result.statusLabel;
    });
    unawaited(
      runtime.addEvent(
        type: 'settings',
        title: result.available ? 'ACE-Step available' : 'ACE-Step unavailable',
        detail: result.statusLabel,
      ),
    );
    _showMessage(
      result.available
          ? result.statusLabel
          : 'ACE-Step не отвечает. Запустите API на 8001 и UI на 3001.',
    );
  }

  Future<void> _openLocalUi(AiProvider provider) async {
    if (provider.id != 'ace-step') return;
    final uiEndpoint =
        _uiEndpointControllers[provider.id]?.text.trim() ??
        'http://localhost:3001';
    final opened = await launchUrl(
      Uri.parse(uiEndpoint),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    _showMessage(
      opened
          ? 'ACE-Step UI открыт во внешнем браузере.'
          : 'Не удалось открыть ACE-Step UI.',
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ExecutionNotice extends StatelessWidget {
  const _ExecutionNotice({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final configured = const ProviderRegistry()
        .getAllProviders()
        .where((provider) => provider.apiKeyRequired)
        .where((provider) => settings.hasProviderApiKey(provider.id))
        .length;

    return OsCard(
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFFC8FFF4)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: const Text(
              'На этом этапе FLUTEN только сохраняет настройки запуска. Реальные API-запросы будут подключены следующим патчем. Не вставляйте ключи в чат: добавляйте их только здесь.',
              style: TextStyle(color: Color(0xFFD9E6F7), height: 1.4),
            ),
          ),
          Chip(label: Text('Ключей добавлено: $configured')),
          const Chip(label: Text('Fallback: copy/open site')),
        ],
      ),
    );
  }
}

class _GeneralSettings extends StatelessWidget {
  const _GeneralSettings({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Общие настройки',
            subtitle:
                'Тема, стартовый экран и предпочтительный режим маршрута.',
          ),
          SwitchListTile(
            value: settings.darkMode,
            onChanged: settings.setDarkMode,
            title: const Text('Тёмная тема'),
            subtitle: const Text('Сохраняется локально на этом устройстве.'),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: settings.compactCards,
            onChanged: settings.setCompactCards,
            title: const Text('Компактные карточки'),
            subtitle: const Text('Более плотные сетки для desktop-экранов.'),
          ),
          const Divider(height: 1),
          _DestinationTile(settings: settings),
          const Divider(height: 1),
          _ModeTile(settings: settings),
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
    return ListTile(
      title: const Text('Стартовый экран'),
      subtitle: const Text('Где FLUTEN откроется в следующий раз.'),
      trailing: SizedBox(
        width: 132,
        child: DropdownButton<AppDestination>(
          value: settings.startupDestination,
          isExpanded: true,
          onChanged: (value) {
            if (value != null) settings.setStartupDestination(value);
          },
          items: [
            for (final destination in AppDestination.values)
              DropdownMenuItem(
                value: destination,
                child: Text(destination.label),
              ),
          ],
        ),
      ),
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
      trailing: SizedBox(
        width: 132,
        child: DropdownButton<OperatorMode>(
          value: settings.operatorMode,
          isExpanded: true,
          onChanged: (value) {
            if (value != null) settings.setOperatorMode(value);
          },
          items: [
            for (final mode in OperatorMode.values)
              DropdownMenuItem(value: mode, child: Text(mode.label)),
          ],
        ),
      ),
    );
  }
}

class _ApiProviderSettings extends StatelessWidget {
  const _ApiProviderSettings({
    required this.providers,
    required this.enabled,
    required this.keyControllers,
    required this.baseUrlControllers,
    required this.modelControllers,
    required this.settings,
    required this.onToggle,
    required this.onSave,
    required this.onClear,
  });

  final List<AiProvider> providers;
  final Map<String, bool> enabled;
  final Map<String, TextEditingController> keyControllers;
  final Map<String, TextEditingController> baseUrlControllers;
  final Map<String, TextEditingController> modelControllers;
  final AppSettings settings;
  final void Function(AiProvider provider, bool value) onToggle;
  final ValueChanged<AiProvider> onSave;
  final ValueChanged<AiProvider> onClear;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'API Providers',
            subtitle:
                'Ключи сохраняются локально. Полные значения после сохранения не показываются.',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final provider in providers)
                    SizedBox(
                      width: wide
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: _ApiProviderCard(
                        provider: provider,
                        enabled: enabled[provider.id] ?? false,
                        keyController: keyControllers[provider.id]!,
                        baseUrlController: baseUrlControllers[provider.id]!,
                        modelController: modelControllers[provider.id]!,
                        settings: settings,
                        onToggle: (value) => onToggle(provider, value),
                        onSave: () => onSave(provider),
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

class _ApiProviderCard extends StatelessWidget {
  const _ApiProviderCard({
    required this.provider,
    required this.enabled,
    required this.keyController,
    required this.baseUrlController,
    required this.modelController,
    required this.settings,
    required this.onToggle,
    required this.onSave,
    required this.onClear,
  });

  final AiProvider provider;
  final bool enabled;
  final TextEditingController keyController;
  final TextEditingController baseUrlController;
  final TextEditingController modelController;
  final AppSettings settings;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasKey = settings.hasProviderApiKey(provider.id);
    final status = hasKey
        ? 'Ключ добавлен'
        : enabled
        ? 'Требуется проверка'
        : 'Не настроено';

    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: enabled,
            onChanged: onToggle,
            title: Text(provider.name),
            subtitle: Text(provider.description),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InfoChip(provider.type.label),
              _InfoChip(status),
              if (hasKey) _InfoChip(settings.maskedProviderApiKey(provider.id)),
            ],
          ),
          if (provider.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              provider.notes,
              style: const TextStyle(color: Color(0xFFFFD29D), height: 1.35),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: keyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'API key',
              hintText: hasKey
                  ? settings.maskedProviderApiKey(provider.id)
                  : '',
              helperText: 'Не печатается в логах и не показывается полностью.',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: baseUrlController,
            decoration: InputDecoration(
              labelText: provider.id == 'omniroute'
                  ? 'Base URL OmniRoute'
                  : 'Base URL optional',
              helperText: provider.id == 'omniroute'
                  ? 'Configurable OpenAI-compatible endpoint; placeholder may be local or remote.'
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: modelController,
            decoration: InputDecoration(
              labelText: provider.id == 'omniroute'
                  ? 'Model / Router profile'
                  : 'Model optional',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Сохранить'),
              ),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Очистить'),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Проверить позже'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocalProviderSettings extends StatelessWidget {
  const _LocalProviderSettings({
    required this.providers,
    required this.enabled,
    required this.endpointControllers,
    required this.uiEndpointControllers,
    required this.modelControllers,
    required this.workflowControllers,
    required this.outputFolderControllers,
    required this.statuses,
    required this.models,
    required this.checking,
    required this.onToggle,
    required this.onSave,
    required this.onCheck,
    required this.onModelSelected,
    required this.onClearWorkflow,
    required this.onOpenUi,
  });

  final List<AiProvider> providers;
  final Map<String, bool> enabled;
  final Map<String, TextEditingController> endpointControllers;
  final Map<String, TextEditingController> uiEndpointControllers;
  final Map<String, TextEditingController> modelControllers;
  final Map<String, TextEditingController> workflowControllers;
  final Map<String, TextEditingController> outputFolderControllers;
  final Map<String, String> statuses;
  final Map<String, List<String>> models;
  final Set<String> checking;
  final void Function(AiProvider provider, bool value) onToggle;
  final ValueChanged<AiProvider> onSave;
  final ValueChanged<AiProvider> onCheck;
  final void Function(AiProvider provider, String model) onModelSelected;
  final ValueChanged<AiProvider> onClearWorkflow;
  final ValueChanged<AiProvider> onOpenUi;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Local Providers',
            subtitle:
                'Endpoint-ы для Ollama, ComfyUI, ACE-Step и будущего локального браузера.',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final provider in providers)
                    SizedBox(
                      width: wide
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: _LocalProviderCard(
                        provider: provider,
                        enabled: enabled[provider.id] ?? false,
                        endpointController: endpointControllers[provider.id]!,
                        uiEndpointController:
                            uiEndpointControllers[provider.id],
                        modelController: modelControllers[provider.id],
                        workflowController: workflowControllers[provider.id],
                        outputFolderController:
                            outputFolderControllers[provider.id],
                        status: statuses[provider.id],
                        models: models[provider.id] ?? const [],
                        checking: checking.contains(provider.id),
                        onToggle: (value) => onToggle(provider, value),
                        onSave: () => onSave(provider),
                        onCheck: () => onCheck(provider),
                        onModelSelected: (model) =>
                            onModelSelected(provider, model),
                        onClearWorkflow: () => onClearWorkflow(provider),
                        onOpenUi: () => onOpenUi(provider),
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

class _LocalProviderCard extends StatelessWidget {
  const _LocalProviderCard({
    required this.provider,
    required this.enabled,
    required this.endpointController,
    required this.uiEndpointController,
    required this.modelController,
    required this.workflowController,
    required this.outputFolderController,
    required this.status,
    required this.models,
    required this.checking,
    required this.onToggle,
    required this.onSave,
    required this.onCheck,
    required this.onModelSelected,
    required this.onClearWorkflow,
    required this.onOpenUi,
  });

  final AiProvider provider;
  final bool enabled;
  final TextEditingController endpointController;
  final TextEditingController? uiEndpointController;
  final TextEditingController? modelController;
  final TextEditingController? workflowController;
  final TextEditingController? outputFolderController;
  final String? status;
  final List<String> models;
  final bool checking;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSave;
  final VoidCallback onCheck;
  final ValueChanged<String> onModelSelected;
  final VoidCallback onClearWorkflow;
  final VoidCallback onOpenUi;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: enabled,
            onChanged: onToggle,
            title: Text(provider.name),
            subtitle: Text(_localStatusFor(provider)),
          ),
          TextField(
            controller: endpointController,
            decoration: const InputDecoration(labelText: 'Endpoint URL'),
          ),
          if (provider.id == 'ace-step') ...[
            const SizedBox(height: 8),
            TextField(
              controller: uiEndpointController,
              decoration: const InputDecoration(
                labelText: 'ACE-Step UI endpoint',
                helperText: 'Обычно http://localhost:3001',
              ),
            ),
            const SizedBox(height: 8),
            _InfoChip(status ?? 'Не проверено'),
          ],
          if (provider.id == 'ollama') ...[
            const SizedBox(height: 8),
            if (models.isEmpty)
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Ollama model',
                  helperText:
                      'Если список моделей недоступен, впишите имя вручную.',
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: models.contains(modelController?.text)
                    ? modelController?.text
                    : null,
                decoration: const InputDecoration(labelText: 'Ollama model'),
                items: [
                  for (final model in models)
                    DropdownMenuItem(value: model, child: Text(model)),
                ],
                onChanged: (value) {
                  if (value != null) onModelSelected(value);
                },
              ),
            const SizedBox(height: 8),
            _InfoChip(status ?? 'Не проверено'),
          ],
          if (provider.id == 'comfyui') ...[
            const SizedBox(height: 8),
            TextField(
              controller: workflowController,
              decoration: const InputDecoration(
                labelText: 'Workflow path optional',
                helperText:
                    'Пока FLUTEN не отправляет workflow в ComfyUI. Поле готовит следующий этап.',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: outputFolderController,
              decoration: const InputDecoration(
                labelText: 'Output folder optional',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _InfoChip(status ?? 'Не проверено'),
                _InfoChip(
                  (workflowController?.text.trim().isEmpty ?? true)
                      ? 'Workflow не выбран'
                      : 'Workflow указан',
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Сохранить'),
              ),
              OutlinedButton.icon(
                onPressed: checking ? null : onCheck,
                icon: const Icon(Icons.cable_rounded),
                label: Text(
                  checking ? 'Проверяем...' : _checkLabelFor(provider),
                ),
              ),
              if (provider.id == 'comfyui')
                OutlinedButton.icon(
                  onPressed: onClearWorkflow,
                  icon: const Icon(Icons.clear_rounded),
                  label: const Text('Очистить workflow'),
                ),
              if (provider.id == 'ace-step')
                OutlinedButton.icon(
                  onPressed: onOpenUi,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Открыть ACE-Step UI'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrowserManualSettings extends StatelessWidget {
  const _BrowserManualSettings();

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Browser / Manual Mode',
            subtitle:
                'Если ключ не добавлен, FLUTEN продолжает работать в ручном режиме: copy/open site.',
          ),
          Text(
            'Провайдеры через сайт остаются рабочим fallback. Кнопки генерации внутри FLUTEN не должны обещать результат, пока API/local runtime не подключены.',
            style: TextStyle(color: Color(0xFFA7B1C1), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SafetySecretsPanel extends StatelessWidget {
  const _SafetySecretsPanel();

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Safety / Secrets',
            subtitle: 'Локальное хранение без публикации ключей.',
          ),
          Text(
            'Ключи хранятся локально на этом устройстве через SharedPreferences, потому что secure storage dependency в проекте пока не подключена. Не публикуйте их в GitHub и не вставляйте в чат. После сохранения показывается только маска вида sk-...abcd.',
            style: TextStyle(color: Color(0xFFD9E6F7), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66070A0F),
        border: Border.all(color: const Color(0x22FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);

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

String _defaultModelFor(AiProvider provider) {
  return switch (provider.id) {
    'openai' || 'chatgpt' => 'gpt-4.1',
    'gemini' => 'gemini-1.5-pro',
    'claude' => 'claude-3.5-sonnet',
    'openrouter' => 'openrouter/auto',
    'omniroute' => 'auto',
    'runway' => 'gen-3',
    'kling' => 'kling-video',
    'stability' => 'stable-image',
    'elevenlabs' => 'voice',
    _ => '',
  };
}

String _defaultEndpointFor(AiProvider provider) {
  return switch (provider.id) {
    'ollama' => 'http://localhost:11434',
    'comfyui' => 'http://127.0.0.1:8188',
    'ace-step' => 'http://localhost:8001',
    'local-browser' => 'http://localhost',
    _ => provider.localEndpoint ?? provider.baseUrl ?? '',
  };
}

String _localStatusFor(AiProvider provider) {
  return switch (provider.id) {
    'ollama' => 'local text/prompt brain',
    'comfyui' => 'image/video pipeline later',
    'ace-step' =>
      'audio/music generation later; UI обычно http://localhost:3001',
    'local-browser' => 'Встроенный браузер пока не подключен',
    _ => provider.notes,
  };
}

String _checkLabelFor(AiProvider provider) {
  return switch (provider.id) {
    'ollama' => 'Проверить Ollama',
    'comfyui' => 'Проверить ComfyUI',
    'ace-step' => 'Проверить ACE-Step',
    _ => 'Проверить',
  };
}
