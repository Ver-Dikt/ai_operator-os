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
    final trimmed = task.trim().isEmpty ? 'твоя задача' : task.trim();
    return '${agent.name}: демо-запуск\n'
        '1. Уточнить цель: "$trimmed".\n'
        '2. Подобрать инструменты: ${agent.recommendedTools.take(4).join(', ')}.\n'
        '3. Подготовить результат: ${agent.outputType.toLowerCase()}.\n'
        '4. Реальное API/backend-выполнение оставить для следующей фазы.';
  }
}
