class CameraProfile {
  const CameraProfile({
    required this.id,
    required this.name,
    required this.cameraBody,
    required this.lens,
    required this.focalLength,
    required this.aperture,
    required this.motion,
    required this.light,
    required this.color,
  });

  final String id;
  final String name;
  final String cameraBody;
  final String lens;
  final int focalLength;
  final String aperture;
  final String motion;
  final String light;
  final String color;

  String compilePrompt(String basePrompt) {
    final cleanPrompt = basePrompt.trim();
    return [
      if (cleanPrompt.isNotEmpty) cleanPrompt,
      'снято на $cameraBody',
      'объектив $lens, $focalLength mm, $aperture',
      'движение камеры: $motion',
      'свет: $light',
      'цвет и фактура: $color',
      'кинематографичная композиция, выразительная глубина кадра',
    ].join(', ');
  }
}
