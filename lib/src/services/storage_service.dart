import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workspace_memory.dart';

class StorageService {
  const StorageService();

  static const _sessionsKey = 'workspace_sessions_v1';
  static const _projectsKey = 'workspace_projects_v1';

  bool get hasCloudSync => false;
  String get phaseNote => 'Local-only storage in Phase 1. Backend later.';

  Future<List<WorkspaceSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => WorkspaceSession.fromJson(item.cast<String, Object?>()))
        .where((item) => item.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveSessions(List<WorkspaceSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final ordered = [...sessions]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await prefs.setString(
      _sessionsKey,
      jsonEncode(ordered.take(60).map((item) => item.toJson()).toList()),
    );
  }

  Future<List<MemoryProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_projectsKey);
    if (raw == null || raw.isEmpty) return _defaultProjects();
    final decoded = jsonDecode(raw);
    if (decoded is! List) return _defaultProjects();
    final projects = decoded
        .whereType<Map>()
        .map((item) => MemoryProject.fromJson(item.cast<String, Object?>()))
        .where((item) => item.id.isNotEmpty)
        .toList();
    if (projects.isEmpty) return _defaultProjects();
    return projects..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveProjects(List<MemoryProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final ordered = [...projects]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await prefs.setString(
      _projectsKey,
      jsonEncode(ordered.map((item) => item.toJson()).toList()),
    );
  }
}

List<MemoryProject> _defaultProjects() {
  final now = DateTime.now();
  return [
    MemoryProject(
      id: 'project-ai-shorts',
      title: 'AI Shorts Factory',
      description: 'Пакетные Reels, Shorts, сценарии, сцены и промпты.',
      category: 'video',
      sessionIds: const [],
      createdAt: now,
      updatedAt: now,
      pinned: true,
    ),
    MemoryProject(
      id: 'project-music-promo',
      title: 'Music Promo',
      description: 'Промо-паки для треков: видео, обложки, voiceover.',
      category: 'audio',
      sessionIds: const [],
      createdAt: now,
      updatedAt: now,
    ),
    MemoryProject(
      id: 'project-freelance-outreach',
      title: 'Freelance Outreach',
      description: 'AI-услуги, предложения, outreach и клиентские кейсы.',
      category: 'business',
      sessionIds: const [],
      createdAt: now,
      updatedAt: now,
    ),
    MemoryProject(
      id: 'project-youtube-automation',
      title: 'YouTube Automation',
      description: 'Пайплайны для видео, thumbnails, scripts и публикаций.',
      category: 'automation',
      sessionIds: const [],
      createdAt: now,
      updatedAt: now,
    ),
    MemoryProject(
      id: 'project-ai-localization',
      title: 'AI Localization',
      description: 'Перевод, dubbing, subtitles и локализация контента.',
      category: 'localization',
      sessionIds: const [],
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
