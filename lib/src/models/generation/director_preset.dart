import 'camera_profile.dart';

class DirectorPreset {
  const DirectorPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.camera,
    required this.moodTags,
    required this.negativePrompt,
  });

  final String id;
  final String name;
  final String description;
  final CameraProfile camera;
  final List<String> moodTags;
  final String negativePrompt;

  String buildPrompt(String basePrompt) {
    final cinematicPrompt = camera.compilePrompt(basePrompt);
    return '$cinematicPrompt, настроение: ${moodTags.join(', ')}';
  }
}
