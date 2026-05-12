import '../models/route_plan.dart';
import '../models/routing_recommendation.dart';

class RouterService {
  const RouterService();

  RoutePlan buildRoutePlan(String task) {
    final q = task.toLowerCase();
    if (_hasAny(q, const [
      'reels',
      'shorts',
      'cinematic',
      'trailer',
      'video',
      'видео',
      'рилс',
      'шорт',
      'клип',
      'трейлер',
      'сцена',
    ])) {
      return _videoRoute(task);
    }
    if (_hasAny(q, const [
      'music',
      'song',
      'track',
      'promo',
      'трек',
      'музык',
      'релиз',
      'промо',
    ])) {
      return _musicRoute(task);
    }
    if (_hasAny(q, const [
      'logo',
      'poster',
      'thumbnail',
      'cover',
      'облож',
      'постер',
      'лого',
      'превью',
      'баннер',
    ])) {
      return _imageRoute(task);
    }
    if (_hasAny(q, const [
      'outreach',
      'freelance',
      'proposal',
      'client',
      'конкур',
      'клиент',
      'фриланс',
      'оффер',
      'продаж',
    ])) {
      return _businessRoute(task);
    }
    if (_hasAny(q, const [
      'automation',
      'n8n',
      'zapier',
      'make',
      'автомат',
      'воркфлоу',
      'workflow',
    ])) {
      return _automationRoute(task);
    }
    if (_hasAny(q, const ['local', 'ollama', 'comfyui', 'локаль', 'gpu'])) {
      return _localRoute(task);
    }
    return _generalRoute(task);
  }

  RoutingRecommendation recommend(String task) {
    final plan = buildRoutePlan(task);
    final freeOption = plan.executionOptions
        .where((option) => option.badges.contains('FREE'))
        .expand((option) => option.items)
        .toList();
    final qualityOption = plan.executionOptions
        .where((option) => option.badges.contains('PREMIUM'))
        .expand((option) => option.items)
        .toList();
    final localOption = plan.executionOptions
        .where((option) => option.badges.contains('LOCAL'))
        .expand((option) => option.items)
        .toList();

    return RoutingRecommendation(
      task: plan.title,
      bestPaidTools: qualityOption.isEmpty
          ? plan.tools.take(3).toList()
          : qualityOption,
      bestFreeTools: freeOption.isEmpty
          ? plan.tools.take(3).toList()
          : freeOption,
      localOptions: localOption.isEmpty ? ['Ollama', 'ComfyUI'] : localOption,
      recommendedWorkflow: plan.workflows.isEmpty
          ? 'Подбор AI-инструментов'
          : plan.workflows.first,
      estimatedCost: plan.estimatedCost,
      notes: plan.promptSuggestions.take(2).toList(),
      workflowId: plan.workflowIds.isEmpty ? null : plan.workflowIds.first,
      agentIds: plan.agentIds,
      toolIds: plan.toolIds,
      freePath: freeOption,
      proPath: qualityOption,
      manualSteps: plan.steps.map((step) => step.title).toList(),
      automationPotential: plan.recommendedMode,
      monetizationIdea: plan.detectedGoal,
    );
  }

  static bool _hasAny(String q, List<String> keywords) {
    return keywords.any(q.contains);
  }

