class RoutingRecommendation {
  const RoutingRecommendation({
    required this.task,
    required this.bestPaidTools,
    required this.bestFreeTools,
    required this.localOptions,
    required this.recommendedWorkflow,
    required this.estimatedCost,
    required this.notes,
    this.workflowId,
    this.agentIds = const [],
    this.toolIds = const [],
    this.useCaseIds = const [],
    this.freePath = const [],
    this.proPath = const [],
    this.manualSteps = const [],
    this.automationPotential = 'Assisted',
    this.monetizationIdea =
        'Potential opportunity only. Validate demand before selling.',
  });

  final String task;
  final List<String> bestPaidTools;
  final List<String> bestFreeTools;
  final List<String> localOptions;
  final String recommendedWorkflow;
  final String estimatedCost;
  final List<String> notes;
  final String? workflowId;
  final List<String> agentIds;
  final List<String> toolIds;
  final List<String> useCaseIds;
  final List<String> freePath;
  final List<String> proPath;
  final List<String> manualSteps;
  final String automationPotential;
  final String monetizationIdea;
}
