// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import '../models/ai_provider.dart';

class LocalRuntimeStatusService {
  const LocalRuntimeStatusService();

  Future<LocalRuntimeState> checkProvider(AiProvider provider) async {
    final endpoint = provider.localEndpoint;
    if (endpoint == null || endpoint.trim().isEmpty) {
      return LocalRuntimeState.manual;
    }

    try {
      final request = await html.HttpRequest.request(
        endpoint,
        method: 'GET',
      ).timeout(const Duration(seconds: 2));
      return request.status != null && request.status! < 500
          ? LocalRuntimeState.connected
          : LocalRuntimeState.unavailable;
    } catch (_) {
      return LocalRuntimeState.unavailable;
    }
  }
}
