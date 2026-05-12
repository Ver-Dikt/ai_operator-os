enum WorkspaceSessionType { text, image, video, audio, helper, workflow }

extension WorkspaceSessionTypeLabel on WorkspaceSessionType {
  String get label {
    return switch (this) {
      WorkspaceSessionType.text => 'text',
      WorkspaceSessionType.image => 'image',
      WorkspaceSessionType.video => 'video',
      WorkspaceSessionType.audio => 'audio',
      WorkspaceSessionType.helper => 'helper',
      WorkspaceSessionType.workflow => 'workflow',
    };
  }
}

class WorkspaceSession {
  const WorkspaceSession({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.preview,
    required this.workspaceType,
    required this.promptBlocks,
    required this.output,
    required this.openedTools,
    required this.usedHelpers,
    required this.workflowIds,
    this.routeSeed,
    this.entityId,
    this.projectId,
    this.pinned = false,
    this.favorite = false,
  });

  final String id;
  final String title;
  final WorkspaceSessionType type;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String preview;
  final String workspaceType;
  final bool pinned;
  final bool favorite;
  final List<String> promptBlocks;
  final String output;
  final List<String> openedTools;
  final List<String> usedHelpers;
  final List<String> workflowIds;
  final String? routeSeed;
  final String? entityId;
  final String? projectId;

  WorkspaceSession copyWith({
    String? title,
    WorkspaceSessionType? type,
    String? category,
    DateTime? updatedAt,
    String? preview,
    String? workspaceType,
    bool? pinned,
    bool? favorite,
    List<String>? promptBlocks,
    String? output,
    List<String>? openedTools,
    List<String>? usedHelpers,
    List<String>? workflowIds,
    String? routeSeed,
    String? entityId,
    String? projectId,
  }) {
    return WorkspaceSession(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preview: preview ?? this.preview,
      workspaceType: workspaceType ?? this.workspaceType,
      pinned: pinned ?? this.pinned,
      favorite: favorite ?? this.favorite,
      promptBlocks: promptBlocks ?? this.promptBlocks,
      output: output ?? this.output,
      openedTools: openedTools ?? this.openedTools,
      usedHelpers: usedHelpers ?? this.usedHelpers,
      workflowIds: workflowIds ?? this.workflowIds,
      routeSeed: routeSeed ?? this.routeSeed,
      entityId: entityId ?? this.entityId,
      projectId: projectId ?? this.projectId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preview': preview,
      'workspaceType': workspaceType,
      'pinned': pinned,
      'favorite': favorite,
      'promptBlocks': promptBlocks,
      'output': output,
      'openedTools': openedTools,
      'usedHelpers': usedHelpers,
      'workflowIds': workflowIds,
      'routeSeed': routeSeed,
      'entityId': entityId,
      'projectId': projectId,
    };
  }

  factory WorkspaceSession.fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String? ?? WorkspaceSessionType.text.name;
    return WorkspaceSession(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Сессия',
      type: WorkspaceSessionType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => WorkspaceSessionType.text,
      ),
      category: json['category'] as String? ?? 'workspace',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      preview: json['preview'] as String? ?? '',
      workspaceType: json['workspaceType'] as String? ?? 'text',
      pinned: json['pinned'] as bool? ?? false,
      favorite: json['favorite'] as bool? ?? false,
      promptBlocks: _stringList(json['promptBlocks']),
      output: json['output'] as String? ?? '',
      openedTools: _stringList(json['openedTools']),
      usedHelpers: _stringList(json['usedHelpers']),
      workflowIds: _stringList(json['workflowIds']),
      routeSeed: json['routeSeed'] as String?,
      entityId: json['entityId'] as String?,
      projectId: json['projectId'] as String?,
    );
  }
}

class MemoryProject {
  const MemoryProject({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.sessionIds,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> sessionIds;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemoryProject copyWith({
    String? title,
    String? description,
    String? category,
    List<String>? sessionIds,
    bool? pinned,
    DateTime? updatedAt,
  }) {
    return MemoryProject(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      sessionIds: sessionIds ?? this.sessionIds,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'sessionIds': sessionIds,
      'pinned': pinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MemoryProject.fromJson(Map<String, Object?> json) {
    return MemoryProject(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Проект',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'workspace',
      sessionIds: _stringList(json['sessionIds']),
      pinned: json['pinned'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}
