import '../../data/seed_generation_providers.dart';
import '../../models/generation/generation_provider.dart';

class GenerationProviderRegistry {
  const GenerationProviderRegistry();

  List<GenerationProvider> all() => seedGenerationProviders;

  List<GenerationProvider> forCapability(GenerationCapability capability) {
    return seedGenerationProviders
        .where((provider) => provider.supports(capability))
        .toList(growable: false);
  }

  GenerationProvider byId(String id) {
    return seedGenerationProviders.firstWhere(
      (provider) => provider.id == id,
      orElse: () => seedGenerationProviders.first,
    );
  }
}
