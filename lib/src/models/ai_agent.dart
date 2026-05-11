enum AgentStatus { prototype, active, planned }

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
}
