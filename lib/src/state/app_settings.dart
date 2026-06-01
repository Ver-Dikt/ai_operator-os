import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_tools.dart';
import '../models/ai_tool.dart';

enum OperatorMode { local, cloud, hybrid }

extension OperatorModeLabel on OperatorMode {
  String get label {
    return switch (this) {
      OperatorMode.local => 'Local - локально',
      OperatorMode.cloud => 'Cloud - облачные сервисы',
      OperatorMode.hybrid => 'Hybrid - смешанный режим',
    };
  }
}

enum AppDestination {
  commandCenter,
  textWorkspace,
  images,
  video,
  audio,
  director,
  providers,
  renderHistory,
  socialIntelligence,
  browserHub,
  tools,
  agents,
  workflows,
  contentFactory,
  useCases,
  projects,
  favorites,
  settings,
}

extension AppDestinationRoute on AppDestination {
  String get routePath {
    return switch (this) {
      AppDestination.commandCenter => '/',
      AppDestination.textWorkspace => '/text',
      AppDestination.images => '/images',
      AppDestination.video => '/video',
      AppDestination.audio => '/audio',
      AppDestination.director => '/director',
      AppDestination.providers => '/providers',
      AppDestination.renderHistory => '/history',
      AppDestination.socialIntelligence => '/social',
      AppDestination.browserHub => '/browser',
      AppDestination.tools => '/tools',
      AppDestination.agents => '/agents',
      AppDestination.workflows => '/workflows',
      AppDestination.contentFactory => '/factory',
      AppDestination.useCases => '/use-cases',
      AppDestination.projects => '/projects',
      AppDestination.favorites => '/favorites',
      AppDestination.settings => '/settings',
    };
  }

  static AppDestination fromRoute(String? route) {
    return switch (route) {
      '/text' || '/chat' || '/prompt-builder' => AppDestination.textWorkspace,
      '/images' || '/image' => AppDestination.images,
      '/video' => AppDestination.video,
      '/audio' => AppDestination.audio,
      '/director' || '/cinema' => AppDestination.director,
      '/providers' => AppDestination.providers,
      '/history' || '/renders' => AppDestination.renderHistory,
      '/social' || '/analytics' => AppDestination.socialIntelligence,
      '/browser' || '/ai-browser' || '/hub' => AppDestination.browserHub,
      '/tools' || '/catalog' => AppDestination.tools,
      '/agents' => AppDestination.agents,
      '/workflows' => AppDestination.workflows,
      '/factory' => AppDestination.contentFactory,
      '/prompts' ||
      '/router' ||
      '/free' ||
      '/use-cases' => AppDestination.useCases,
      '/projects' => AppDestination.projects,
      '/favorites' => AppDestination.favorites,
      '/settings' => AppDestination.settings,
      _ => AppDestination.commandCenter,
    };
  }

  String get label {
    return switch (this) {
      AppDestination.commandCenter => 'Пульт',
      AppDestination.textWorkspace => 'AI Чат',
      AppDestination.images => 'Изображения',
      AppDestination.video => 'Видео',
      AppDestination.audio => 'Audio',
      AppDestination.director => 'Режиссёр',
      AppDestination.providers => 'Провайдеры',
      AppDestination.renderHistory => 'История',
      AppDestination.socialIntelligence => 'Соцаналитика',
      AppDestination.browserHub => 'Браузер нейронок',
      AppDestination.tools => 'Инструменты',
      AppDestination.agents => 'AI-помощники',
      AppDestination.workflows => 'Планы работы',
      AppDestination.contentFactory => 'Фабрики',
      AppDestination.useCases => 'Кейсы',
      AppDestination.projects => 'Проекты',
      AppDestination.favorites => 'Избранное',
      AppDestination.settings => 'Настройки',
    };
  }
}

