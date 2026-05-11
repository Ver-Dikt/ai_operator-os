enum PricingType { free, freemium, paid, credits, local }

enum ToolPlatform { web, desktop, mobile, api, local }

enum ToolCategory {
  text,
  image,
  video,
  music,
  voice,
  coding,
  agents,
  automation,
  search,
  research,
  design,
  socialMedia,
  localModels,
  developerTools,
}

extension PricingTypeLabel on PricingType {
  String get label {
    return switch (this) {
      PricingType.free => 'Бесплатно',
      PricingType.freemium => 'Freemium',
      PricingType.paid => 'Платно',
      PricingType.credits => 'Кредиты',
      PricingType.local => 'Локально',
    };
  }
}

extension ToolCategoryLabel on ToolCategory {
  String get label {
    return switch (this) {
      ToolCategory.text => 'Текст',
      ToolCategory.image => 'Изображения',
      ToolCategory.video => 'Видео',
      ToolCategory.music => 'Музыка',
      ToolCategory.voice => 'Голос',
      ToolCategory.coding => 'Кодинг',
      ToolCategory.agents => 'Агенты',
      ToolCategory.automation => 'Автоматизация',
      ToolCategory.search => 'Поиск',
      ToolCategory.research => 'Исследования',
      ToolCategory.design => 'Дизайн',
      ToolCategory.socialMedia => 'Соцсети',
      ToolCategory.localModels => 'Локальные модели',
      ToolCategory.developerTools => 'Инструменты разработчика',
    };
  }
}

class AiTool {
  const AiTool({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.url,
    required this.pricingType,
    required this.hasApi,
    required this.apiUrl,
    required this.freeCreditsInfo,
    required this.bestFor,
    required this.limitations,
    required this.tags,
    required this.rating,
    required this.platforms,
    required this.recommendedUseCases,
    required this.workflowExamples,
    this.categoryIds = const [],
    this.useCaseIds = const [],
    this.agentIds = const [],
    this.workflowIds = const [],
    this.alternativeToolIds = const [],
  });

  final String id;
  final String name;
  final ToolCategory category;
  final String description;
  final String url;
  final PricingType pricingType;
  final bool hasApi;
  final String? apiUrl;
  final String freeCreditsInfo;
  final String bestFor;
  final String limitations;
  final List<String> tags;
  final double rating;
  final List<ToolPlatform> platforms;
  final List<String> recommendedUseCases;
  final List<String> workflowExamples;
  final List<String> categoryIds;
  final List<String> useCaseIds;
  final List<String> agentIds;
  final List<String> workflowIds;
  final List<String> alternativeToolIds;

  bool get isFreePath =>
      pricingType == PricingType.free ||
      pricingType == PricingType.freemium ||
      pricingType == PricingType.local;

  bool get isLocal => platforms.contains(ToolPlatform.local);

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return [
      name,
      category.label,
      description,
      bestFor,
      limitations,
      freeCreditsInfo,
      ...tags,
      ...recommendedUseCases,
      ...workflowExamples,
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}