  RoutePlan _videoRoute(String task) {
    return RoutePlan(
      title: 'AI Route Plan: Shorts / cinematic video',
      detectedGoal:
          'Обнаружена задача: создание AI Shorts или кинематографичного видео',
      recommendedMode: 'Видео-режим',
      routeType: 'Video production route',
      workflows: const ['Фабрика коротких AI-видео', 'Кинематографичная сцена'],
      workflowIds: const ['ai-short-video-factory', 'cinematic-scene-builder'],
      tools: const [
        'ChatGPT',
        'Kling',
        'Veo',
        'Runway',
        'Canva',
        'ElevenLabs',
        'ComfyUI',
      ],
      toolIds: const [
        'chatgpt',
        'kling',
        'veo',
        'runway',
        'canva',
        'elevenlabs',
        'comfyui',
      ],
      agents: const [
        'Режиссерский AI-помощник',
        'AI-помощник по промптам',
        'AI-помощник фабрики контента',
      ],
      agentIds: const [
        'director-agent',
        'prompt-engineer-agent',
        'content-factory-agent',
      ],
      promptSuggestions: _promptPack(task, const [
        'Hook scene',
        'Cinematic opener',
        'Storyboard sequence',
        'Music sync prompt',
        'TikTok CTA',
      ]),
      steps: const [
        RouteStep(
          title: 'Сценарий',
          explanation: 'Сжать идею в хук, конфликт и финальный жест.',
          badges: ['MANUAL', 'FREE'],
          state: RouteExecutionState.manualStep,
          iconKey: 'script',
        ),
        RouteStep(
          title: 'Storyboard',
          explanation: 'Разложить ролик на визуальные биты и кадры.',
          badges: ['MANUAL', 'FAST'],
          state: RouteExecutionState.ready,
          iconKey: 'storyboard',
        ),
        RouteStep(
          title: 'Генерация сцен',
          explanation: 'Создать image-to-video или Text-to-video варианты.',
          badges: ['API', 'PREMIUM'],
          state: RouteExecutionState.requiresApi,
          iconKey: 'video',
        ),
        RouteStep(
          title: 'Монтаж',
          explanation: 'Собрать лучшие дубли, ритм, подписи и CTA.',
          badges: ['MANUAL', 'FAST'],
          state: RouteExecutionState.manualStep,
          iconKey: 'edit',
        ),
        RouteStep(
          title: 'Озвучка',
          explanation: 'Добавить voiceover, музыку или дубляж.',
          badges: ['API', 'PREMIUM'],
          state: RouteExecutionState.requiresApi,
          iconKey: 'audio',
        ),
        RouteStep(
          title: 'Экспорт',
          explanation: 'Проверить финальный кадр, субтитры и формат 9:16.',
          badges: ['READY', 'MANUAL'],
          state: RouteExecutionState.ready,
          iconKey: 'export',
        ),
      ],
      executionOptions: const [
        RouteExecutionOption(
          title: 'Бесплатный маршрут',
          description:
              'Промпты и монтаж вручную, генерация через free credits.',
          badges: ['FREE', 'MANUAL', 'FAST'],
          items: ['ChatGPT Free', 'Kling free credits', 'Canva Free'],
        ),
        RouteExecutionOption(
          title: 'Лучшее качество',
          description:
              'Premium генерация и финальный проход в сильной видео-модели.',
          badges: ['PREMIUM', 'API'],
          items: ['Veo', 'Runway', 'ElevenLabs'],
        ),
        RouteExecutionOption(
          title: 'Локальный маршрут',
          description: 'Локальные черновики и контроль визуального пайплайна.',
          badges: ['LOCAL', 'GPU', 'COMFYUI'],
          items: ['ComfyUI', 'Stable Diffusion', 'Ollama'],
        ),
        RouteExecutionOption(
          title: 'Hybrid route',
          description:
              'Сценарий локально, генерация сцен в cloud, монтаж вручную.',
          badges: ['LOCAL', 'API', 'MANUAL'],
          items: ['Ollama', 'Kling', 'Runway', 'Canva'],
        ),
      ],
      estimatedComplexity: 'Средняя',
      estimatedCost: 'Можно начать бесплатно, качество растет через кредиты',
      localPossible: true,
      freePossible: true,
    );
  }