class AppSettings extends ChangeNotifier {
  AppSettings({required SharedPreferences preferences})
    : _preferences = preferences {
    _favoriteIds =
        _preferences.getStringList(_favoritesKey)?.toSet() ?? <String>{};
    _favoriteAgentIds =
        _preferences.getStringList(_favoriteAgentsKey)?.toSet() ??
        <String>{'director-agent', 'tool-router-agent'};
    _favoriteWorkflowIds =
        _preferences.getStringList(_favoriteWorkflowsKey)?.toSet() ??
        <String>{};
    _favoritePromptIds =
        _preferences.getStringList(_favoritePromptsKey)?.toSet() ??
        <String>{'cinematic-video-scene'};
    compactCards = _preferences.getBool(_compactKey) ?? false;
    operatorMode = OperatorMode.values.firstWhere(
      (item) => item.name == _preferences.getString(_operatorModeKey),
      orElse: () => OperatorMode.hybrid,
    );
    ollamaBaseUrl =
        _preferences.getString(_ollamaBaseUrlKey) ?? 'http://localhost:11434';
    ollamaModel = _preferences.getString(_ollamaModelKey) ?? defaultOllamaModel;
    themeAccent = _preferences.getString(_accentKey) ?? 'cyan';
    darkMode = _preferences.getBool(_darkModeKey) ?? true;

    final savedDestination = _preferences.getString(_startupKey);
    startupDestination = AppDestination.values.firstWhere(
      (item) => item.name == savedDestination,
      orElse: () => AppDestination.commandCenter,
    );
    currentDestination = startupDestination;
  }

  static const _favoritesKey = 'favorite_tool_ids';
  static const _favoriteAgentsKey = 'favorite_agent_ids';
  static const _favoriteWorkflowsKey = 'favorite_workflow_ids';
  static const _favoritePromptsKey = 'favorite_prompt_ids';
  static const _compactKey = 'compact_cards';
  static const _startupKey = 'startup_destination';
  static const _operatorModeKey = 'operator_mode';
  static const _ollamaBaseUrlKey = 'ollama_base_url';
  static const _ollamaModelKey = 'ollama_model';
  static const _accentKey = 'theme_accent';
  static const _darkModeKey = 'dark_mode';
  static const _providerEnabledPrefix = 'execution_provider_enabled_';
  static const _providerApiKeyPrefix = 'execution_provider_api_key_';
  static const _providerBaseUrlPrefix = 'execution_provider_base_url_';
  static const _providerModelPrefix = 'execution_provider_model_';
  static const _localEnabledPrefix = 'execution_local_enabled_';
  static const _localEndpointPrefix = 'execution_local_endpoint_';
  static const _localUiEndpointPrefix = 'execution_local_ui_endpoint_';
  static const _localWorkflowPathPrefix = 'execution_local_workflow_path_';
  static const _localOutputFolderPrefix = 'execution_local_output_folder_';
  static const defaultOllamaModel = 'qwen2.5-coder:7b';
  static const ollamaModels = <String>[
    'qwen2.5-coder:7b',
    'llama3.1:8b',
    'qwen3.5:9b',
    'gemma4:latest',
  ];
  static const allCategories = 'Все';

  final SharedPreferences _preferences;
  Set<String> _favoriteIds = <String>{};
  Set<String> _favoriteAgentIds = <String>{};
  Set<String> _favoriteWorkflowIds = <String>{};
  Set<String> _favoritePromptIds = <String>{};

  String query = '';
  String selectedTag = 'all';
  String selectedCategory = allCategories;
  bool compactCards = false;
  OperatorMode operatorMode = OperatorMode.hybrid;
  String ollamaBaseUrl = 'http://localhost:11434';
  String ollamaModel = defaultOllamaModel;
  String themeAccent = 'cyan';
  bool darkMode = true;
  AppDestination startupDestination = AppDestination.commandCenter;
  AppDestination currentDestination = AppDestination.commandCenter;
  String? pendingBrowserPrompt;
  String? pendingBrowserToolId;
  String? pendingImagePromptDraft;
  String? pendingVideoPromptDraft;

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  Set<String> get favoriteAgentIds => Set.unmodifiable(_favoriteAgentIds);
  Set<String> get favoriteWorkflowIds => Set.unmodifiable(_favoriteWorkflowIds);
  Set<String> get favoritePromptIds => Set.unmodifiable(_favoritePromptIds);

  List<String> get categories => <String>[
    allCategories,
    ...seedTools.map((tool) => tool.category.label).toSet(),
  ];

