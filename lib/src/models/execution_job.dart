enum ExecutionJobWorkspace { image, video, audio, text, director, browser }

enum ExecutionJobStatus {
  idle,
  prepared,
  queued,
  running,
  completed,
  failed,
  cancelled,
  requiresApiKey,
  manualOnly,
  localUnavailable,
  needsWorkflow,
  needsExecutionImplementation,
  browserReady,
  openedExternal,
  completedManual,
}

enum ExecutionJobMode { api, browser, local, manual }

extension ExecutionJobStatusLabel on ExecutionJobStatus {
  String get label {
    return switch (this) {
      ExecutionJobStatus.idle => 'Ожидает',
      ExecutionJobStatus.prepared => 'Подготовлено',
      ExecutionJobStatus.queued => 'В очереди',
      ExecutionJobStatus.running => 'Выполняется',
      ExecutionJobStatus.completed => 'Готово',
      ExecutionJobStatus.failed => 'Ошибка',
      ExecutionJobStatus.cancelled => 'Отменено',
      ExecutionJobStatus.requiresApiKey => 'Нужен API-ключ',
      ExecutionJobStatus.manualOnly => 'Ручной режим',
      ExecutionJobStatus.localUnavailable => 'Локально недоступно',
      ExecutionJobStatus.needsWorkflow => 'Нужен workflow',
      ExecutionJobStatus.needsExecutionImplementation =>
        'Нужна реализация запуска',
      ExecutionJobStatus.browserReady => 'Browser ready',
      ExecutionJobStatus.openedExternal => 'Открыт внешний сайт',
      ExecutionJobStatus.completedManual => 'Результат сохранён вручную',
    };
  }
}

extension ExecutionJobModeLabel on ExecutionJobMode {
  String get label {
    return switch (this) {
      ExecutionJobMode.api => 'Через API',
      ExecutionJobMode.browser => 'Через сайт',
      ExecutionJobMode.local => 'Локально',
      ExecutionJobMode.manual => 'Вручную',
    };
  }
}

class ExecutionJob {
  const ExecutionJob({
    required this.id,
    required this.workspace,
    required this.providerId,
    required this.providerName,
    required this.capability,
    required this.inputPrompt,
    required this.composedPrompt,
    required this.status,
    required this.executionMode,
    required this.createdAt,
    required this.updatedAt,
    this.resultAssets = const [],
    this.errorMessage,
    this.metadata = const {},
  });

  final String id;
  final ExecutionJobWorkspace workspace;
  final String providerId;
  final String providerName;
  final String capability;
  final String inputPrompt;
  final String composedPrompt;
  final ExecutionJobStatus status;
  final ExecutionJobMode executionMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> resultAssets;
  final String? errorMessage;
  final Map<String, String> metadata;

  ExecutionJob copyWith({
    ExecutionJobStatus? status,
    ExecutionJobMode? executionMode,
    DateTime? updatedAt,
    List<String>? resultAssets,
    String? errorMessage,
    Map<String, String>? metadata,
  }) {
    return ExecutionJob(
      id: id,
      workspace: workspace,
      providerId: providerId,
      providerName: providerName,
      capability: capability,
      inputPrompt: inputPrompt,
      composedPrompt: composedPrompt,
      status: status ?? this.status,
      executionMode: executionMode ?? this.executionMode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resultAssets: resultAssets ?? this.resultAssets,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'workspace': workspace.name,
      'providerId': providerId,
      'providerName': providerName,
      'capability': capability,
      'inputPrompt': inputPrompt,
      'composedPrompt': composedPrompt,
      'status': status.name,
      'executionMode': executionMode.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resultAssets': resultAssets,
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  factory ExecutionJob.fromJson(Map<String, Object?> json) {
    return ExecutionJob(
      id: json['id'] as String? ?? '',
      workspace: _enumByName(
        ExecutionJobWorkspace.values,
        json['workspace'] as String?,
        ExecutionJobWorkspace.text,
      ),
      providerId: json['providerId'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      capability: json['capability'] as String? ?? '',
      inputPrompt: json['inputPrompt'] as String? ?? '',
      composedPrompt: json['composedPrompt'] as String? ?? '',
      status: _enumByName(
        ExecutionJobStatus.values,
        json['status'] as String?,
        ExecutionJobStatus.idle,
      ),
      executionMode: _enumByName(
        ExecutionJobMode.values,
        json['executionMode'] as String?,
        ExecutionJobMode.manual,
      ),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      resultAssets:
          (json['resultAssets'] as List?)?.whereType<String>().toList() ??
              const [],
      errorMessage: json['errorMessage'] as String?,
      metadata:
          (json['metadata'] as Map?)?.cast<String, String>() ??
              const <String, String>{},
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

DateTime _date(Object? value) {
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
