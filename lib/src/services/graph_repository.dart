import '../data/seed_agents.dart';
import '../data/seed_prompts.dart';
import '../data/seed_tools.dart';
import '../data/seed_use_cases.dart';
import '../data/seed_workflows.dart';
import '../models/ai_agent.dart';
import '../models/ai_tool.dart';
import '../models/prompt_template.dart';
import '../models/use_case.dart';
import '../models/workflow_template.dart';

class GraphRepository {
  const GraphRepository();

  List<AiTool> toolsByIds(List<String> ids) =>
      seedTools.where((tool) => ids.contains(tool.id)).toList();

  List<AiAgent> agentsByIds(List<String> ids) =>
      seedAgents.where((agent) => ids.contains(agent.id)).toList();

  List<WorkflowTemplate> workflowsByIds(List<String> ids) =>
      seedWorkflows.where((workflow) => ids.contains(workflow.id)).toList();

  List<PromptTemplate> promptsByIds(List<String> ids) =>
      seedPrompts.where((prompt) => ids.contains(prompt.id)).toList();

  List<UseCase> useCasesByIds(List<String> ids) =>
      seedUseCases.where((useCase) => ids.contains(useCase.id)).toList();

  List<UseCase> useCasesForTool(String toolId) {
    return seedUseCases
        .where((useCase) => useCase.recommendedToolIds.contains(toolId))
        .toList();
  }

  List<UseCase> useCasesForAgent(String agentId) {
    return seedUseCases
        .where((useCase) => useCase.recommendedAgentIds.contains(agentId))
        .toList();
  }

  List<UseCase> useCasesForWorkflow(String workflowId) {
    return seedUseCases
        .where((useCase) => useCase.recommendedWorkflowIds.contains(workflowId))
        .toList();
  }
}
