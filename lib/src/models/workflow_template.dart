import 'monetization.dart';

enum WorkflowDifficulty { easy, medium, advanced }

enum CostLevel { free, low, medium, high, mixed }

enum AutomationLevel { manual, assisted, semiAutomated, automated }

class WorkflowStep {
  const WorkflowStep({
    required this.id,
    required this.title,
    required this.instruction,
    required this.agentId,
    required this.toolIds,
    required this.promptTemplate,
    required this.expectedOutput,
    required this.isManual,
    required this.isAutomatable,
  });

  final String id;
  final String title;
  final String instruction;
  final String? agentId;
  final List<String> toolIds;
  final String promptTemplate;
  final String expectedOutput;
  final bool isManual;
  final bool isAutomatable;
}

class WorkflowTemplate {
  const WorkflowTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedTime,
    required this.costLevel,
    required this.steps,
    required this.requiredTools,
    required this.optionalTools,
    required this.outputExamples,
    this.agentIds = const [],
    this.toolIds = const [],
    this.promptTemplateIds = const [],
    this.useCaseIds = const [],
    this.outputs = const [],
    this.monetizationPotential = MonetizationPotential.low,
    this.revenueModel = RevenueModel.freelance,
    this.requiresHumanReview = true,
    this.automationLevel = AutomationLevel.assisted,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final WorkflowDifficulty difficulty;
  final String estimatedTime;
  final CostLevel costLevel;
  final List<WorkflowStep> steps;
  final List<String> requiredTools;
  final List<String> optionalTools;
  final List<String> outputExamples;
  final List<String> agentIds;
  final List<String> toolIds;
  final List<String> promptTemplateIds;
  final List<String> useCaseIds;
  final List<String> outputs;
  final MonetizationPotential monetizationPotential;
  final RevenueModel revenueModel;
  final bool requiresHumanReview;
  final AutomationLevel automationLevel;
}
