import 'monetization.dart';

class UseCase {
  const UseCase({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.recommendedAgentIds,
    required this.recommendedToolIds,
    required this.recommendedWorkflowIds,
    required this.promptTemplateIds,
    required this.monetizationType,
    required this.monetizationPotential,
    required this.requiresHumanReview,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> recommendedAgentIds;
  final List<String> recommendedToolIds;
  final List<String> recommendedWorkflowIds;
  final List<String> promptTemplateIds;
  final RevenueModel monetizationType;
  final MonetizationPotential monetizationPotential;
  final bool requiresHumanReview;
}
