import 'package:flutter/material.dart';

enum BrowserAiCategory { text, research, image, video, universal }

extension BrowserAiCategoryLabel on BrowserAiCategory {
  String get label {
    return switch (this) {
      BrowserAiCategory.text => 'Текст',
      BrowserAiCategory.research => 'Исследование',
      BrowserAiCategory.image => 'Картинки',
      BrowserAiCategory.video => 'Видео',
      BrowserAiCategory.universal => 'Универсальный',
    };
  }

  IconData get icon {
    return switch (this) {
      BrowserAiCategory.text => Icons.chat_bubble_outline_rounded,
      BrowserAiCategory.research => Icons.travel_explore_rounded,
      BrowserAiCategory.image => Icons.image_outlined,
      BrowserAiCategory.video => Icons.movie_creation_outlined,
      BrowserAiCategory.universal => Icons.auto_awesome_rounded,
    };
  }
}

enum BrowserLaunchMode { embeddedDesktop, externalBrowser, clipboardOnly }

extension BrowserLaunchModeLabel on BrowserLaunchMode {
  String get label {
    return switch (this) {
      BrowserLaunchMode.embeddedDesktop => 'Внутри STUDIO',
      BrowserLaunchMode.externalBrowser => 'Внешний браузер',
      BrowserLaunchMode.clipboardOnly => 'Через буфер',
    };
  }
}

enum BrowserToolAccessType { free, freemium, paid, account }

extension BrowserToolAccessTypeLabel on BrowserToolAccessType {
  String get label {
    return switch (this) {
      BrowserToolAccessType.free => 'Бесплатно',
      BrowserToolAccessType.freemium => 'Freemium',
      BrowserToolAccessType.paid => 'Платно',
      BrowserToolAccessType.account => 'Через аккаунт',
    };
  }
}

class BrowserAiTool {
  const BrowserAiTool({
    required this.id,
    required this.name,
    required this.url,
    required this.category,
    required this.accessType,
    required this.launchModes,
    required this.description,
    this.promptRelevant = true,
    this.tags = const [],
    this.workflowHints = const [],
  });

  final String id;
  final String name;
  final String url;
  final BrowserAiCategory category;
  final BrowserToolAccessType accessType;
  final List<BrowserLaunchMode> launchModes;
  final String description;
  final bool promptRelevant;
  final List<String> tags;
  final List<String> workflowHints;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        description.toLowerCase().contains(normalized) ||
        url.toLowerCase().contains(normalized) ||
        tags.any((tag) => tag.toLowerCase().contains(normalized));
  }
}
