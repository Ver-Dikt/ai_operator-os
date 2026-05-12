enum ExecutionMode { demo, manual, browserLaunch, api, local }

extension ExecutionModeLabel on ExecutionMode {
  String get label {
    return switch (this) {
      ExecutionMode.demo => 'Demo',
      ExecutionMode.manual => 'Manual',
      ExecutionMode.browserLaunch => 'Browser launch',
      ExecutionMode.api => 'API later',
      ExecutionMode.local => 'Local later',
    };
  }
}
