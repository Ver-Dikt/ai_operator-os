import '../data/seed_tools.dart';
import '../models/ai_tool.dart';

class ToolRepository {
  const ToolRepository();

  List<AiTool> all() => seedTools;

  AiTool? byId(String id) {
    for (final tool in seedTools) {
      if (tool.id == id) return tool;
    }
    return null;
  }

  List<AiTool> search(String query) =>
      seedTools.where((tool) => tool.matches(query)).toList();
}
