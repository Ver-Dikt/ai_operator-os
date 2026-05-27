enum FlutenWorkspaceType { text, image, video, browser, director }

enum FlutenRouteType { local, api, browser, external, manual, mock }

enum FlutenJobStatus {
  draft,
  prepared,
  running,
  completed,
  failed,
  saved,
  manual,
}

enum FlutenAssetType { prompt, image, video, audio, link, text, manual }

class FlutenProject {
  const FlutenProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;

  FlutenProject copyWith({
    String? name,
    DateTime? updatedAt,
    String? description,
  }) {
    return FlutenProject(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
    };
  }

  factory FlutenProject.fromJson(Map<String, Object?> json) {
    return FlutenProject(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'FLUTEN Project',
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      description: json['description'] as String?,
    );
  }
}

class FlutenSession {
  const FlutenSession({
    required this.id,
    required this.projectId,
    required this.name,
    required this.activeWorkspace,
    required this.createdAt,
    required this.updatedAt,
    this.sourceIdea,
    this.activePromptDraft,
    this.activeProviderId,
    this.activeRoute,
  });

  final String id;
  final String projectId;
  final String name;
  final String activeWorkspace;
  final String? sourceIdea;
  final String? activePromptDraft;
  final String? activeProviderId;
  final String? activeRoute;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlutenSession copyWith({
    String? name,
    String? activeWorkspace,
    String? sourceIdea,
    String? activePromptDraft,
    String? activeProviderId,
    String? activeRoute,
    DateTime? updatedAt,
  }) {
    return FlutenSession(
      id: id,
      projectId: projectId,
      name: name ?? this.name,
      activeWorkspace: activeWorkspace ?? this.activeWorkspace,
      sourceIdea: sourceIdea ?? this.sourceIdea,
      activePromptDraft: activePromptDraft ?? this.activePromptDraft,
      activeProviderId: activeProviderId ?? this.activeProviderId,
      activeRoute: activeRoute ?? this.activeRoute,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'activeWorkspace': activeWorkspace,
      'sourceIdea': sourceIdea,
      'activePromptDraft': activePromptDraft,
      'activeProviderId': activeProviderId,
      'activeRoute': activeRoute,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FlutenSession.fromJson(Map<String, Object?> json) {
    return FlutenSession(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      name: json['name'] as String? ?? 'Creative Session',
      activeWorkspace: json['activeWorkspace'] as String? ?? 'text',
      sourceIdea: json['sourceIdea'] as String?,
      activePromptDraft: json['activePromptDraft'] as String?,
      activeProviderId: json['activeProviderId'] as String?,
      activeRoute: json['activeRoute'] as String?,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}

class FlutenGenerationJob {
  const FlutenGenerationJob({
    required this.id,
    required this.projectId,
    required this.sessionId,
    required this.workspaceType,
    required this.routeType,
    required this.prompt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.providerId,
    this.resultLabel,
    this.resultUrl,
  });

  final String id;
  final String projectId;
  final String sessionId;
  final String workspaceType;
  final String? providerId;
  final String routeType;
  final String prompt;
  final String status;
  final String? resultLabel;
  final String? resultUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlutenGenerationJob copyWith({
    String? status,
    String? resultLabel,
    String? resultUrl,
    DateTime? updatedAt,
  }) {
    return FlutenGenerationJob(
      id: id,
      projectId: projectId,
      sessionId: sessionId,
      workspaceType: workspaceType,
      providerId: providerId,
      routeType: routeType,
      prompt: prompt,
      status: status ?? this.status,
      resultLabel: resultLabel ?? this.resultLabel,
      resultUrl: resultUrl ?? this.resultUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'sessionId': sessionId,
      'workspaceType': workspaceType,
      'providerId': providerId,
      'routeType': routeType,
      'prompt': prompt,
      'status': status,
      'resultLabel': resultLabel,
      'resultUrl': resultUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FlutenGenerationJob.fromJson(Map<String, Object?> json) {
    return FlutenGenerationJob(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      workspaceType: json['workspaceType'] as String? ?? 'text',
      providerId: json['providerId'] as String?,
      routeType: json['routeType'] as String? ?? 'manual',
      prompt: json['prompt'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      resultLabel: json['resultLabel'] as String?,
      resultUrl: json['resultUrl'] as String?,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}

class FlutenAsset {
  const FlutenAsset({
    required this.id,
    required this.projectId,
    required this.sessionId,
    required this.type,
    required this.title,
    required this.createdAt,
    this.jobId,
    this.description,
    this.sourceProvider,
    this.url,
    this.localPath,
  });

  final String id;
  final String projectId;
  final String sessionId;
  final String? jobId;
  final String type;
  final String title;
  final String? description;
  final String? sourceProvider;
  final String? url;
  final String? localPath;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'sessionId': sessionId,
      'jobId': jobId,
      'type': type,
      'title': title,
      'description': description,
      'sourceProvider': sourceProvider,
      'url': url,
      'localPath': localPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FlutenAsset.fromJson(Map<String, Object?> json) {
    return FlutenAsset(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      jobId: json['jobId'] as String?,
      type: json['type'] as String? ?? 'manual',
      title: json['title'] as String? ?? 'Asset',
      description: json['description'] as String?,
      sourceProvider: json['sourceProvider'] as String?,
      url: json['url'] as String?,
      localPath: json['localPath'] as String?,
      createdAt: _date(json['createdAt']),
    );
  }
}

class FlutenSessionEvent {
  const FlutenSessionEvent({
    required this.id,
    required this.projectId,
    required this.sessionId,
    required this.type,
    required this.title,
    required this.createdAt,
    this.detail,
  });

  final String id;
  final String projectId;
  final String sessionId;
  final String type;
  final String title;
  final String? detail;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'sessionId': sessionId,
      'type': type,
      'title': title,
      'detail': detail,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FlutenSessionEvent.fromJson(Map<String, Object?> json) {
    return FlutenSessionEvent(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      type: json['type'] as String? ?? 'event',
      title: json['title'] as String? ?? 'Runtime event',
      detail: json['detail'] as String?,
      createdAt: _date(json['createdAt']),
    );
  }
}

DateTime _date(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
