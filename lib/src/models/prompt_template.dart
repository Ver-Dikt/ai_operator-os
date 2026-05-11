class PromptTemplate {
  const PromptTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.template,
    required this.variables,
    required this.recommendedTools,
    required this.style,
    required this.notes,
  });

  final String id;
  final String title;
  final String category;
  final String template;
  final List<String> variables;
  final List<String> recommendedTools;
  final String style;
  final String notes;
}
