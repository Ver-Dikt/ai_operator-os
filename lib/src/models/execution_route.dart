enum ExecutionRouteType { local, api, browserLaunch, manual, hybridFallback }

class ExecutionRoute {
  const ExecutionRoute({
    required this.routeType,
    required this.providerId,
    required this.statusLabel,
    required this.reason,
    required this.workspaceType,
    this.toolId,
  });

  final ExecutionRouteType routeType;
  final String providerId;
  final String statusLabel;
  final String reason;
  final String workspaceType;
  final String? toolId;
}

extension ExecutionRouteTypeLabel on ExecutionRouteType {
  String get label {
    return switch (this) {
      ExecutionRouteType.local => 'Local Runtime',
      ExecutionRouteType.api => 'API Provider',
      ExecutionRouteType.browserLaunch => 'Browser Launch',
      ExecutionRouteType.manual => 'Manual Fallback',
      ExecutionRouteType.hybridFallback => 'Hybrid Fallback',
    };
  }
}