  RoutePlan _musicRoute(String task) {
    return RoutePlan(
      title: 'AI Route Plan: Music Promo',
      detectedGoal: 'Обнаружена задача: промо музыкального релиза',
      recommendedMode: 'Аудио / видео-промо',
      routeType: 'Music release route',
      workflows: const [
        'Промо-пак музыкального релиза',
        'Фабрика коротких AI-видео',
      ],
      workflowIds: const ['music-release-promo-pack', 'ai-short-video-factory'],
      tools: const ['ChatGPT', 'Suno', 'Udio', 'Kling', 'Canva', 'ElevenLabs'],
      toolIds: const [
        'chatgpt',
        'suno',
        'udio',
        'kling',
        'canva',
        'elevenlabs',
      ],
      agents: const [
        'AI-помощник музыкального промо',
        'AI-помощник фабрики контента',
        'Режиссерский AI-помощник',
      ],
      agentIds: const [
        'music-promo-agent',
        'content-factory-agent',
        'director-agent',
      ],
      promptSuggestions: _promptPack(task, const [
        'Release hook',
        'Lyric clip idea',
        'Music sync prompt',
        'Cover art prompt',
        'Posting calendar',
      ]),
      steps: const [
        RouteStep(
          title: 'Хуки релиза',
          explanation: 'Собрать 5 коротких заходов по настроению трека.',
          badges: ['MANUAL', 'FREE'],
          state: RouteExecutionState.ready,
          iconKey: 'script',
        ),
        RouteStep(
          title: 'Визуальная система',
          explanation: 'Определить цвета, объекты, темп и обложку.',
          badges: ['MANUAL'],
          state: RouteExecutionState.manualStep,
          iconKey: 'image',
        ),
        RouteStep(
          title: 'Клипы и lyric cuts',
          explanation: 'Разложить трек на короткие видео-сцены.',
          badges: ['FAST', 'MANUAL'],
          state: RouteExecutionState.ready,
          iconKey: 'video',
        ),
        RouteStep(
          title: 'Озвучка / музыка',
          explanation: 'Подготовить voiceover, stems или музыкальные варианты.',
          badges: ['API', 'PREMIUM'],
          state: RouteExecutionState.requiresApi,
          iconKey: 'audio',
        ),
        RouteStep(
          title: 'Публикация',
          explanation: 'Собрать календарь, captions и CTA.',
          badges: ['MANUAL', 'FREE'],
          state: RouteExecutionState.manualStep,
          iconKey: 'export',
        ),
      ],
      executionOptions: const [
        RouteExecutionOption(
          title: 'Бесплатный маршрут',
          description: 'План, монтаж и дизайн без оплаты.',
          badges: ['FREE', 'MANUAL'],
          items: ['ChatGPT Free', 'Canva Free', 'BandLab'],
        ),
        RouteExecutionOption(
          title: 'Быстрый маршрут',
          description: 'Сразу собрать тизеры и клипы через freemium tools.',
          badges: ['FAST', 'API'],
          items: ['Kling', 'Canva', 'Suno free tests'],
        ),
        RouteExecutionOption(
          title: 'Локальный маршрут',
          description: 'Черновики текста и анализа локально.',
          badges: ['LOCAL', 'OLLAMA'],
          items: ['Ollama', 'LM Studio'],
        ),
        RouteExecutionOption(
          title: 'Лучшее качество',
          description: 'Premium музыка, голос и видео-генерация.',
          badges: ['PREMIUM', 'API'],
          items: ['Suno Pro', 'Udio paid', 'Runway', 'ElevenLabs'],
        ),
      ],
      estimatedComplexity: 'Средняя',
      estimatedCost:
          'Бесплатный план, платные сервисы только для финального качества',
      localPossible: true,
      freePossible: true,
    );
  }

