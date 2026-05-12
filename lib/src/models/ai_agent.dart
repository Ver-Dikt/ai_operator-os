enum AgentStatus { prototype, active, planned }

extension AgentStatusLabel on AgentStatus {
  String get label {
    return switch (this) {
      AgentStatus.prototype => 'Прототип',
      AgentStatus.active => 'Активен',
      AgentStatus.planned => 'Запланирован',
    };
  }
}

class AiAgent {
  const AiAgent({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    required this.avatarEmoji,
    required this.systemPrompt,
    required this.inputSchema,
    required this.outputType,
    required this.recommendedTools,
    required this.canUseInternet,
    required this.canUseApi,
    required this.isLocalCapable,
    required this.status,
    this.category = 'General',
    this.toolIds = const [],
    this.workflowIds = const [],
    this.promptTemplateIds = const [],
    this.taskTypes = const [],
    this.humanApprovalRequired = true,
  });

  final String id;
  final String name;
  final String role;
  final String description;
  final String avatarEmoji;
  final String systemPrompt;
  final String inputSchema;
  final String outputType;
  final List<String> recommendedTools;
  final bool canUseInternet;
  final bool canUseApi;
  final bool isLocalCapable;
  final AgentStatus status;
  final String category;
  final List<String> toolIds;
  final List<String> workflowIds;
  final List<String> promptTemplateIds;
  final List<String> taskTypes;
  final bool humanApprovalRequired;
}
