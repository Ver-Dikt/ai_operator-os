import '../data/seed_agents.dart';
import '../models/ai_agent.dart';

class AgentRepository {
  const AgentRepository();

  List<AiAgent> all() => seedAgents;

  AiAgent? byId(String id) {
    for (final agent in seedAgents) {
      if (agent.id == id) return agent;
    }
    return null;
  }

  String runMock(AiAgent agent, String task) {
    final trimmed = task.trim().isEmpty ? 'your task' : task.trim();
    return '${agent.name} mock run:\n'
        '1. Clarify the goal for "$trimmed".\n'
        '2. Pick tools: ${agent.recommendedTools.take(4).join(', ')}.\n'
        '3. Produce ${agent.outputType.toLowerCase()}.\n'
        '4. Mark API/backend execution as planned for a later phase.';
  }
}
