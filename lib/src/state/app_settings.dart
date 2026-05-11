import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../models/tool_item.dart';

enum AppDestination { dashboard, catalog, favorites, settings }

extension AppDestinationRoute on AppDestination {
  String get routePath {
    return switch (this) {
      AppDestination.dashboard => '/',
      AppDestination.catalog => '/catalog',
      AppDestination.favorites => '/favorites',
      AppDestination.settings => '/settings',
    };
  }

  static AppDestination fromRoute(String? route) {
    return switch (route) {
      '/catalog' => AppDestination.catalog,
      '/favorites' => AppDestination.favorites,
      '/settings' => AppDestination.settings,
      _ => AppDestination.dashboard,
    };
  }
}

class AppSettings extends ChangeNotifier {
  static const _favoritesKey = 'favorite_tool_ids';
  static const _compactKey = 'compact_cards';
  static const _sensitiveKey = 'show_sensitive_tools';
  static const _startupKey = 'startup_destination';
  static const allCategories = 'Все';

  AppSettings({required SharedPreferences preferences})
    : _preferences = preferences {
    _favoriteIds =
        _preferences.getStringList(_favoritesKey)?.toSet() ?? <String>{};
    compactCards = _preferences.getBool(_compactKey) ?? false;
    showSensitiveTools = _preferences.getBool(_sensitiveKey) ?? false;
    final savedDestination = _preferences.getString(_startupKey);
    startupDestination = AppDestination.values.firstWhere(
      (item) => item.name == savedDestination,
      orElse: () => AppDestination.dashboard,
    );
    currentDestination = startupDestination;
  }

  final SharedPreferences _preferences;
  Set<String> _favoriteIds = <String>{};

  String query = '';
  String selectedTag = 'all';
  String selectedCategory = allCategories;
  bool compactCards = false;
  bool showSensitiveTools = false;
  AppDestination startupDestination = AppDestination.dashboard;
  AppDestination currentDestination = AppDestination.dashboard;

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  List<String> get categories => <String>[
    allCategories,
    ...toolsCatalog.map((tool) => tool.category).toSet(),
  ];

  List<ToolItem> get visibleTools {
    return toolsCatalog.where((tool) {
      if (!showSensitiveTools && tool.access == ToolAccess.sensitive) {
        return false;
      }

      final matchesCategory =
          selectedCategory == allCategories ||
          tool.category == selectedCategory;
      final matchesTag =
          selectedTag == 'all' || tool.tags.contains(selectedTag);
      return matchesCategory && matchesTag && tool.matches(query);
    }).toList()..sort((a, b) {
      final access = a.access.sortWeight.compareTo(b.access.sortWeight);
      if (access != 0) {
        return access;
      }
      final signal = b.signal.compareTo(a.signal);
      if (signal != 0) {
        return signal;
      }
      return a.name.compareTo(b.name);
    });
  }

  List<ToolItem> get favoriteTools {
    return toolsCatalog
        .where((tool) => _favoriteIds.contains(tool.id))
        .toList();
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void setDestination(AppDestination value) {
    currentDestination = value;
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    await _preferences.setStringList(
      _favoritesKey,
      _favoriteIds.toList()..sort(),
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

  Future<void> setShowSensitiveTools(bool value) async {
    showSensitiveTools = value;
    await _preferences.setBool(_sensitiveKey, value);
    notifyListeners();
  }

  Future<void> setStartupDestination(AppDestination value) async {
    startupDestination = value;
    await _preferences.setString(_startupKey, value.name);
    notifyListeners();
  }
}
