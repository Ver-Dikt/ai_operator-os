import '../models/workflow_template.dart';

WorkflowStep _step(
  String id,
  String title,
  String instruction, {
  String? agentId,
  List<String> tools = const [],
  String prompt = '',
  bool manual = true,
  bool auto = false,
}) {
  return WorkflowStep(
    id: id,
    title: title,
    instruction: instruction,
    agentId: agentId,
    toolIds: tools,
    promptTemplate: prompt.isEmpty
        ? 'Task: {{task}}\nConstraints: {{constraints}}\nOutput: $title'
        : prompt,
    expectedOutput: 'Готовый результат этапа: $title',
    isManual: manual,
    isAutomatable: auto,
  );
}

final seedWorkflows = <WorkflowTemplate>[
  WorkflowTemplate(
    id: 'ai-short-video-factory',
    title: 'Фабрика коротких AI-видео',
    description:
        'От идеи к хуку, сценарию, сценам, video prompts, выбору инструментов, плану монтажа и подписям.',
    category: 'Видео',
    difficulty: WorkflowDifficulty.medium,
    estimatedTime: '45-90 min',
    costLevel: CostLevel.mixed,
    requiredTools: ['chatgpt', 'kling', 'canva'],
    optionalTools: ['veo', 'runway', 'elevenlabs', 'suno'],
    outputExamples: ['9 промптов сцен', 'пак подписей', 'чеклист публикации'],
    steps: [
      _step(
        'idea',
        'Идея',
        'Сожми идею до одного эмоционального обещания.',
        agentId: 'content-factory-agent',
      ),
      _step(
        'hook',
        'Хук',
        'Напиши три хука для первой секунды и выбери самое сильное ограничение.',
      ),
      _step(
        'script',
        'Сценарий',
        'Напиши компактный сценарий с ясным поворотом.',
      ),
      _step(
        'scenes',
        'Сцены',
        'Разбей сценарий на визуальные биты.',
        agentId: 'director-agent',
      ),
      _step(
        'video-prompts',
        'Video prompts',
        'Подготовь кадры-промпты с блокингом и причиной движения камеры.',
        tools: ['kling', 'veo'],
      ),
      _step(
        'tool-selection',
        'Выбор инструментов',
        'Выбери бесплатный, быстрый и качественный маршруты инструментов.',
        agentId: 'tool-router-agent',
      ),
      _step(
        'generation',
        'Чеклист генерации',
        'Отследи сгенерированные кадры и варианты.',
      ),
      _step('edit', 'План монтажа', 'Определи ритм, подписи и финальный жест.'),
      _step(
        'publish',
        'Подписи для публикации',
        'Напиши подписи и хэштеги для релиза.',
      ),
    ],
  ),
  WorkflowTemplate(
    id: 'music-release-promo-pack',
    title: 'Промо-пак музыкального релиза',
    description:
        'Превращает настроение трека в идеи тизеров, промпты обложки, lyric clips и календарь публикаций.',
    category: 'Музыка',
    difficulty: WorkflowDifficulty.easy,
    estimatedTime: '60 min',
    costLevel: CostLevel.low,
    requiredTools: ['chatgpt', 'canva', 'kling'],
    optionalTools: ['suno', 'udio', 'bandlab'],
    outputExamples: [
      '7 идей тизеров',
      'промпты обложки',
      'календарь на 14 дней',
    ],
    steps: [
      _step(
        'song-mood',
        'Настроение трека',
        'Опиши эмоциональный мир трека.',
        agentId: 'music-promo-agent',
      ),
      _step(
        'identity',
        'Визуальная айдентика',
        'Определи цвета, объекты, темп и фактуру.',
      ),
      _step('teasers', 'Идеи тизеров', 'Сгенерируй концепты коротких роликов.'),
      _step('lyrics', 'Lyric clips', 'Выбери строки и визуальную подачу.'),
      _step(
        'cover',
        'Промпты обложки',
        'Создай варианты промптов для cover art.',
      ),
      _step(
        'video',
        'Промпты коротких видео',
        'Создай video prompts для промо-клипов.',
      ),
      _step('calendar', 'Календарь публикаций', 'Собери ритм релизных постов.'),
    ],
  ),
  WorkflowTemplate(
    id: 'ai-tool-finder',
    title: 'Подбор AI-инструментов',
    description:
        'Превращает задачу и ограничения в стек бесплатных, платных и локальных инструментов.',
    category: 'Исследование',
    difficulty: WorkflowDifficulty.easy,
    estimatedTime: '15 min',
    costLevel: CostLevel.free,
    requiredTools: ['perplexity', 'chatgpt'],
    optionalTools: ['ollama', 'notebooklm'],
    outputExamples: [
      'лучший платный вариант',
      'бесплатный путь',
      'локальный запасной вариант',
    ],
    steps: [
      _step(
        'task',
        'Задача пользователя',
        'Сформулируй конкретную работу, которую нужно выполнить.',
      ),
      _step(
        'constraints',
        'Ограничения',
        'Добавь бюджет, платформу и ограничения по времени.',
      ),
      _step(
        'split',
        'Разделение free / paid / Local',
        'Раздели бесплатные, платные и локальные варианты.',
        agentId: 'free-stack-agent',
      ),
      _step(
        'best-tools',
        'Лучшие инструменты',
        'Выбери инструменты по соответствию задаче и надежности.',
        agentId: 'tool-router-agent',
      ),
      _step(
        'workflow',
        'Рекомендованный план работы',
        'Преврати результат в последовательность действий.',
      ),
    ],
  ),
  WorkflowTemplate(
    id: 'cinematic-scene-builder',
    title: 'Кинематографичная сцена',
    description:
        'Собирает сцену с драматическим битом, блокингом, причиной движения камеры и финальным жестом.',
    category: 'Видео',
    difficulty: WorkflowDifficulty.advanced,
    estimatedTime: '30-60 min',
    costLevel: CostLevel.mixed,
    requiredTools: ['chatgpt', 'veo'],
    optionalTools: ['midjourney', 'runway', 'comfyui'],
    outputExamples: [
      'режиссерские заметки',
      'пак video prompts',
      'negative prompts',
    ],
    steps: [
      _step('beat', 'Драматический бит', 'Назови эмоциональный поворот.'),
      _step(
        'location',
        'Локация',
        'Выбери пространство, которое создает напряжение.',
      ),
      _step(
        'blocking',
        'Блокинг',
        'Расставь персонажей до движения камеры.',
        agentId: 'director-agent',
      ),
      _step(
        'camera',
        'Причина движения камеры',
        'Двигай камеру только по драматической причине.',
      ),
      _step(
        'stable',
        'Стабильный кадр',
        'Используй стабильность как выразительный прием.',
      ),
      _step(
        'gesture',
        'Финальный жест',
        'Определи жест, который переосмысливает сцену.',
      ),
      _step(
        'prompt-pack',
        'Пак промптов',
        'Напиши финальные prompts и negative prompts.',
      ),
    ],
  ),
  WorkflowTemplate(
    id: 'local-ai-setup',
    title: 'Настройка Local AI',
    description:
        'Подготовь локальный стек вокруг Ollama, выбора моделей и локальной базы знаний.',
    category: 'Local',
    difficulty: WorkflowDifficulty.medium,
    estimatedTime: '45 min',
    costLevel: CostLevel.free,
    requiredTools: ['ollama', 'lm-studio'],
    optionalTools: ['open-webui', 'anythingllm', 'n8n'],
    outputExamples: [
      'список моделей',
      'настройка локального чата',
      'заметки по автоматизации',
    ],
    steps: [
      _step('ollama', 'Ollama', 'Установи и проверь локальный endpoint.'),
      _step('models', 'Выбор моделей', 'Подбери модели по RAM и задаче.'),
      _step('chat', 'Local Chat', 'Открой локальный чат-интерфейс.'),
      _step(
        'knowledge',
        'Локальная база знаний',
        'Спланируй загрузку документов.',
      ),
      _step(
        'automation',
        'Локальная автоматизация',
        'Подключи локальные сервисы позже.',
      ),
    ],
  ),
];