  RoutePlan _imageRoute(String task) {
    return RoutePlan(
      title: 'AI Route Plan: Image / Thumbnail Pack',
      detectedGoal: 'Обнаружена задача: визуальный пакет, постер или thumbnail',
      recommendedMode: 'Дизайн-режим',
      routeType: 'Image production route',
      workflows: const ['Подбор AI-инструментов', 'Кинематографичная сцена'],
      workflowIds: const ['ai-tool-finder', 'cinematic-scene-builder'],
      tools: const [
        'Midjourney',
        'ChatGPT Images',
        'Leonardo AI',
        'Canva',
        'ComfyUI',
      ],
      toolIds: const [
        'midjourney',
        'chatgpt-images',
        'leonardo',
        'canva',
        'comfyui',
      ],
      agents: const [
        'AI-помощник по промптам',
        'AI-помощник QA',
        'AI-помощник по выбору инструментов',
      ],
      agentIds: const [
        'prompt-engineer-agent',
        'qa-critic-agent',
        'tool-router-agent',
      ],
      promptSuggestions: _promptPack(task, const [
        'Thumbnail concept',
        'Poster composition',
        'Style lock',
        'Negative prompt',
        'Variant grid',
      ]),
      steps: const [
        RouteStep(
          title: 'Creative brief',
          explanation: 'Определить формат, объект, аудиторию и ограничение.',
          badges: ['MANUAL', 'FREE'],
          state: RouteExecutionState.manualStep,
          iconKey: 'script',
        ),
        RouteStep(
          title: 'Визуальные варианты',
          explanation: 'Собрать 6-12 направлений без смены цели.',
          badges: ['FAST', 'API'],
          state: RouteExecutionState.ready,
          iconKey: 'image',
        ),
        RouteStep(
          title: 'Финальный промпт',
          explanation:
              'Зафиксировать стиль, свет, композицию и negative prompt.',
          badges: ['MANUAL'],
          state: RouteExecutionState.manualStep,
          iconKey: 'prompt',
        ),
        RouteStep(
          title: 'Дизайн-сборка',
          explanation: 'Доработать типографику, safe zones и экспорт.',
          badges: ['MANUAL', 'FREE'],
          state: RouteExecutionState.ready,
          iconKey: 'export',
        ),
      ],
      executionOptions: const [
        RouteExecutionOption(
          title: 'Бесплатный маршрут',
          description: 'Быстрые черновики и дизайн без оплаты.',
          badges: ['FREE', 'MANUAL'],
          items: ['Canva Free', 'Leonardo AI free', 'ChatGPT Free'],
        ),
        RouteExecutionOption(
          title: 'Лучшее качество',
          description: 'Сильная image model + ручной art direction.',
          badges: ['PREMIUM', 'API'],
          items: ['Midjourney', 'ChatGPT Images'],
        ),
        RouteExecutionOption(
          title: 'Локальный маршрут',
          description: 'Контроль через локальный граф и GPU.',
          badges: ['LOCAL', 'GPU', 'COMFYUI'],
          items: ['ComfyUI', 'Stable Diffusion'],
        ),
        RouteExecutionOption(
          title: 'Hybrid route',
          description: 'Идеи в ChatGPT, финал в Midjourney/Canva.',
          badges: ['API', 'MANUAL'],
          items: ['ChatGPT', 'Midjourney', 'Canva'],
        ),
      ],
      estimatedComplexity: 'Низкая / средняя',
      estimatedCost: 'Можно начать бесплатно',
      localPossible: true,
      freePossible: true,
    );
  }

