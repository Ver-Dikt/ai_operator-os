import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fluten_runtime.dart';

class FlutenRuntimeStore extends ChangeNotifier {
  FlutenRuntimeStore({required SharedPreferences preferences})
    : _preferences = preferences {
    _load();
  }

  static const _projectKey = 'fluten_current_project_v1';
  static const _sessionKey = 'fluten_current_session_v1';
  static const _jobsKey = 'fluten_generation_jobs_v1';
  static const _assetsKey = 'fluten_assets_v1';
  static const _eventsKey = 'fluten_session_events_v1';

  final SharedPreferences _preferences;

  late FlutenProject _project;
  late FlutenSession _session;
  List<FlutenGenerationJob> _jobs = <FlutenGenerationJob>[];
  List<FlutenAsset> _assets = <FlutenAsset>[];
  List<FlutenSessionEvent> _events = <FlutenSessionEvent>[];

  FlutenProject getCurrentProject() => _project;
  FlutenSession getCurrentSession() => _session;

  List<FlutenSessionEvent> getRecentEvents({int limit = 12}) {
    return _events.take(limit).toList(growable: false);
  }

  List<FlutenGenerationJob> getRecentJobs({int limit = 12}) {
    return _jobs.take(limit).toList(growable: false);
  }

  List<FlutenAsset> getAssets({int limit = 12}) {
    return _assets.take(limit).toList(growable: false);
  }

  Future<void> updateCurrentWorkspace(String workspace) async {
    _touchSession(activeWorkspace: workspace);
    await _persist();
    notifyListeners();
  }

  Future<void> clearCurrentSession() async {
    final now = DateTime.now();
    _session = FlutenSession(
      id: _id('session'),
      projectId: _project.id,
      name: 'Creative Session',
      activeWorkspace: 'text',
      createdAt: now,
      updatedAt: now,
    );
    _jobs = <FlutenGenerationJob>[];
    _assets = <FlutenAsset>[];
    _events = <FlutenSessionEvent>[];
    _project = _project.copyWith(updatedAt: now);
    await _persist();
    notifyListeners();
  }

