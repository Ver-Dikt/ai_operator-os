class Workflow {
  const Workflow({
    required this.title,
    required this.description,
    required this.steps,
  });

  final String title;
  final String description;
  final List<String> steps;
}