  RoutePlan _businessRoute(String task) {
    return RoutePlan(
      title: 'AI Route Plan: Freelance / Outreach',
      detectedGoal:
          'Обнаружена задача: клиентский оффер, outreach или бизнес-анализ',
      recommendedMode: 'Исследование + продажи',
      routeType: 'Business route',
      workflows: const ['Подбор AI-инструментов'],
      workflowIds: const ['ai-tool-finder'],
      tools: const ['Perplexity', 'ChatGPT', 'Claude', 'NotebookLM', 'Canva'],
      toolIds: const ['perplexity', 'chatgpt', 'claude', 'notebooklm', 'canva'],
      agents: const [
        'AI-помощник исследования',
        'AI-помощник QA',
        'AI-помощник по выбору инструментов',
      ],
      agentIds: const [
        'research-agent',
        'qa-critic-agent',
        'tool-router-agent',
      ],
      promptSuggestions: _promptPack(task, const [
        'Client niche scan',
        'Offer matrix',
        'Outreach message',
        'Proposal outline',
        'Risk checklist',
      ]),
      steps: const [
        RouteStep(
          title: 'Исследование ниши',
          explanation: 'Найти спрос, боль и существующие платежи.',
          badges: ['MANUAL', 'FREE'],
          state: RouteExecutionState.manualStep,
          iconKey: 'research',
        ),
        RouteStep(
          title: 'Оффер',
          explanation: 'Сформулировать результат, сроки и границы услуги.',
          badges: ['MANUAL'],
          state: RouteExecutionState.ready,
          iconKey: 'script',
        ),
        RouteStep(
          title: 'Outreach',
          explanation: 'Подготовить короткие сообщения и follow-up.',
          badges: ['FAST', 'MANUAL'],
          state: RouteExecutionState.ready,
          iconKey: 'send',
        ),
        RouteStep(
          title: 'QA предложения',
          explanation: 'Проверить обещания, риски и доказательства.',
          badges: ['MANUAL'],
          state: RouteExecutionState.manualStep,
          iconKey: 'qa',
        ),
      ],
      executionOptions: const [
        RouteExecutionOption(
          title: 'Бесплатный маршрут',
          description: 'Исследование и офферы вручную.',
          badges: ['FREE', 'MANUAL'],
          items: ['ChatGPT Free', 'Perplexity free', 'NotebookLM'],
        ),
        RouteExecutionOption(
          title: 'Быстрый маршрут',
          description: 'Сразу собрать оффер и 10 сообщений.',
          badges: ['FAST', 'API'],
          items: ['ChatGPT', 'Claude'],
        ),
        RouteExecutionOption(
          title: 'Локальный маршрут',
          description: 'Приватные черновики и анализ без cloud.',
          badges: ['LOCAL', 'OLLAMA'],
          items: ['Ollama', 'LM Studio'],
        ),
        RouteExecutionOption(
          title: 'Лучшее качество',
          description: 'Глубокое исследование и полировка pitch deck.',
          badges: ['PREMIUM', 'API'],
          items: ['Perplexity Pro', 'Claude', 'Canva'],
        ),
      ],
      estimatedComplexity: 'Средняя',
      estimatedCost: 'Можно начать бесплатно',
      localPossible: true,
      freePossible: true,
    );
  }

  RoutePlan _automationRoute(String task) {
    return RoutePlan(
      title: 'AI Route Plan: Automation',
      detectedGoal: 'Обнаружена задача: AI-автоматизация или workflow',
      recommendedMode: 'Автоматизация',
      routeType: 'Automation design route',
      workflows: const ['Настройка Local AI', 'Подбор AI-инструментов'],
      workflowIds: const ['local-ai-setup', 'ai-tool-finder'],
      tools: const [
        'n8n',
        'Make',
        'Zapier',
        'Flowise',
        'OpenAI Agents SDK',
        'Ollama',
      ],
      toolIds: const [
        'n8n',
        'make',
        'zapier',
        'flowise',
        'openai-agents-sdk',
        'ollama',
      ],
      agents: const [
        'AI-помощник автоматизации',
        'AI-помощник QA',
        'AI-помощник разработки',
      ],
      agentIds: const [
        'automation-architect-agent',
        'qa-critic-agent',
        'code-builder-agent',
      ],
      promptSuggestions: _promptPack(task, const [
        'Trigger map',
        'Action chain',
        'Human review gate',
        'Failure handling',
        'n8n node plan',
      ]),
      steps: const [
        RouteStep(
          title: 'Trigger',
          explanation: 'Определить событие запуска и входные данные.',
          badges: ['MANUAL'],
          state: RouteExecutionState.manualStep,
          iconKey: 'automation',
        ),
        RouteStep(
          title: 'Actions',
          explanation: 'Разложить процесс на узлы и передачи данных.',
          badges: ['MANUAL', 'API'],
          state: RouteExecutionState.ready,
          iconKey: 'nodes',
        ),
        RouteStep(
          title: 'Human check',
          explanation: 'Поставить ручной контроль там, где высок риск.',
          badges: ['MANUAL'],
          state: RouteExecutionState.manualStep,
          iconKey: 'qa',
        ),
        RouteStep(
          title: 'Runtime later',
          explanation: 'Реальное исполнение появится после API/backend слоя.',
          badges: ['COMING LATER', 'API'],
          state: RouteExecutionState.comingLater,
          iconKey: 'api',
        ),
      ],
      executionOptions: const [
        RouteExecutionOption(
          title: 'Бесплатный маршрут',
          description: 'Схема и ручной запуск без backend.',
          badges: ['FREE', 'MANUAL'],
          items: ['n8n self-host', 'Ollama'],
        ),
        RouteExecutionOption(
          title: 'Быстрый маршрут',
          description: 'No-code сборка через cloud коннекторы.',
          badges: ['FAST', 'API'],
          items: ['Make', 'Zapier'],
        ),
        RouteExecutionOption(
          title: 'Локальный маршрут',
          description: 'Self-hosted automations и локальная LLM.',
          badges: ['LOCAL', 'OLLAMA'],
          items: ['n8n', 'Ollama', 'Flowise'],
        ),
        RouteExecutionOption(
          title: 'Hybrid route',
          description: 'Локальные шаги плюс API там, где нужен cloud.',
          badges: ['LOCAL', 'API', 'MANUAL'],
          items: ['n8n', 'OpenAI Agents SDK', 'Ollama'],
        ),
      ],
      estimatedComplexity: 'Высокая',
      estimatedCost: 'Зависит от API-коннекторов',
      localPossible: true,
      freePossible: true,
    );
  }

