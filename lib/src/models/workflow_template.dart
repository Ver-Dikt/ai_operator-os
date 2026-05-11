enum WorkflowDifficulty { easy, medium, advanced }

enum CostLevel { free, low, medium, high, mixed }

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
}
