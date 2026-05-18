import 'execution_mode.dart';

enum AiProviderType { api, local, manual, browser, hybrid }

enum AiProviderStatus {
  available,
  notConfigured,
  connectedMock,
  localUnavailable,
  comingSoon,
}

class AiProvider {
  const AiProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.executionModes,
    required this.status,
    required this.supportedWorkspaces,
    required this.description,
    required this.apiKeyRequired,
    required this.notes,
    this.baseUrl,
    this.localEndpoint,
  });

  final String id;
  final String name;
  final AiProviderType type;
  final List<ExecutionMode> executionModes;
  final AiProviderStatus status;
  final List<String> supportedWorkspaces;
  final String description;
  final String? baseUrl;
  final bool apiKeyRequired;
  final String? localEndpoint;
  final String notes;
}

extension AiProviderStatusLabel on AiProviderStatus {
  String get label {
    return switch (this) {
      AiProviderStatus.available => 'Manual Ready',
      AiProviderStatus.notConfigured => 'API Key Needed',
      AiProviderStatus.connectedMock => 'Local Connected',
      AiProviderStatus.localUnavailable => 'Local Runtime Unavailable',
      AiProviderStatus.comingSoon => 'Automation Layer Pending',
    };
  }
}

extension AiProviderTypeLabel on AiProviderType {
  String get label {
    return switch (this) {
      AiProviderType.api => 'API',
      AiProviderType.local => 'Local',
      AiProviderType.manual => 'Manual',
      AiProviderType.browser => 'Browser',
      AiProviderType.hybrid => 'Hybrid',
    };
  }
}