  List<AiTool> get visibleTools {
    return seedTools.where((tool) {
      final matchesCategory =
          selectedCategory == allCategories ||
          tool.category.label == selectedCategory;
      final matchesTag =
          selectedTag == 'all' || tool.tags.contains(selectedTag);
      return matchesCategory && matchesTag && tool.matches(query);
    }).toList()..sort((a, b) {
      final rating = b.rating.compareTo(a.rating);
      if (rating != 0) return rating;
      return a.name.compareTo(b.name);
    });
  }

  List<AiTool> get favoriteTools {
    return seedTools.where((tool) => _favoriteIds.contains(tool.id)).toList();
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);
  bool isFavoriteAgent(String id) => _favoriteAgentIds.contains(id);
  bool isFavoriteWorkflow(String id) => _favoriteWorkflowIds.contains(id);
  bool isFavoritePrompt(String id) => _favoritePromptIds.contains(id);

  void setDestination(AppDestination value) {
    currentDestination = value;
    notifyListeners();
  }

  void setBrowserHandoff({required String prompt, String? toolId}) {
    pendingBrowserPrompt = prompt;
    pendingBrowserToolId = toolId;
    notifyListeners();
  }

  void clearBrowserHandoff() {
    pendingBrowserPrompt = null;
    pendingBrowserToolId = null;
    notifyListeners();
  }

  void setImagePromptDraft(String prompt) {
    pendingImagePromptDraft = prompt;
    notifyListeners();
  }

  void setVideoPromptDraft(String prompt) {
    pendingVideoPromptDraft = prompt;
    notifyListeners();
  }

  void clearImagePromptDraft() {
    pendingImagePromptDraft = null;
    notifyListeners();
  }

  void clearVideoPromptDraft() {
    pendingVideoPromptDraft = null;
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    if (!_favoriteIds.remove(id)) {
      _favoriteIds.add(id);
    }
    await _preferences.setStringList(
      _favoritesKey,
      _favoriteIds.toList()..sort(),
    );
    notifyListeners();
  }

  Future<void> toggleFavoriteAgent(String id) async {
    if (!_favoriteAgentIds.remove(id)) {
      _favoriteAgentIds.add(id);
    }
    await _preferences.setStringList(
      _favoriteAgentsKey,
      _favoriteAgentIds.toList()..sort(),
    );
    notifyListeners();
  }

  Future<void> toggleFavoriteWorkflow(String id) async {
    if (!_favoriteWorkflowIds.remove(id)) {
      _favoriteWorkflowIds.add(id);
    }
    await _preferences.setStringList(
      _favoriteWorkflowsKey,
      _favoriteWorkflowIds.toList()..sort(),
    );
    notifyListeners();
  }

