class RoutingRecommendation {
  const RoutingRecommendation({
    required this.task,
    required this.bestPaidTools,
    required this.bestFreeTools,
    required this.localOptions,
    required this.recommendedWorkflow,
    required this.estimatedCost,
    required this.notes,
  });

  final String task;
  final List<String> bestPaidTools;
  final List<String> bestFreeTools;
  final List<String> localOptions;
  final String recommendedWorkflow;
  final String estimatedCost;
  final List<String> notes;
}