  Future<void> setActivePromptDraft(String prompt) async {
    _touchSession(activePromptDraft: prompt);
    addEvent(
      type: 'prompt',
      title: 'Active prompt draft updated',
      detail: _preview(prompt),
      notify: false,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> setActiveProvider(String providerId, {String? route}) async {
    _touchSession(activeProviderId: providerId, activeRoute: route);
    addEvent(
      type: 'provider',
      title: 'Active provider updated',
      detail: route == null ? providerId : '$providerId / $route',
      notify: false,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> addEvent({
    required String type,
    required String title,
    String? detail,
    bool notify = true,
  }) async {
    _events.insert(
      0,
      FlutenSessionEvent(
        id: _id('event'),
        projectId: _project.id,
        sessionId: _session.id,
        type: type,
        title: title,
        detail: detail,
        createdAt: DateTime.now(),
      ),
    );
    _trim();
    if (notify) {
      await _persist();
      notifyListeners();
    }
  }

  Future<FlutenGenerationJob> addGenerationJob({
    required String workspaceType,
    required String routeType,
    required String prompt,
    required String status,
    String? providerId,
    String? resultLabel,
    String? resultUrl,
  }) async {
    final now = DateTime.now();
    final job = FlutenGenerationJob(
      id: _id('job'),
      projectId: _project.id,
      sessionId: _session.id,
      workspaceType: workspaceType,
      providerId: providerId,
      routeType: routeType,
      prompt: prompt,
      status: status,
      resultLabel: resultLabel,
      resultUrl: resultUrl,
      createdAt: now,
      updatedAt: now,
    );
    _jobs.insert(0, job);
    _touchSession(
      activeWorkspace: workspaceType,
      activeProviderId: providerId,
      activeRoute: routeType,
      activePromptDraft: prompt,
    );
    await addEvent(
      type: 'job',
      title: 'Generation job added',
      detail: '$workspaceType / $routeType / $status',
      notify: false,
    );
    _trim();
    await _persist();
    notifyListeners();
    return job;
  }

  Future<void> updateGenerationJob(
    String id, {
    String? status,
    String? resultLabel,
    String? resultUrl,
  }) async {
    final index = _jobs.indexWhere((job) => job.id == id);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(
      status: status,
      resultLabel: resultLabel,
      resultUrl: resultUrl,
      updatedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<FlutenAsset> addAsset({
    required String type,
    required String title,
    String? jobId,
    String? description,
    String? sourceProvider,
    String? url,
    String? localPath,
  }) async {
    final asset = FlutenAsset(
      id: _id('asset'),
      projectId: _project.id,
      sessionId: _session.id,
      jobId: jobId,
      type: type,
      title: title,
      description: description,
      sourceProvider: sourceProvider,
      url: url,
      localPath: localPath,
      createdAt: DateTime.now(),
    );
    _assets.insert(0, asset);
    await addEvent(
      type: 'asset',
      title: 'Asset saved',
      detail: '$type / $title',
      notify: false,
    );
    _trim();
    await _persist();
    notifyListeners();
    return asset;
  }

  void _load() {
    final now = DateTime.now();
    _project = _decodeObject(
      _projectKey,
      FlutenProject.fromJson,
      FlutenProject(
        id: 'project-${now.microsecondsSinceEpoch}',
        name: 'FLUTEN Project',
        description: 'Local creative operating workspace',
        createdAt: now,
        updatedAt: now,
      ),
    );
    _session = _decodeObject(
      _sessionKey,
      FlutenSession.fromJson,
      FlutenSession(
        id: 'session-${now.microsecondsSinceEpoch}',
        projectId: _project.id,
        name: 'Creative Session',
        activeWorkspace: 'text',
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (_session.projectId != _project.id) {
      _session = FlutenSession(
        id: _id('session'),
        projectId: _project.id,
        name: 'Creative Session',
        activeWorkspace: 'text',
        createdAt: now,
        updatedAt: now,
      );
    }
    _jobs = _decodeList(_jobsKey, FlutenGenerationJob.fromJson);
    _assets = _decodeList(_assetsKey, FlutenAsset.fromJson);
    _events = _decodeList(_eventsKey, FlutenSessionEvent.fromJson);
    _sort();
    _persist();
  }

  T _decodeObject<T>(
    String key,
    T Function(Map<String, Object?> json) fromJson,
    T fallback,
  ) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) return fallback;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return fallback;
    return fromJson(decoded.cast<String, Object?>());
  }

  List<T> _decodeList<T>(
    String key,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) return <T>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <T>[];
    return decoded
        .whereType<Map>()
        .map((item) => fromJson(item.cast<String, Object?>()))
        .toList();
  }

  Future<void> _persist() async {
    _sort();
    await _preferences.setString(_projectKey, jsonEncode(_project.toJson()));
    await _preferences.setString(_sessionKey, jsonEncode(_session.toJson()));
    await _preferences.setString(
      _jobsKey,
      jsonEncode(_jobs.map((job) => job.toJson()).toList()),
    );
    await _preferences.setString(
      _assetsKey,
      jsonEncode(_assets.map((asset) => asset.toJson()).toList()),
    );
    await _preferences.setString(
      _eventsKey,
      jsonEncode(_events.map((event) => event.toJson()).toList()),
    );
  }

  void _touchSession({
    String? activeWorkspace,
    String? activePromptDraft,
    String? activeProviderId,
    String? activeRoute,
  }) {
    _session = _session.copyWith(
      activeWorkspace: activeWorkspace,
      activePromptDraft: activePromptDraft,
      activeProviderId: activeProviderId,
      activeRoute: activeRoute,
      updatedAt: DateTime.now(),
    );
    _project = _project.copyWith(updatedAt: DateTime.now());
  }

  void _sort() {
    _jobs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _assets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _trim() {
    if (_jobs.length > 80) _jobs = _jobs.take(80).toList();
    if (_assets.length > 80) _assets = _assets.take(80).toList();
    if (_events.length > 120) _events = _events.take(120).toList();
  }

  String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  String _preview(String value) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= 80) return clean;
    return '${clean.substring(0, 80)}...';
  }
}
