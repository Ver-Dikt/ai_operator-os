import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ElevenLabsTtsResult {
  const ElevenLabsTtsResult({required this.success, this.localPath, this.error});

  final bool success;
  final String? localPath;
  final String? error;
}

class ElevenLabsTtsService {
  const ElevenLabsTtsService();

  Future<ElevenLabsTtsResult> generate({
    required String baseUrl,
    required String apiKey,
    required String voiceId,
    required String text,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const ElevenLabsTtsResult(
        success: false,
        error: 'Добавьте API-ключ ElevenLabs в настройках.',
      );
    }
    if (voiceId.trim().isEmpty) {
      return const ElevenLabsTtsResult(
        success: false,
        error: 'Укажите Voice ID ElevenLabs в поле модели.',
      );
    }
    if (text.trim().isEmpty) {
      return const ElevenLabsTtsResult(
        success: false,
        error: 'Добавьте текст для озвучивания.',
      );
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final uri = _endpoint(baseUrl, voiceId).replace(
        queryParameters: const {'output_format': 'mp3_44100_128'},
      );
      final request = await client.postUrl(uri);
      request.headers
        ..set('xi-api-key', apiKey.trim())
        ..contentType = ContentType.json;
      request.write(
        jsonEncode({
          'text': text.trim(),
          'model_id': 'eleven_multilingual_v2',
        }),
      );
      final response = await request.close().timeout(const Duration(minutes: 5));
      final bytes = await response.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ElevenLabsTtsResult(
          success: false,
          error: _apiError(response.statusCode, utf8.decode(bytes, allowMalformed: true)),
        );
      }
      if (bytes.isEmpty) {
        return const ElevenLabsTtsResult(
          success: false,
          error: 'ElevenLabs вернул пустой аудиофайл.',
        );
      }
      final directory = await _outputDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}'
        'elevenlabs-${DateTime.now().microsecondsSinceEpoch}.mp3',
      );
      await file.writeAsBytes(bytes, flush: true);
      return ElevenLabsTtsResult(success: true, localPath: file.path);
    } on TimeoutException {
      return const ElevenLabsTtsResult(
        success: false,
        error: 'ElevenLabs не ответил вовремя.',
      );
    } on SocketException {
      return const ElevenLabsTtsResult(
        success: false,
        error: 'Нет соединения с ElevenLabs. Проверьте интернет и Base URL.',
      );
    } catch (_) {
      return const ElevenLabsTtsResult(
        success: false,
        error: 'Не удалось создать или сохранить озвучку.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Uri _endpoint(String baseUrl, String voiceId) {
    var base = baseUrl.trim();
    if (base.isEmpty) base = 'https://api.elevenlabs.io';
    base = base.replaceFirst(RegExp(r'/+$'), '');
    if (!base.endsWith('/v1')) base = '$base/v1';
    return Uri.parse('$base/text-to-speech/${Uri.encodeComponent(voiceId.trim())}');
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

  String _apiError(int statusCode, String body) {
    String? message;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        message = detail is Map ? detail['message']?.toString() : detail.toString();
      }
    } catch (_) {
      message = null;
    }
    final prefix = switch (statusCode) {
      401 || 403 => 'ElevenLabs отклонил API-ключ.',
      422 => 'ElevenLabs отклонил Voice ID или текст.',
      429 => 'ElevenLabs временно ограничил запросы или закончилась квота.',
      >= 500 => 'ElevenLabs временно недоступен.',
      _ => 'ElevenLabs вернул ошибку $statusCode.',
    };
    return message == null || message!.trim().isEmpty
        ? prefix
        : '$prefix ${message!.trim()}';
  }
}
