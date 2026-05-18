import 'dart:async';
import 'dart:io';

import '../models/ai_provider.dart';

class LocalRuntimeStatusService {
  const LocalRuntimeStatusService();

  Future<LocalRuntimeState> checkProvider(AiProvider provider) async {
    final endpoint = provider.localEndpoint;
    if (endpoint == null || endpoint.trim().isEmpty) {
      return LocalRuntimeState.manual;
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request = await client
          .getUrl(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 2));
      final response = await request.close().timeout(
        const Duration(seconds: 2),
      );
      await response.drain<void>();
      return response.statusCode < 500
          ? LocalRuntimeState.connected
          : LocalRuntimeState.unavailable;
    } catch (_) {
      return LocalRuntimeState.unavailable;
    } finally {
      client.close(force: true);
    }
  }
}
