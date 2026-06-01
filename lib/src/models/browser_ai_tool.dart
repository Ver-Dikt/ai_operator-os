import 'package:flutter/material.dart';

enum BrowserAiCategory { text, image, video, audio, utility }

extension BrowserAiCategoryLabel on BrowserAiCategory {
  String get label {
    return switch (this) {
      BrowserAiCategory.text => 'Text',
      BrowserAiCategory.image => 'Image',
      BrowserAiCategory.video => 'Video',
      BrowserAiCategory.audio => 'Audio',
      BrowserAiCategory.utility => 'Utility',
    };
  }

  IconData get icon {
    return switch (this) {
      BrowserAiCategory.text => Icons.chat_bubble_outline_rounded,
      BrowserAiCategory.image => Icons.image_outlined,
      BrowserAiCategory.video => Icons.movie_creation_outlined,
      BrowserAiCategory.audio => Icons.graphic_eq_rounded,
      BrowserAiCategory.utility => Icons.travel_explore_rounded,
    };
  }
}

enum BrowserExecutionMode { api, browser, local, manual, unavailable }

extension BrowserExecutionModeLabel on BrowserExecutionMode {
  String get label {
    return switch (this) {
      BrowserExecutionMode.api => 'Через API',
      BrowserExecutionMode.browser => 'Через сайт',
      BrowserExecutionMode.local => 'Локально',
      BrowserExecutionMode.manual => 'Вручную',
      BrowserExecutionMode.unavailable => 'Недоступно',
    };
  }
}

enum BrowserProviderStatus {
  readyBrowser,
  apiKeyRequired,
  localNotConnected,
  comingSoon,
  manualOnly,
}

extension BrowserProviderStatusLabel on BrowserProviderStatus {
  String get label {
    return switch (this) {
      BrowserProviderStatus.readyBrowser => 'Готово: можно открыть сайт',
      BrowserProviderStatus.apiKeyRequired => 'Нужен API-ключ',
      BrowserProviderStatus.localNotConnected =>
        'Локальная модель не подключена',
      BrowserProviderStatus.comingSoon => 'Скоро',
      BrowserProviderStatus.manualOnly =>
        'Скопируйте prompt и вставьте вручную',
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
    this.executionMode = BrowserExecutionMode.browser,
    this.status = BrowserProviderStatus.readyBrowser,
    this.recommendedUseCase,
    this.supportedWorkflows = const ['browserHandoff'],
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
  final BrowserExecutionMode executionMode;
  final BrowserProviderStatus status;
  final String? recommendedUseCase;
  final List<String> supportedWorkflows;
  final bool promptRelevant;
  final List<String> tags;
  final List<String> workflowHints;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        description.toLowerCase().contains(normalized) ||
        url.toLowerCase().contains(normalized) ||
        (recommendedUseCase?.toLowerCase().contains(normalized) ?? false) ||
        supportedWorkflows.any(
          (workflow) => workflow.toLowerCase().contains(normalized),
        ) ||
        tags.any((tag) => tag.toLowerCase().contains(normalized));
  }
}
