import 'execution_mode.dart';

enum AiProviderType { api, local, manual, browser, hybrid }

enum AiProviderStatus {
  available,
  notConfigured,
  connectedMock,
  localUnavailable,
  comingSoon,
}

enum LocalRuntimeState { connected, unavailable, checking, manual, unknown }

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
      AiProviderStatus.available => 'Ручной запуск',
      AiProviderStatus.notConfigured => 'Требуется API ключ',
      AiProviderStatus.connectedMock => 'Локально доступно',
      AiProviderStatus.localUnavailable => 'Локальный runtime недоступен',
      AiProviderStatus.comingSoon => 'Будет позже',
    };
  }
}

extension AiProviderTypeLabel on AiProviderType {
  String get label {
    return switch (this) {
      AiProviderType.api => 'API',
      AiProviderType.local => 'Локально',
      AiProviderType.manual => 'Ручной',
      AiProviderType.browser => 'Browser',
      AiProviderType.hybrid => 'Гибрид',
    };
  }
}

extension LocalRuntimeStateLabel on LocalRuntimeState {
  String get label {
    return switch (this) {
      LocalRuntimeState.connected => 'Локально доступно',
      LocalRuntimeState.unavailable => 'Endpoint недоступен',
      LocalRuntimeState.checking => 'Проверка runtime...',
      LocalRuntimeState.manual => 'Ручной запуск',
      LocalRuntimeState.unknown => 'Статус неизвестен',
    };
  }
}
