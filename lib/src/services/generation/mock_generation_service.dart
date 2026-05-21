import '../../models/generation/generation_job.dart';
import '../../models/generation/generation_provider.dart';
import '../../models/generation/generation_request.dart';
import 'generation_provider_registry.dart';

class MockGenerationService {
  const MockGenerationService({
    this.registry = const GenerationProviderRegistry(),
  });

  final GenerationProviderRegistry registry;

  GenerationJob createMockJob(GenerationRequest request) {
    final provider = registry.byId(request.providerId);
    final now = DateTime.now();
    final title = _titleFor(request);
    return GenerationJob(
      id: 'mock-${now.microsecondsSinceEpoch}',
      title: title,
      request: request,
      providerName: provider.name,
      status: GenerationJobStatus.completed,
      createdAt: now,
      updatedAt: now,
      progress: 1,
      previewUrl: _mockPreviewFor(request.capability),
      outputUrl: _mockPreviewFor(request.capability),
    );
  }

  String _titleFor(GenerationRequest request) {
    final clean = request.prompt.trim();
    if (clean.isEmpty) return request.capability.label;
    return clean.length <= 42 ? clean : '${clean.substring(0, 42)}...';
  }

  String _mockPreviewFor(GenerationCapability capability) {
    return switch (capability) {
      GenerationCapability.textToImage ||
      GenerationCapability.imageToImage => 'mock://image/cinematic-frame',
      GenerationCapability.textToVideo ||
      GenerationCapability.imageToVideo ||
      GenerationCapability.videoToVideo => 'mock://video/cinematic-shot',
    };
  }
}
