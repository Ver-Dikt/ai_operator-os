enum ExecutionMode { demo, manual, browserLaunch, api, local }

extension ExecutionModeLabel on ExecutionMode {
  String get label {
    return switch (this) {
      ExecutionMode.demo => 'Демо',
      ExecutionMode.manual => 'Вручную',
      ExecutionMode.browserLaunch => 'Через сайт',
      ExecutionMode.api => 'Через API',
      ExecutionMode.local => 'Локально',
    };
  }
}