  RoutePlan _localRoute(String task) {
    return RoutePlan(
      title: 'AI Route Plan: Local AI Setup',
      detectedGoal: 'Обнаружена задача: локальный AI-стек',
      recommendedMode: 'Local',
      routeType: 'Local route',
      workflows: const ['Настройка Local AI'],
      workflowIds: const ['local-ai-setup'],
      tools: const ['Ollama', 'ComfyUI', 'LM Studio', 'Open WebUI', 'Docker'],
      toolIds: const ['ollama', 'comfyui', 'lm-studio', 'open-webui', 'docker'],
      agents: const [
        'AI-помощник по выбору инструментов',
        'AI-помощник разработки',
        'AI-помощник QA',
      ],
      agentIds: const [
        'tool-router-agent',
        'code-builder-agent',
        'qa-critic-agent',
      ],
      promptSuggestions: _promptPack(task, const [
        'Model selection',
        'GPU checklist',
        'Local workflow',
        'Privacy plan',
        'Fallback route',
      ]),
      steps: const [
        RouteStep(
          title: 'Проверка железа',
          explanation: 'Оценить RAM, GPU и формат моделей.',
          badges: ['LOCAL', 'GPU'],
          state: RouteExecutionState.localAvailable,
          iconKey: 'local',
        ),
        RouteStep(
          title: 'Ollama',
          explanation: 'Поднять локальный LLM endpoint.',
          badges: ['LOCAL', 'OLLAMA'],
          state: RouteExecutionState.localAvailable,
          iconKey: 'local',
        ),
        RouteStep(
          title: 'ComfyUI',
          explanation: 'Собрать локальный image/video граф.',
          badges: ['LOCAL', 'COMFYUI', 'GPU'],
          state: RouteExecutionState.localAvailable,
          iconKey: 'image',
        ),
        RouteStep(
          title: 'Hybrid fallback',
          explanation: 'Оставить cloud-инструменты для тяжелых задач.',
          badges: ['API', 'MANUAL'],
          state: RouteExecutionState.ready,
          iconKey: 'api',
        ),
      ],
      executionOptions: const [
        RouteExecutionOption(
          title: 'Бесплатный маршрут',
          description: 'Все базовые шаги локально.',
          badges: ['FREE', 'LOCAL'],
          items: ['Ollama', 'ComfyUI', 'Open WebUI'],
        ),
        RouteExecutionOption(
          title: 'Локальный маршрут',
          description: 'Основной режим без cloud.',
          badges: ['LOCAL', 'GPU', 'OLLAMA'],
          items: ['Ollama', 'LM Studio', 'Docker'],
        ),
        RouteExecutionOption(
          title: 'Hybrid route',
          description: 'Локально для приватности, cloud для качества.',
          badges: ['LOCAL', 'API'],
          items: ['Ollama', 'Veo', 'Runway'],
        ),
        RouteExecutionOption(
          title: 'Лучшее качество',
          description: 'Премиум cloud только для финального прохода.',
          badges: ['PREMIUM', 'API'],
          items: ['Veo', 'Runway'],
        ),
      ],
      estimatedComplexity: 'Средняя / высокая',
      estimatedCost: 'Бесплатно локально, но зависит от железа',
      localPossible: true,
      freePossible: true,
    );
  }