  Future<void> toggleFavoritePrompt(String id) async {
    if (!_favoritePromptIds.remove(id)) {
      _favoritePromptIds.add(id);
    }
    await _preferences.setStringList(
      _favoritePromptsKey,
      _favoritePromptIds.toList()..sort(),
    );
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setTag(String value) {
    selectedTag = value;
    notifyListeners();
  }

  void setCategory(String value) {
    selectedCategory = value;
    notifyListeners();
  }

  void resetCatalogFilters() {
    query = '';
    selectedTag = 'all';
    selectedCategory = allCategories;
    notifyListeners();
  }

  Future<void> setCompactCards(bool value) async {
    compactCards = value;
    await _preferences.setBool(_compactKey, value);
    notifyListeners();
  }

  Future<void> setStartupDestination(AppDestination value) async {
    startupDestination = value;
    await _preferences.setString(_startupKey, value.name);
    notifyListeners();
  }

  Future<void> setOperatorMode(OperatorMode value) async {
    operatorMode = value;
    await _preferences.setString(_operatorModeKey, value.name);
    notifyListeners();
  }

  Future<void> setOllamaBaseUrl(String value) async {
    ollamaBaseUrl = value;
    await _preferences.setString(_ollamaBaseUrlKey, value);
    notifyListeners();
  }

  bool isProviderEnabled(String providerId) {
    return _preferences.getBool('$_providerEnabledPrefix$providerId') ?? false;
  }

  bool hasProviderApiKey(String providerId) {
    return providerApiKey(providerId).trim().isNotEmpty;
  }

  String providerApiKey(String providerId) {
    return _preferences.getString('$_providerApiKeyPrefix$providerId') ?? '';
  }

  String providerBaseUrl(String providerId, {String fallback = ''}) {
    return _preferences.getString('$_providerBaseUrlPrefix$providerId') ??
        fallback;
  }

  String providerModel(String providerId, {String fallback = ''}) {
    return _preferences.getString('$_providerModelPrefix$providerId') ??
        fallback;
  }

  String maskedProviderApiKey(String providerId) {
    return maskSecret(providerApiKey(providerId));
  }

  Future<void> saveProviderApiSettings({
    required String providerId,
    required bool enabled,
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {
    await _preferences.setBool('$_providerEnabledPrefix$providerId', enabled);
    if (apiKey.trim().isNotEmpty) {
      await _preferences.setString(
        '$_providerApiKeyPrefix$providerId',
        apiKey.trim(),
      );
    }
    await _preferences.setString(
      '$_providerBaseUrlPrefix$providerId',
      baseUrl.trim(),
    );
    await _preferences.setString(
      '$_providerModelPrefix$providerId',
      model.trim(),
    );
    notifyListeners();
  }

  Future<void> clearProviderApiKey(String providerId) async {
    await _preferences.remove('$_providerApiKeyPrefix$providerId');
    await _preferences.setBool('$_providerEnabledPrefix$providerId', false);
    notifyListeners();
  }

  bool isLocalProviderEnabled(String providerId) {
    return _preferences.getBool('$_localEnabledPrefix$providerId') ?? false;
  }

  String localEndpoint(String providerId, {required String fallback}) {
    return _preferences.getString('$_localEndpointPrefix$providerId') ??
        fallback;
  }

  String localUiEndpoint(String providerId, {required String fallback}) {
    return _preferences.getString('$_localUiEndpointPrefix$providerId') ??
        fallback;
  }

  String localWorkflowPath(String providerId) {
    return _preferences.getString('$_localWorkflowPathPrefix$providerId') ?? '';
  }

  String localOutputFolder(String providerId) {
    return _preferences.getString('$_localOutputFolderPrefix$providerId') ?? '';
  }

  Future<void> saveLocalProviderSettings({
    required String providerId,
    required bool enabled,
    required String endpoint,
  }) async {
    final normalized = endpoint.trim();
    await _preferences.setBool('$_localEnabledPrefix$providerId', enabled);
    await _preferences.setString('$_localEndpointPrefix$providerId', normalized);
    if (providerId == 'ollama') {
      ollamaBaseUrl = normalized;
      await _preferences.setString(_ollamaBaseUrlKey, normalized);
    }
    notifyListeners();
  }

  Future<void> saveLocalWorkflowSettings({
    required String providerId,
    required String workflowPath,
    required String outputFolder,
  }) async {
    await _preferences.setString(
      '$_localWorkflowPathPrefix$providerId',
      workflowPath.trim(),
    );
    await _preferences.setString(
      '$_localOutputFolderPrefix$providerId',
      outputFolder.trim(),
    );
    notifyListeners();
  }

  Future<void> saveLocalUiEndpoint({
    required String providerId,
    required String uiEndpoint,
  }) async {
    await _preferences.setString(
      '$_localUiEndpointPrefix$providerId',
      uiEndpoint.trim(),
    );
    notifyListeners();
  }

  Future<void> clearLocalWorkflow(String providerId) async {
    await _preferences.remove('$_localWorkflowPathPrefix$providerId');
    notifyListeners();
  }

  Future<void> setOllamaModel(String value) async {
    ollamaModel = value;
    await _preferences.setString(_ollamaModelKey, value);
    notifyListeners();
  }

  Future<void> setThemeAccent(String value) async {
    themeAccent = value;
    await _preferences.setString(_accentKey, value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _preferences.setBool(_darkModeKey, value);
    notifyListeners();
  }
}

String maskSecret(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Не настроено';
  if (trimmed.length <= 8) {
    return '••••${trimmed.substring(trimmed.length - 2)}';
  }
  return '${trimmed.substring(0, 3)}...${trimmed.substring(trimmed.length - 4)}';
}
