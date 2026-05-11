abstract class ToolAdapter {
  const ToolAdapter(this.toolId);

  final String toolId;
  String get mode;
  bool get isReady;
}

class ManualToolAdapter extends ToolAdapter {
  const ManualToolAdapter(super.toolId);

  @override
  String get mode => 'manual';

  @override
  bool get isReady => true;
}

class ApiToolAdapter extends ToolAdapter {
  const ApiToolAdapter(super.toolId, {required this.hasApiKey});

  final bool hasApiKey;

  @override
  String get mode => 'api';

  @override
  bool get isReady => hasApiKey;
}

class LocalToolAdapter extends ToolAdapter {
  const LocalToolAdapter(super.toolId, {required this.endpoint});

  final String endpoint;

  @override
  String get mode => 'local';

  @override
  bool get isReady => endpoint.trim().isNotEmpty;
}
