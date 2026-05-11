enum ContentFormat {
  tiktok,
  reels,
  shorts,
  youtube,
  musicPromo,
  cinematicScene,
}

enum ContentStatus { draft, planned, running, exported }

class ScenePlan {
  const ScenePlan({
    required this.sceneNumber,
    required this.dramaticPurpose,
    required this.cameraLogic,
    required this.blocking,
    required this.visualPrompt,
    required this.negativePrompt,
    required this.voiceover,
    required this.musicDirection,
    required this.toolRecommendation,
  });

  final int sceneNumber;
  final String dramaticPurpose;
  final String cameraLogic;
  final String blocking;
  final String visualPrompt;
  final String negativePrompt;
  final String voiceover;
  final String musicDirection;
  final String toolRecommendation;
}

class ContentProject {
  const ContentProject({
    required this.id,
    required this.title,
    required this.format,
    required this.idea,
    required this.targetAudience,
    required this.mood,
    required this.duration,
    required this.scenes,
    required this.prompts,
    required this.tools,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final ContentFormat format;
  final String idea;
  final String targetAudience;
  final String mood;
  final String duration;
  final List<ScenePlan> scenes;
  final List<String> prompts;
  final List<String> tools;
  final ContentStatus status;
  final DateTime createdAt;
}
