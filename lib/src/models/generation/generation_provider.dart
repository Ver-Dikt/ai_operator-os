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
      GenerationProviderType.api => 'Через API',
      GenerationProviderType.browser => 'Через сайт',
      GenerationProviderType.local => 'Локально',
      GenerationProviderType.externalLink => 'Вручную',
    };
  }

  String get workflowLabel {
    return switch (this) {
      GenerationProviderType.api => 'Через API',
      GenerationProviderType.browser => 'Через сайт',
      GenerationProviderType.local => 'Локальная генерация',
      GenerationProviderType.externalLink => 'Ручной режим',
    };
  }

  String get description {
    return switch (this) {
      GenerationProviderType.api =>
        'Маршрут через API. Если ключ не подключен, FLUTEN только показывает честный статус.',
      GenerationProviderType.browser =>
        'Откройте сайт провайдера и вставьте подготовленный prompt вручную.',
      GenerationProviderType.local =>
        'Локальный runtime используется только после подключения локальной модели.',
      GenerationProviderType.externalLink =>
        'Ручной режим: prompt остается в FLUTEN, результат добавляется вручную.',
    };
  }
}

extension GenerationCapabilityLabel on GenerationCapability {
  String get label {
    return switch (this) {
      GenerationCapability.textToImage => 'Text to Image',
      GenerationCapability.imageToImage => 'Image to Image',
      GenerationCapability.textToVideo => 'Text to Video',
      GenerationCapability.imageToVideo => 'Image to Video',
      GenerationCapability.videoToVideo => 'Video to Video',
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
