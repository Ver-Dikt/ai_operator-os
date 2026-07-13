import 'dart:async';
import 'dart:convert';
import 'dart:io';

class OpenAiImageResult {
  const OpenAiImageResult({
    required this.success,
    this.localPaths = const [],
    this.error,
  });

  final bool success;
  final List<String> localPaths;
  final String? error;
}

class OpenAiImageService {
  const OpenAiImageService();

  Future<OpenAiImageResult> generate({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    required String size,
    required String quality,
    required int count,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const OpenAiImageResult(
        success: false,
        error: 'Добавьте API-ключ OpenAI в настройках.',
      );
    }
    if (prompt.trim().isEmpty) {
      return const OpenAiImageResult(
        success: false,
        error: 'Сначала напишите prompt.',
      );
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final endpoint = _imagesEndpoint(baseUrl);
      final request = await client.postUrl(endpoint);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer ${apiKey.trim()}')
        ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);
      request.write(
        jsonEncode({
          'model': model.trim().isEmpty ? 'gpt-image-2' : model.trim(),
          'prompt': prompt.trim(),
          'size': size,
          'quality': quality,
          'output_format': 'png',
          'n': count.clamp(1, 4),
        }),
      );

      final response = await request.close().timeout(const Duration(minutes: 5));
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return OpenAiImageResult(
          success: false,
          error: _apiError(response.statusCode, body),
        );
      }

      final decoded = jsonDecode(body);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! List || data.isEmpty) {
        return const OpenAiImageResult(
          success: false,
          error: 'OpenAI вернул ответ без изображения.',
        );
      }

      final outputDirectory = await _outputDirectory();
      final paths = <String>[];
      for (var index = 0; index < data.length; index++) {
        final item = data[index];
        if (item is! Map) continue;
        final encoded = item['b64_json'];
        if (encoded is! String || encoded.isEmpty) continue;
        final suffix = data.length > 1 ? '-${index + 1}' : '';
        final file = File(
          '${outputDirectory.path}${Platform.pathSeparator}'
          'openai-${DateTime.now().microsecondsSinceEpoch}$suffix.png',
        );
        await file.writeAsBytes(base64Decode(encoded), flush: true);
        paths.add(file.path);
      }
      if (paths.isEmpty) {
        return const OpenAiImageResult(
          success: false,
          error: 'OpenAI не вернул данные изображения в ожидаемом формате.',
        );
      }
      return OpenAiImageResult(success: true, localPaths: paths);
    } on TimeoutException {
      return const OpenAiImageResult(
        success: false,
        error: 'OpenAI не ответил вовремя. Повторите попытку.',
      );
    } on SocketException {
      return const OpenAiImageResult(
        success: false,
        error: 'Нет соединения с OpenAI. Проверьте интернет и Base URL.',
      );
    } on FormatException {
      return const OpenAiImageResult(
        success: false,
        error: 'OpenAI вернул повреждённый ответ.',
      );
    } catch (_) {
      return const OpenAiImageResult(
        success: false,
        error: 'Не удалось создать или сохранить изображение.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Uri _imagesEndpoint(String baseUrl) {
    var normalized = baseUrl.trim();
    if (normalized.isEmpty) normalized = 'https://api.openai.com/v1';
    normalized = normalized.replaceFirst(RegExp(r'/+$'), '');
    if (normalized.endsWith('/images/generations')) {
      return Uri.parse(normalized);
    }
    return Uri.parse('$normalized/images/generations');
  }

  Future<Directory> _outputDirectory() async {
    final appData = Platform.environment['APPDATA']?.trim();
    final root = appData != null && appData.isNotEmpty
        ? appData
        : '${Directory.current.path}${Platform.pathSeparator}.dart_appdata';
    final directory = Directory(
      '$root${Platform.pathSeparator}FLUTEN${Platform.pathSeparator}'
      'outputs${Platform.pathSeparator}images',
    );
    await directory.create(recursive: true);
    return directory;
  }

  String _apiError(int statusCode, String body) {
    String? message;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final value = (decoded['error'] as Map)['message'];
        if (value is String && value.trim().isNotEmpty) message = value.trim();
      }
    } catch (_) {
      // Use the safe status-based fallback below.
    }
    final prefix = switch (statusCode) {
      401 || 403 => 'OpenAI отклонил API-ключ.',
      429 => 'OpenAI временно ограничил запросы или закончился баланс.',
      >= 500 => 'Сервис OpenAI временно недоступен.',
      _ => 'OpenAI вернул ошибку $statusCode.',
    };
    if (message == null) return prefix;
    final safe = message.replaceAll(RegExp(r'sk-[A-Za-z0-9_-]+'), '[скрыто]');
    return '$prefix $safe';
  }
}
