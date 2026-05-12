enum PromptLanguageMode { ru, en, ruEn }

extension PromptLanguageModeLabel on PromptLanguageMode {
  String get badge {
    return switch (this) {
      PromptLanguageMode.ru => 'RU для понимания',
      PromptLanguageMode.en => 'EN для генерации',
      PromptLanguageMode.ruEn => 'RU/EN',
    };
  }
}

class PromptTemplate {
  const PromptTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.descriptionRu,
    required this.whenToUseRu,
    required this.template,
    required this.ruExplanation,
    required this.languageMode,
    required this.variables,
    required this.recommendedTools,
    required this.style,
    required this.notes,
  });

  final String id;
  final String title;
  final String category;
  final String descriptionRu;
  final String whenToUseRu;
  final String template;
  final String ruExplanation;
  final PromptLanguageMode languageMode;
  final List<String> variables;
  final List<String> recommendedTools;
  final String style;
  final String notes;

  String get copyAllText {
    return [
      'Описание:',
      descriptionRu,
      '',
      'Когда использовать:',
      whenToUseRu,
      '',
      'RU объяснение:',
      ruExplanation,
      '',
      'Рабочий промпт:',
      template,
    ].join('\n');
  }
}
