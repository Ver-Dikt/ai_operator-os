import 'dart:async';
import 'dart:convert';
import 'dart:io';

class AceStepExecutionResult {
  const AceStepExecutionResult({
    required this.success,
    this.localPaths = const [],
    this.taskId,
    this.error,
  });

  final bool success;
  final List<String> localPaths;
  final String? taskId;
  final String? error;
}

class AceStepExecutionService {
  const AceStepExecutionService();

  Future<AceStepExecutionResult> generate({
    required String endpoint,
    required String prompt,
    required String lyrics,
    required int durationSeconds,
  }) async {
    if (prompt.trim().isEmpty) {
      return const AceStepExecutionResult(
        success: false,
        error: 'Сначала опишите музыку.',
      );
    }
    final base = endpoint.trim().replaceFirst(RegExp(r'/+$'), '');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final submit = await _postJson(client, Uri.parse('$base/release_task'), {
        'prompt': prompt.trim(),
        'lyrics': lyrics.trim(),
        'thinking': true,
        'use_format': true,
        'audio_format': 'mp3',
        'audio_duration': durationSeconds.clamp(10, 600),
        'inference_steps': 8,
        'batch_size': 1,
        'use_random_seed': true,
      });
      final submitted = _decodeMap(submit.body);
      if (submit.statusCode < 200 ||
          submit.statusCode >= 300 ||
          submitted['code'] != 200) {
        return AceStepExecutionResult(
          success: false,
          error: _error('ACE-Step отклонил задачу', submit.statusCode, submitted),
        );
      }
      final data = submitted['data'];
      final taskId = data is Map ? data['task_id']?.toString() : null;
      if (taskId == null || taskId.isEmpty) {
        return const AceStepExecutionResult(
          success: false,
          error: 'ACE-Step не вернул task_id.',
        );
      }

      final files = await _waitForFiles(client, base, taskId);
      if (files.isEmpty) {
        return AceStepExecutionResult(
          success: false,
          taskId: taskId,
          error: 'ACE-Step не вернул аудиофайл до истечения времени ожидания.',
        );
      }
      final directory = await _outputDirectory();
      final paths = <String>[];
      for (var index = 0; index < files.length; index++) {
        final fileRef = files[index];
        final uri = fileRef.startsWith('http://') || fileRef.startsWith('https://')
            ? Uri.parse(fileRef)
            : Uri.parse('$base${fileRef.startsWith('/') ? '' : '/'}$fileRef');
        final bytes = await _getBytes(client, uri);
        if (bytes == null || bytes.isEmpty) continue;
        final suffix = files.length > 1 ? '-${index + 1}' : '';
        final file = File(
          '${directory.path}${Platform.pathSeparator}ace-step-$taskId$suffix.mp3',
        );
        await file.writeAsBytes(bytes, flush: true);
        paths.add(file.path);
      }
      if (paths.isEmpty) {
        return AceStepExecutionResult(
          success: false,
          taskId: taskId,
          error: 'ACE-Step завершил задачу, но аудиофайл не загрузился.',
        );
      }
      return AceStepExecutionResult(
        success: true,
        localPaths: paths,
        taskId: taskId,
      );
    } on TimeoutException {
      return const AceStepExecutionResult(
        success: false,
        error: 'ACE-Step не ответил вовремя.',
      );
    } on SocketException {
      return const AceStepExecutionResult(
        success: false,
        error: 'Нет соединения с ACE-Step API на локальном компьютере.',
      );
    } on _AceStepTaskException catch (error) {
      return AceStepExecutionResult(
        success: false,
        error: 'ACE-Step не выполнил генерацию: ${error.message}',
      );
    } on FormatException {
      return const AceStepExecutionResult(
        success: false,
        error: 'ACE-Step вернул некорректный JSON.',
      );
    } catch (_) {
      return const AceStepExecutionResult(
        success: false,
        error: 'Не удалось выполнить задачу ACE-Step.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<List<String>> _waitForFiles(
    HttpClient client,
    String base,
    String taskId,
  ) async {
    final deadline = DateTime.now().add(const Duration(minutes: 30));
    while (DateTime.now().isBefore(deadline)) {
      final response = await _postJson(
        client,
        Uri.parse('$base/query_result'),
        {'task_id_list': [taskId]},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _decodeMap(response.body);
        final data = body['data'];
        if (data is List && data.isNotEmpty && data.first is Map) {
          final task = data.first as Map;
          final status = task['status'];
          if (status == 2) {
            throw _AceStepTaskException(
              task['error']?.toString() ?? 'ACE-Step failed',
            );
          }
          if (status == 1) {
            final rawResult = task['result'];
            final result = rawResult is String ? jsonDecode(rawResult) : rawResult;
            if (result is List) {
              return result
                  .whereType<Map>()
                  .map((item) => item['file']?.toString() ?? '')
                  .where((value) => value.isNotEmpty)
                  .toList(growable: false);
            }
          }
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return const [];
  }

  Future<_TextResponse> _postJson(
    HttpClient client,
    Uri uri,
    Map<String, Object?> body,
  ) async {
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close().timeout(const Duration(seconds: 30));
    return _TextResponse(
      response.statusCode,
      await utf8.decoder.bind(response).join(),
    );
  }

  Future<List<int>?> _getBytes(HttpClient client, Uri uri) async {
    final request = await client.getUrl(uri);
    final response = await request.close().timeout(const Duration(minutes: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    return response.fold<List<int>>(
      <int>[],
      (buffer, chunk) => buffer..addAll(chunk),
    );
  }

  Map<String, Object?> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) throw const FormatException('Expected object');
    return decoded.cast<String, Object?>();
  }

  Future<Directory> _outputDirectory() async {
    final appData = Platform.environment['APPDATA']?.trim();
    final root = appData != null && appData.isNotEmpty
        ? appData
        : '${Directory.current.path}${Platform.pathSeparator}.dart_appdata';
    final directory = Directory(
      '$root${Platform.pathSeparator}FLUTEN${Platform.pathSeparator}'
      'outputs${Platform.pathSeparator}audio',
    );
    await directory.create(recursive: true);
    return directory;
  }

  String _error(String prefix, int statusCode, Map<String, Object?> body) {
    final detail = body['error'] ?? body['detail'];
    return detail == null
        ? '$prefix (HTTP $statusCode).'
        : '$prefix: $detail';
  }
}

class _TextResponse {
  const _TextResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

class _AceStepTaskException implements Exception {
  const _AceStepTaskException(this.message);

  final String message;

  @override
  String toString() => message;
}
