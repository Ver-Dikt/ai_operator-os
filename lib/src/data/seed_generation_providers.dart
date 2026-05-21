import '../models/generation/generation_provider.dart';

const seedGenerationProviders = <GenerationProvider>[
  GenerationProvider(
    id: 'mock-api-cinema',
    name: 'Cinematic API Mock',
    type: GenerationProviderType.api,
    capabilities: [
      GenerationCapability.textToImage,
      GenerationCapability.imageToImage,
      GenerationCapability.textToVideo,
      GenerationCapability.imageToVideo,
    ],
    description:
        'API-маршрут для проверки workflow Image/Video Studio до подключения реальных провайдеров.',
    statusLabel: 'Mock API · без внешнего запроса',
    requiresApiKey: true,
  ),
  GenerationProvider(
    id: 'browser-higgsfield',
    name: 'Higgsfield через браузер',
    type: GenerationProviderType.browser,
    capabilities: [
      GenerationCapability.textToVideo,
      GenerationCapability.imageToVideo,
    ],
    description:
        'Браузерный маршрут: подготовленный промпт копируется во внешнюю студию генерации.',
    statusLabel: 'Готов к ручному запуску',
    launchUrl: 'https://higgsfield.ai/',
  ),
  GenerationProvider(
    id: 'browser-midjourney',
    name: 'Midjourney / Discord',
    type: GenerationProviderType.browser,
    capabilities: [
      GenerationCapability.textToImage,
      GenerationCapability.imageToImage,
    ],
    description:
        'Браузерный маршрут для image workflow: STUDIO готовит промпт, пользователь переносит его во внешний интерфейс.',
    statusLabel: 'Браузерная генерация вручную',
    launchUrl: 'https://www.midjourney.com/',
  ),
  GenerationProvider(
    id: 'local-comfyui',
    name: 'ComfyUI Local',
    type: GenerationProviderType.local,
    capabilities: [
      GenerationCapability.textToImage,
      GenerationCapability.imageToImage,
      GenerationCapability.textToVideo,
    ],
    description:
        'Локальный node-runtime для будущей интеграции ComfyUI или локального inference.',
    statusLabel: 'Локальный runtime не подключен',
    localEndpoint: 'http://127.0.0.1:8188',
  ),
  GenerationProvider(
    id: 'external-runway',
    name: 'Runway External',
    type: GenerationProviderType.externalLink,
    capabilities: [
      GenerationCapability.textToVideo,
      GenerationCapability.imageToVideo,
      GenerationCapability.videoToVideo,
    ],
    description:
        'Внешняя ссылка для видео-инструментов, где подготовленный промпт остается под контролем оператора.',
    statusLabel: 'Внешняя рабочая область',
    launchUrl: 'https://app.runwayml.com/',
  ),
  GenerationProvider(
    id: 'external-leonardo',
    name: 'Leonardo External',
    type: GenerationProviderType.externalLink,
    capabilities: [
      GenerationCapability.textToImage,
      GenerationCapability.imageToImage,
    ],
    description:
        'Внешний image-сервис: промпт и настройки остаются в STUDIO, результат добавляется вручную.',
    statusLabel: 'Внешняя ссылка',
    launchUrl: 'https://app.leonardo.ai/',
  ),
];
