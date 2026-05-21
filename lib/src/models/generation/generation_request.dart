import 'generation_provider.dart';

class GenerationRequest {
  const GenerationRequest({
    required this.prompt,
    required this.providerId,
    required this.capability,
    required this.aspectRatio,
    this.modelId,
    this.negativePrompt,
    this.durationSeconds,
    this.quality,
    this.seed,
    this.referencePaths = const [],
    this.metadata = const {},
  });

  final String prompt;
  final String providerId;
  final GenerationCapability capability;
  final String aspectRatio;
  final String? modelId;
  final String? negativePrompt;
  final int? durationSeconds;
  final String? quality;
  final int? seed;
  final List<String> referencePaths;
  final Map<String, String> metadata;

  bool get hasReferences => referencePaths.isNotEmpty;
}
