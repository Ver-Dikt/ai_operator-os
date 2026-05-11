import '../data/seed_prompts.dart';
import '../models/prompt_template.dart';

class PromptRepository {
  const PromptRepository();

  List<PromptTemplate> all() => seedPrompts;

  List<PromptTemplate> byCategory(String category) {
    return seedPrompts
        .where((prompt) => prompt.category == category)
        .toList();
  }
}
