enum GenerationProviderType { api, browser, local, externalLink }

enum GenerationCapability {
  textToImage,
  imageToImage,
  textToVideo,
  imageToVideo,
  videoToVideo,
}

extension GenerationProviderTypeLabel on GenerationProviderType {
  String get label {
    return switch (this) {
      GenerationProviderType.api => 'API',
      GenerationProviderType.browser => 'Браузер',
      GenerationProviderType.local => 'Локально',
      GenerationProviderType.externalLink => 'Внешняя ссылка',
    };
  }

  String get workflowLabel {
    return switch (this) {
      GenerationProviderType.api => 'API / Mock',
      GenerationProviderType.browser => 'Браузер',
      GenerationProviderType.local => 'Локально',
      GenerationProviderType.externalLink => 'Внешняя ссылка',
    };
  }

  String get description {
    return switch (this) {
      GenerationProviderType.api =>
        'STUDIO запускает mock/API-генерацию и показывает результат в холсте.',
      GenerationProviderType.browser =>
        'STUDIO готовит промпт и параметры, затем открывает браузерный сервис.',
      GenerationProviderType.local =>
        'STUDIO отправит задачу в локальный runtime, когда он будет подключен.',
      GenerationProviderType.externalLink =>
        'STUDIO сохраняет промпт и настройки, а результат возвращается вручную.',
    };
  }
}

extension GenerationCapabilityLabel on GenerationCapability {
  String get label {
    return switch (this) {
      GenerationCapability.textToImage => 'Текст в изображение',
      GenerationCapability.imageToImage => 'Изображение в изображение',
      GenerationCapability.textToVideo => 'Текст в видео',
      GenerationCapability.imageToVideo => 'Изображение в видео',
      GenerationCapability.videoToVideo => 'Видео в видео',
    };
  }
}

class GenerationProvider {
  const GenerationProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.capabilities,
    required this.description,
    required this.statusLabel,
    this.requiresApiKey = false,
    this.launchUrl,
    this.localEndpoint,
  });

  final String id;
  final String name;
  final GenerationProviderType type;
  final List<GenerationCapability> capabilities;
  final String description;
  final String statusLabel;
  final bool requiresApiKey;
  final String? launchUrl;
  final String? localEndpoint;

  bool supports(GenerationCapability capability) {
    return capabilities.contains(capability);
  }
}
