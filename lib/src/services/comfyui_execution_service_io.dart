import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class ComfyUiExecutionResult {
  const ComfyUiExecutionResult({
    required this.success,
    this.localPaths = const [],
    this.promptId,
    this.error,
  });

  final bool success;
  final List<String> localPaths;
  final String? promptId;
  final String? error;
}

class ComfyUiExecutionService {
  const ComfyUiExecutionService();

  Future<ComfyUiExecutionResult> generate({
    required String endpoint,
    required String workflowPath,
    required String outputFolder,
    required String prompt,
    required String negativePrompt,
    required int width,
    required int height,
  }) async {
    if (prompt.trim().isEmpty) {
      return const ComfyUiExecutionResult(
        success: false,
        error: 'Сначала напишите prompt.',
      );
    }
    final workflowFile = File(workflowPath.trim());
    if (workflowPath.trim().isEmpty || !await workflowFile.exists()) {
      return const ComfyUiExecutionResult(
        success: false,
        error: 'Не найден API-workflow ComfyUI. Укажите JSON-файл в настройках.',
      );
    }

    final base = endpoint.trim().replaceFirst(RegExp(r'/+$'), '');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final decoded = jsonDecode(await workflowFile.readAsString());
      if (decoded is! Map) {
        return const ComfyUiExecutionResult(
          success: false,
          error: 'Workflow должен быть JSON-объектом в формате API ComfyUI.',
        );
      }
      final rawWorkflow = decoded['prompt'] is Map ? decoded['prompt'] : decoded;
      final seed = Random.secure().nextInt(2147483647);
      final workflow = _replaceTokens(
        rawWorkflow,
        prompt: prompt.trim(),
        negativePrompt: negativePrompt.trim(),
        width: width,
        height: height,
        seed: seed,
      );
      final clientId = 'fluten-${DateTime.now().microsecondsSinceEpoch}';
      final submit = await _postJson(
        client,
        Uri.parse('$base/prompt'),
        {'prompt': workflow, 'client_id': clientId},
      );
      if (submit.statusCode < 200 || submit.statusCode >= 300) {
        return ComfyUiExecutionResult(
          success: false,
          error: _submitError(submit.statusCode, submit.body),
        );
      }
      final submitJson = jsonDecode(submit.body);
      final promptId = submitJson is Map ? submitJson['prompt_id'] : null;
      if (promptId is! String || promptId.isEmpty) {
        return const ComfyUiExecutionResult(
          success: false,
          error: 'ComfyUI приняла запрос, но не вернула prompt_id.',
        );
      }

      final images = await _waitForImages(client, base, promptId);
      if (images.isEmpty) {
        return ComfyUiExecutionResult(
          success: false,
          promptId: promptId,
          error: 'ComfyUI не вернула изображения до истечения времени ожидания.',
        );
      }
      final directory = await _outputDirectory(outputFolder);
      final paths = <String>[];
      for (var index = 0; index < images.length; index++) {
        final image = images[index];
        final filename = image['filename'];
        if (filename is! String || filename.isEmpty) continue;
        final uri = Uri.parse('$base/view').replace(
          queryParameters: {
            'filename': filename,
            'subfolder': image['subfolder']?.toString() ?? '',
            'type': image['type']?.toString() ?? 'output',
          },
        );
        final bytes = await _getBytes(client, uri);
        if (bytes == null) continue;
        final safeName = filename.split(RegExp(r'[/\\]')).last;
        final uniqueName = images.length > 1
            ? '${promptId}_${index + 1}_$safeName'
            : '${promptId}_$safeName';
        final file = File(
          '${directory.path}${Platform.pathSeparator}$uniqueName',
        );
        await file.writeAsBytes(bytes, flush: true);
        paths.add(file.path);
      }
      if (paths.isEmpty) {
        return ComfyUiExecutionResult(
          success: false,
          promptId: promptId,
          error: 'ComfyUI завершила workflow, но файлы результата не загрузились.',
        );
      }
      return ComfyUiExecutionResult(
        success: true,
        localPaths: paths,
        promptId: promptId,
      );
    } on TimeoutException {
      return const ComfyUiExecutionResult(
        success: false,
        error: 'ComfyUI не ответила вовремя.',
      );
    } on SocketException {
      return const ComfyUiExecutionResult(
        success: false,
        error: 'Нет соединения с ComfyUI. Проверьте локальный endpoint.',
      );
    } on FormatException {
      return const ComfyUiExecutionResult(
        success: false,
        error: 'Workflow или ответ ComfyUI содержит некорректный JSON.',
      );
    } catch (_) {
      return const ComfyUiExecutionResult(
        success: false,
        error: 'Не удалось выполнить workflow ComfyUI.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Object? _replaceTokens(
    Object? value, {
    required String prompt,
    required String negativePrompt,
    required int width,
    required int height,
    required int seed,
  }) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          _replaceTokens(
            item,
            prompt: prompt,
            negativePrompt: negativePrompt,
            width: width,
            height: height,
            seed: seed,
          ),
        ),
      );
    }
    if (value is List) {
      return value
          .map(
            (item) => _replaceTokens(
              item,
              prompt: prompt,
              negativePrompt: negativePrompt,
              width: width,
              height: height,
              seed: seed,
            ),
          )
          .toList();
    }
    if (value == '{{width}}') return width;
    if (value == '{{height}}') return height;
    if (value == '{{seed}}') return seed;
    if (value is String) {
      return value
          .replaceAll('{{prompt}}', prompt)
          .replaceAll('{{negative_prompt}}', negativePrompt)
          .replaceAll('{{width}}', '$width')
          .replaceAll('{{height}}', '$height')
          .replaceAll('{{seed}}', '$seed');
    }
    return value;
  }

  Future<List<Map<String, Object?>>> _waitForImages(
    HttpClient client,
    String base,
    String promptId,
  ) async {
    final deadline = DateTime.now().add(const Duration(minutes: 10));
    while (DateTime.now().isBefore(deadline)) {
      final response = await _getText(
        client,
        Uri.parse('$base/history/$promptId'),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded[promptId] is Map) {
          final entry = decoded[promptId] as Map;
          final status = entry['status'];
          if (status is Map && status['status_str'] == 'error') {
            throw const FormatException('ComfyUI workflow failed');
          }
          final outputs = entry['outputs'];
          final images = <Map<String, Object?>>[];
          if (outputs is Map) {
            for (final output in outputs.values) {
              if (output is! Map || output['images'] is! List) continue;
              for (final image in output['images'] as List) {
                if (image is Map) images.add(image.cast<String, Object?>());
              }
            }
          }
          if (images.isNotEmpty) return images;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    }
    return const [];
  }

  Future<Directory> _outputDirectory(String configured) async {
    if (configured.trim().isNotEmpty) {
      final directory = Directory(configured.trim());
      await directory.create(recursive: true);
      return directory;
    }
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

  Future<_TextResponse> _getText(HttpClient client, Uri uri) async {
    final request = await client.getUrl(uri);
    final response = await request.close().timeout(const Duration(seconds: 20));
    return _TextResponse(
      response.statusCode,
      await utf8.decoder.bind(response).join(),
    );
  }

  Future<List<int>?> _getBytes(HttpClient client, Uri uri) async {
    final request = await client.getUrl(uri);
    final response = await request.close().timeout(const Duration(minutes: 2));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    return response.fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
  }

  String _submitError(int statusCode, String body) {
    String? nodeErrors;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        nodeErrors = (decoded['error'] as Map)['message']?.toString();
      }
    } catch (_) {
      nodeErrors = null;
    }
    return nodeErrors == null || nodeErrors.trim().isEmpty
        ? 'ComfyUI отклонила workflow (HTTP $statusCode). Проверьте формат API JSON.'
        : 'ComfyUI отклонила workflow: $nodeErrors';
  }
}

class _TextResponse {
  const _TextResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
