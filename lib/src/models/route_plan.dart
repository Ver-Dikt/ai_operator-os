enum RouteExecutionState {
  ready,
  manualStep,
  requiresApi,
  localAvailable,
  comingLater,
}

extension RouteExecutionStateLabel on RouteExecutionState {
  String get label {
    return switch (this) {
      RouteExecutionState.ready => 'Ready',
      RouteExecutionState.manualStep => 'Manual step',
      RouteExecutionState.requiresApi => 'Requires API',
      RouteExecutionState.localAvailable => 'Local available',
      RouteExecutionState.comingLater => 'Coming later',
    };
  }
}

class RouteStep {
  const RouteStep({
    required this.title,
    required this.explanation,
    required this.badges,
    required this.state,
    required this.iconKey,
  });

  final String title;
  final String explanation;
  final List<String> badges;
  final RouteExecutionState state;
  final String iconKey;
}

class RouteExecutionOption {
  const RouteExecutionOption({
    required this.title,
    required this.description,
    required this.badges,
    required this.items,
  });

  final String title;
  final String description;
  final List<String> badges;
  final List<String> items;
}

class RoutePlan {
  const RoutePlan({
    required this.title,
    required this.detectedGoal,
    required this.recommendedMode,
    required this.routeType,
    required this.steps,
    required this.workflows,
    required this.workflowIds,
    required this.tools,
    required this.toolIds,
    required this.agents,
    required this.agentIds,
    required this.promptSuggestions,
    required this.executionOptions,
    required this.estimatedComplexity,
    required this.estimatedCost,
    required this.localPossible,
    required this.freePossible,
  });

  final String title;
  final String detectedGoal;
  final String recommendedMode;
  final String routeType;
  final List<RouteStep> steps;
  final List<String> workflows;
  final List<String> workflowIds;
  final List<String> tools;
  final List<String> toolIds;
  final List<String> agents;
  final List<String> agentIds;
  final List<String> promptSuggestions;
  final List<RouteExecutionOption> executionOptions;
  final String estimatedComplexity;
  final String estimatedCost;
  final bool localPossible;
  final bool freePossible;
}
