import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_tools.dart';
import '../models/ai_tool.dart';

enum OperatorMode { local, cloud, hybrid }

enum AppDestination {
  commandCenter,
  tools,
  agents,
  workflows,
  contentFactory,
  promptStudio,
  modelRouter,
  freeCredits,
  favorites,
  settings,
}

extension AppDestinationRoute on AppDestination {
  String get routePath {
    return switch (this) {
      AppDestination.commandCenter => '/',
      AppDestination.tools => '/tools',
      AppDestination.agents => '/agents',
      AppDestination.workflows => '/workflows',
      AppDestination.contentFactory => '/factory',
      AppDestination.promptStudio => '/prompts',
      AppDestination.modelRouter => '/router',
      AppDestination.freeCredits => '/free',
      AppDestination.favorites => '/favorites',
      AppDestination.settings => '/settings',
    };
  }

  static AppDestination fromRoute(String? route) {
    return switch (route) {
      '/tools' || '/catalog' => AppDestination.tools,
      '/agents' => AppDestination.agents,
      '/workflows' => AppDestination.workflows,
      '/factory' => AppDestination.contentFactory,
      '/prompts' => AppDestination.promptStudio,
      '/router' => AppDestination.modelRouter,
      '/free' => AppDestination.freeCredits,
      '/favorites' => AppDestination.favorites,
      '/settings' => AppDestination.settings,
      _ => AppDestination.commandCenter,
    };
  }

  String get label {
    return switch (this) {
      AppDestination.commandCenter => 'Home',
      AppDestination.tools => 'AI Tools',
      AppDestination.agents => 'Agents',
      AppDestination.workflows => 'Workflows',
      AppDestination.contentFactory => 'Factory',
      AppDestination.promptStudio => 'Prompts',
      AppDestination.modelRouter => 'Router',
      AppDestination.freeCredits => 'Free',
      AppDestination.favorites => 'Favorites',
      AppDestination.settings => 'Settings',
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
        <String>{'ai-short-video-factory'};
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
    themeAccent = _preferences.getString(_accentKey) ?? 'cyan';

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
  static const _accentKey = 'theme_accent';
  static const allCategories = 'All';

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
  String themeAccent = 'cyan';
  AppDestination startupDestination = AppDestination.commandCenter;
  AppDestination currentDestination = AppDestination.commandCenter;

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

  Future<void> setThemeAccent(String value) async {
    themeAccent = value;
    await _preferences.setString(_accentKey, value);
    notifyListeners();
  }
}
