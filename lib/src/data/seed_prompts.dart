import '../models/prompt_template.dart';

const seedPrompts = <PromptTemplate>[
  PromptTemplate(
    id: 'cinematic-video-scene',
    title: 'Cinematic Video Scene',
    category: 'Видео',
    style: 'сдержанный кинематографичный стиль',
    descriptionRu:
        'Промпт для кинематографичной сцены. Лучше работает на английском в Kling/Veo/Runway.',
    whenToUseRu:
        'Используй для Reels, Shorts, cinematic scene и image-to-video подготовки.',
    ruExplanation:
        'Сцена, камера, свет, движение, глубина кадра и финальный жест.',
    languageMode: PromptLanguageMode.ruEn,
    variables: [
      'idea',
      'location',
      'emotion',
      'camera_reason',
      'final_gesture',
    ],
    recommendedTools: ['veo', 'kling', 'runway', 'google-flow'],
    notes: 'Сначала блокинг и управление вниманием, потом движение камеры.',
    template:
        'Create a cinematic scene about {{idea}} in {{location}}. Emotional turn: {{emotion}}. Camera moves only because {{camera_reason}}. Use depth, blocking and stable composition. End on {{final_gesture}}. Negative prompt: random motion, overcutting, glossy stock look, incoherent hands.',
  ),
  PromptTemplate(
    id: 'tool-router',
    title: 'Tool Router Brief',
    category: 'AI-помощники',
    style: 'матрица решений',
    descriptionRu:
        'Промпт помогает подобрать инструменты под задачу: платные, бесплатные, локальные и быстрые варианты.',
    whenToUseRu:
        'Используй перед стартом задачи, когда непонятно, какую нейросеть открыть первой.',
    ruExplanation:
        'Задача, бюджет, платформа, уровень качества, риски и порядок работы.',
    languageMode: PromptLanguageMode.ruEn,
    variables: ['task', 'budget', 'platform', 'quality_target'],
    recommendedTools: ['chatgpt', 'perplexity', 'ollama'],
    notes: 'Хороший стартовый запрос для выбора рабочего стека.',
    template:
        'Task: {{task}}\nBudget: {{budget}}\nPlatform: {{platform}}\nQuality target: {{quality_target}}\nReturn: best paid option, best free option, local option, fastest option, risks, and workflow order.',
  ),
  PromptTemplate(
    id: 'music-promo',
    title: 'Music Promo Pack',
    category: 'Маркетинг',
    style: 'кампания релиза',
    descriptionRu:
        'Промпт собирает промо-пак для музыкального релиза: хуки, визуал, клипы, постинг.',
    whenToUseRu:
        'Используй для трека, альбома, teaser-контента и коротких видео.',
    ruExplanation:
        'Настроение трека, жанр, аудитория, дата релиза, визуальная идея и календарь.',
    languageMode: PromptLanguageMode.ruEn,
    variables: ['song_mood', 'genre', 'audience', 'release_date'],
    recommendedTools: ['suno', 'udio', 'canva', 'kling'],
    notes: 'Для релизных кампаний и коротких teaser-роликов.',
    template:
        'Build a music promo pack for a {{genre}} track. Mood: {{song_mood}}. Audience: {{audience}}. Release date: {{release_date}}. Create teaser hooks, visual identity, lyric clip ideas, cover art prompts, video prompts, and a posting calendar.',
  ),
  PromptTemplate(
    id: 'flutter-feature-builder',
    title: 'Flutter Feature Builder',
    category: 'Код',
    style: 'инженерный план',
    descriptionRu:
        'Промпт превращает фичу в понятный план реализации, тестов и рисков.',
    whenToUseRu: 'Используй перед разработкой новой функции или UX-патча.',
    ruExplanation:
        'Фича, ограничения, файлы, шаги реализации, состояние, UI, тесты и риски.',
    languageMode: PromptLanguageMode.ruEn,
    variables: ['feature', 'constraints', 'files'],
    recommendedTools: ['cursor', 'copilot', 'windsurf'],
    notes: 'Используй перед реализацией крупных изменений.',
    template:
        'Feature: {{feature}}\nConstraints: {{constraints}}\nRelevant files: {{files}}\nReturn implementation steps, state changes, UI components, tests, and risk checklist.',
  ),
  PromptTemplate(
    id: 'research-comparison',
    title: 'Research Comparison Matrix',
    category: 'Исследование',
    style: 'сравнение',
    descriptionRu:
        'Промпт собирает компактную матрицу сравнения сервисов, подходов или вариантов.',
    whenToUseRu:
        'Используй, когда нужно выбрать инструмент, сервис или стратегию.',
    ruExplanation:
        'Тема, критерии, срок, матрица, рекомендация, дешёвая альтернатива и проверка.',
    languageMode: PromptLanguageMode.ruEn,
    variables: ['topic', 'criteria', 'deadline'],
    recommendedTools: ['perplexity', 'elicit', 'notebooklm'],
    notes: 'Для выбора между сервисами или техническими вариантами.',
    template:
        'Compare options for {{topic}} using criteria {{criteria}}. Deadline: {{deadline}}. Return a compact matrix, recommended choice, cheap alternative, risks, and verification steps.',
  ),
];
