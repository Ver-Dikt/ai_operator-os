import 'package:flutter/material.dart';

enum BrowserAiCategory {
  text,
  image,
  video,
  audio,
  social,
  agent,
  workflow,
  editor,
  router,
  localModel,
  code,
  utility,
  research,
}

extension BrowserAiCategoryLabel on BrowserAiCategory {
  String get label {
    return switch (this) {
      BrowserAiCategory.text => 'Text',
      BrowserAiCategory.image => 'Image',
      BrowserAiCategory.video => 'Video',
      BrowserAiCategory.audio => 'Audio',
      BrowserAiCategory.social => 'Social',
      BrowserAiCategory.agent => 'Agents',
      BrowserAiCategory.workflow => 'Workflow',
      BrowserAiCategory.editor => 'Editors',
      BrowserAiCategory.router => 'Router',
      BrowserAiCategory.localModel => 'Local/Self-host',
      BrowserAiCategory.code => 'Code',
      BrowserAiCategory.utility => 'Utility',
      BrowserAiCategory.research => 'Research',
    };
  }

  IconData get icon {
    return switch (this) {
      BrowserAiCategory.text => Icons.chat_bubble_outline_rounded,
      BrowserAiCategory.image => Icons.image_outlined,
      BrowserAiCategory.video => Icons.movie_creation_outlined,
      BrowserAiCategory.audio => Icons.graphic_eq_rounded,
      BrowserAiCategory.social => Icons.campaign_outlined,
      BrowserAiCategory.agent => Icons.smart_toy_outlined,
      BrowserAiCategory.workflow => Icons.account_tree_outlined,
      BrowserAiCategory.editor => Icons.video_settings_outlined,
      BrowserAiCategory.router => Icons.hub_outlined,
      BrowserAiCategory.localModel => Icons.dns_outlined,
      BrowserAiCategory.code => Icons.code_rounded,
      BrowserAiCategory.utility => Icons.travel_explore_rounded,
      BrowserAiCategory.research => Icons.manage_search_rounded,
    };
  }
}

enum BrowserIntegrationMode {
  apiCandidate,
  browserManual,
  localSelfHostCandidate,
  mcpCandidate,
  researchOnly,
  experimental,
  unsafeUnverified,
}

extension BrowserIntegrationModeLabel on BrowserIntegrationMode {
  String get label {
    return switch (this) {
      BrowserIntegrationMode.apiCandidate =>
        'API-\u043a\u0430\u043d\u0434\u0438\u0434\u0430\u0442',
      BrowserIntegrationMode.browserManual =>
        '\u0427\u0435\u0440\u0435\u0437 \u0441\u0430\u0439\u0442 / \u0432\u0440\u0443\u0447\u043d\u0443\u044e',
      BrowserIntegrationMode.localSelfHostCandidate =>
        '\u041b\u043e\u043a\u0430\u043b\u044c\u043d\u044b\u0439/self-host \u043a\u0430\u043d\u0434\u0438\u0434\u0430\u0442',
      BrowserIntegrationMode.mcpCandidate =>
        'MCP-\u043a\u0430\u043d\u0434\u0438\u0434\u0430\u0442',
      BrowserIntegrationMode.researchOnly =>
        '\u0422\u043e\u043b\u044c\u043a\u043e \u0430\u043d\u0430\u043b\u0438\u0437',
      BrowserIntegrationMode.experimental =>
        '\u042d\u043a\u0441\u043f\u0435\u0440\u0438\u043c\u0435\u043d\u0442\u0430\u043b\u044c\u043d\u043e',
      BrowserIntegrationMode.unsafeUnverified =>
        '\u041d\u0435 \u043f\u0440\u043e\u0432\u0435\u0440\u0435\u043d\u043e / \u043e\u0441\u0442\u043e\u0440\u043e\u0436\u043d\u043e',
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
  researchNeeded,
  comingSoon,
  experimental,
  unsafeUnverified,
  manualOnly,
}

extension BrowserProviderStatusLabel on BrowserProviderStatus {
  String get label {
    return switch (this) {
      BrowserProviderStatus.readyBrowser => 'Готово: можно открыть сайт',
      BrowserProviderStatus.apiKeyRequired => 'Нужен API-ключ',
      BrowserProviderStatus.localNotConnected =>
        'Локальная модель не подключена',
      BrowserProviderStatus.researchNeeded => 'Требуется анализ',
      BrowserProviderStatus.comingSoon => 'Скоро',
      BrowserProviderStatus.experimental => 'Эксперимент',
      BrowserProviderStatus.unsafeUnverified => 'Не проверено',
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
    this.categories,
    this.integrationModes = const [BrowserIntegrationMode.browserManual],
    this.executionMode = BrowserExecutionMode.browser,
    this.status = BrowserProviderStatus.readyBrowser,
    this.githubUrl,
    this.docsUrl,
    this.recommendedUseCase,
    this.freeTierNotes,
    this.apiNotes,
    this.localInstallNotes,
    this.riskNotes,
    this.recommendedPhase,
    this.supportedWorkflows = const ['browserHandoff'],
    this.promptRelevant = true,
    this.tags = const [],
    this.workflowHints = const [],
  });

  final String id;
  final String name;
  final String url;
  final BrowserAiCategory category;
  final List<BrowserAiCategory>? categories;
  final List<BrowserIntegrationMode> integrationModes;
  final BrowserToolAccessType accessType;
  final List<BrowserLaunchMode> launchModes;
  final String description;
  final BrowserExecutionMode executionMode;
  final BrowserProviderStatus status;
  final String? githubUrl;
  final String? docsUrl;
  final String? recommendedUseCase;
  final String? freeTierNotes;
  final String? apiNotes;
  final String? localInstallNotes;
  final String? riskNotes;
  final String? recommendedPhase;
  final List<String> supportedWorkflows;
  final bool promptRelevant;
  final List<String> tags;
  final List<String> workflowHints;

  List<BrowserAiCategory> get effectiveCategories => categories ?? [category];

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        description.toLowerCase().contains(normalized) ||
        url.toLowerCase().contains(normalized) ||
        (githubUrl?.toLowerCase().contains(normalized) ?? false) ||
        (docsUrl?.toLowerCase().contains(normalized) ?? false) ||
        (recommendedUseCase?.toLowerCase().contains(normalized) ?? false) ||
        (freeTierNotes?.toLowerCase().contains(normalized) ?? false) ||
        (apiNotes?.toLowerCase().contains(normalized) ?? false) ||
        (localInstallNotes?.toLowerCase().contains(normalized) ?? false) ||
        (riskNotes?.toLowerCase().contains(normalized) ?? false) ||
        (recommendedPhase?.toLowerCase().contains(normalized) ?? false) ||
        supportedWorkflows.any(
          (workflow) => workflow.toLowerCase().contains(normalized),
        ) ||
        tags.any((tag) => tag.toLowerCase().contains(normalized));
  }
}
