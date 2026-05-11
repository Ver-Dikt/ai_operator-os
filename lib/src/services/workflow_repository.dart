import '../data/seed_workflows.dart';
import '../models/workflow_template.dart';

class WorkflowRepository {
  const WorkflowRepository();

  List<WorkflowTemplate> all() => seedWorkflows;

  WorkflowTemplate? byId(String id) {
    for (final workflow in seedWorkflows) {
      if (workflow.id == id) return workflow;
    }
    return null;
  }
}
