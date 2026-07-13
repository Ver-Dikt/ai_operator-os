import 'dart:async';
import 'dart:convert';
import 'dart:io';

class GeminiVeoResult {
  const GeminiVeoResult({
    required this.success,
    this.localPath,
    this.operationName,
    this.error,
  });

  final bool success;
  final String? localPath;
  final String? operationName;
  final String? error;
}

class GeminiVeoService {
  const GeminiVeoService();

  Future<GeminiVeoResult> generate({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required String aspectRatio,
    required int durationSeconds,
    required String resolution,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const GeminiVeoResult(
        success: false,
        error: 'Добавьте Gemini API key в настройках.',
      );
    }
    if (prompt.trim().isEmpty) {
      return const GeminiVeoResult(
        success: false,
        error: 'Сначала напишите prompt для видео.',
      );
    }
    final base = _baseUrl(baseUrl);
    final selectedModel = model.trim().startsWith('veo-')
        ? model.trim()
        : 'veo-3.1-generate-preview';
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final submit = await _postJson(
        client,
        Uri.parse('$base/models/$selectedModel:predictLongRunning'),
        apiKey,
        {
          'instances': [
            {'prompt': prompt.trim()},
          ],
          'parameters': {
            'aspectRatio': aspectRatio == '9:16' ? '9:16' : '16:9',
            'durationSeconds': durationSeconds.clamp(4, 8),
            'resolution': resolution,
            'personGeneration': 'allow_adult',
          },
        },
      );
      final submitted = _decodeMap(submit.body);
      if (submit.statusCode < 200 || submit.statusCode >= 300) {
        return GeminiVeoResult(
          success: false,
          error: _apiError(submit.statusCode, submitted),
        );
      }
      final operationName = submitted['name']?.toString();
      if (operationName == null || operationName.isEmpty) {
        return const GeminiVeoResult(
          success: false,
          error: 'Veo не вернул имя операции.',
        );
      }
      final completed = await _waitForOperation(
        client,
        base,
        apiKey,
        operationName,
      );
      if (completed['error'] != null) {
        return GeminiVeoResult(
          success: false,
          operationName: operationName,
          error: 'Veo не создал видео: ${completed['error']}',
        );
      }
      final videoUri = _videoUri(completed);
      if (videoUri == null) {
        return GeminiVeoResult(
          success: false,
          operationName: operationName,
          error: 'Операция Veo завершена без ссылки на видео.',
        );
      }
      final bytes = await _getBytes(client, Uri.parse(videoUri), apiKey);
      if (bytes == null || bytes.isEmpty) {
        return GeminiVeoResult(
          success: false,
          operationName: operationName,
          error: 'Не удалось скачать готовое видео Veo.',
        );
      }
      final directory = await _outputDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}'
        'veo-${DateTime.now().microsecondsSinceEpoch}.mp4',
      );
      await file.writeAsBytes(bytes, flush: true);
      return GeminiVeoResult(
        success: true,
        localPath: file.path,
        operationName: operationName,
      );
    } on TimeoutException {
      return const GeminiVeoResult(
        success: false,
        error: 'Veo не завершил генерацию вовремя.',
      );
    } on SocketException {
      return const GeminiVeoResult(
        success: false,
        error: 'Нет соединения с Gemini API.',
      );
    } on FormatException {
      return const GeminiVeoResult(
        success: false,
        error: 'Gemini API вернул некорректный ответ.',
      );
    } catch (_) {
      return const GeminiVeoResult(
        success: false,
        error: 'Не удалось выполнить генерацию Veo.',
      );
    } finally {
      client.close(force: true);
    }
  }

  String _baseUrl(String configured) {
    var value = configured.trim();
    if (value.isEmpty || value.contains('gemini.google.com')) {
      value = 'https://generativelanguage.googleapis.com/v1beta';
    }
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  Future<Map<String, Object?>> _waitForOperation(
    HttpClient client,
    String base,
    String apiKey,
    String operationName,
  ) async {
    final deadline = DateTime.now().add(const Duration(minutes: 12));
    while (DateTime.now().isBefore(deadline)) {
      final response = await _getText(
        client,
        Uri.parse('$base/$operationName'),
        apiKey,
      );
      final decoded = _decodeMap(response.body);
      if (response.statusCode >= 400) {
        throw FormatException(
          decoded['error']?.toString() ?? 'Gemini operation failed',
        );
      }
      if (decoded['done'] == true) return decoded;
      await Future<void>.delayed(const Duration(seconds: 10));
    }
    throw TimeoutException('Veo operation timeout');
  }

  String? _videoUri(Map<String, Object?> operation) {
    final response = operation['response'];
    if (response is! Map) return null;
    final generated = response['generateVideoResponse'];
    if (generated is! Map) return null;
    final samples = generated['generatedSamples'];
    if (samples is! List || samples.isEmpty || samples.first is! Map) return null;
    final video = (samples.first as Map)['video'];
    return video is Map ? video['uri']?.toString() : null;
  }

  Future<_TextResponse> _postJson(
    HttpClient client,
    Uri uri,
    String apiKey,
    Map<String, Object?> body,
  ) async {
    final request = await client.postUrl(uri);
    request.headers
      ..set('x-goog-api-key', apiKey.trim())
      ..contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close().timeout(const Duration(seconds: 45));
    return _TextResponse(
      response.statusCode,
      await utf8.decoder.bind(response).join(),
    );
  }

  Future<_TextResponse> _getText(
    HttpClient client,
    Uri uri,
    String apiKey,
  ) async {
    final request = await client.getUrl(uri);
    request.headers.set('x-goog-api-key', apiKey.trim());
    final response = await request.close().timeout(const Duration(seconds: 30));
    return _TextResponse(
      response.statusCode,
      await utf8.decoder.bind(response).join(),
    );
  }

  Future<List<int>?> _getBytes(
    HttpClient client,
    Uri uri,
    String apiKey,
  ) async {
    final request = await client.getUrl(uri);
    request
      ..followRedirects = true
      ..headers.set('x-goog-api-key', apiKey.trim());
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
      'outputs${Platform.pathSeparator}video',
    );
    await directory.create(recursive: true);
    return directory;
  }

  String _apiError(int statusCode, Map<String, Object?> body) {
    final error = body['error'];
    final message = error is Map ? error['message']?.toString() : error?.toString();
    final prefix = switch (statusCode) {
      400 => 'Gemini отклонил параметры Veo.',
      401 || 403 => 'Gemini отклонил API key или доступ к Veo не включён.',
      429 => 'Gemini временно ограничил запросы или закончилась квота.',
      >= 500 => 'Gemini API временно недоступен.',
      _ => 'Gemini API вернул ошибку $statusCode.',
    };
    return message == null || message.trim().isEmpty ? prefix : '$prefix $message';
  }
}

class _TextResponse {
  const _TextResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