  RoutePlan _generalRoute(String task) {
    return RoutePlan(
      title: 'AI Route Plan: General Task',
      detectedGoal: 'Обнаружена общая AI-задача: нужен подбор маршрута',
      recommendedMode: 'Toolkit',
      routeType: 'General routing route',
      workflows: const ['Подбор AI-инструментов'],
      workflowIds: const ['ai-tool-finder'],
      tools: const ['ChatGPT', 'Claude', 'Perplexity', 'NotebookLM', 'Ollama'],
      toolIds: const [
        'chatgpt',
        'claude',
        'perplexity',
        'notebooklm',
        'ollama',
      ],
      agents: const [
        'AI-помощник по выбору инструментов',
        'AI-помощник исследования',
        'AI-помощник QA',
      ],
      agentIds: const [
        'tool-router-agent',
        'research-agent',
        'qa-critic-agent',
      ],
      promptSuggestions: _promptPack(task, const [
        'Task brief',
        'Tool comparison',
        'Risk checklist',
        'Execution order',
        'Output spec',
      ]),
      steps: const [
        RouteStep(
          title: 'Уточнить цель',
          explanation: 'Сформулировать результат, формат и ограничения.',
          badges: ['MANUAL', 'FREE'],
          state: RouteExecutionState.manualStep,
          iconKey: 'script',
        ),
        RouteStep(
          title: 'Подобрать стек',
          explanation: 'Сравнить free/pro/local/API варианты.',
          badges: ['READY'],
          state: RouteExecutionState.ready,
          iconKey: 'route',
        ),
        RouteStep(
          title: 'Собрать промпт',
          explanation: 'Подготовить рабочий prompt и критерии результата.',
          badges: ['MANUAL'],
          state: RouteExecutionState.ready,
          iconKey: 'prompt',
        ),
        RouteStep(
          title: 'Проверка',
          explanation: 'Оценить качество, риски и следующий шаг.',
          badges: ['MANUAL'],
          state: RouteExecutionState.manualStep,
          iconKey: 'qa',
        ),
      ],
      executionOptions: const [
        RouteExecutionOption(
          title: 'Бесплатный маршрут',
          description: 'Начать с free tools и ручной проверки.',
          badges: ['FREE', 'MANUAL'],
          items: ['ChatGPT Free', 'NotebookLM', 'Ollama'],
        ),
        RouteExecutionOption(
          title: 'Быстрый маршрут',
          description: 'Cloud LLM и готовый порядок работы.',
          badges: ['FAST', 'API'],
          items: ['ChatGPT', 'Claude'],
        ),
        RouteExecutionOption(
          title: 'Локальный маршрут',
          description: 'Приватный черновик и анализ локально.',
          badges: ['LOCAL', 'OLLAMA'],
          items: ['Ollama', 'LM Studio'],
        ),
        RouteExecutionOption(
          title: 'Лучшее качество',
          description: 'Сильные модели плюс research-проверка.',
          badges: ['PREMIUM', 'API'],
          items: ['ChatGPT Plus/Pro', 'Claude', 'Perplexity Pro'],
        ),
      ],
      estimatedComplexity: 'Низкая / средняя',
      estimatedCost: 'Можно начать бесплатно',
      localPossible: true,
      freePossible: true,
    );
  }

  static List<String> _promptPack(String task, List<String> labels) {
    final cleanTask = task.trim().isEmpty ? '{{task}}' : task.trim();
    return [
      for (final label in labels)
        '$label: подготовь промпт для задачи "$cleanTask" с переменными {{goal}}, {{format}}, {{constraints}}.',
    ];
  }
}
