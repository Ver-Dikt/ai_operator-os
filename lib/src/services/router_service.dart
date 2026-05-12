import '../models/routing_recommendation.dart';

class RouterService {
  const RouterService();

  RoutingRecommendation recommend(String task) {
    final q = task.toLowerCase();
    if (q.contains('video') ||
        q.contains('cinematic') ||
        q.contains('short') ||
        q.contains('видео') ||
        q.contains('рилс') ||
        q.contains('reels') ||
        q.contains('клип') ||
        q.contains('локализ') ||
        q.contains('озвуч')) {
      return const RoutingRecommendation(
        task: 'Кинематографичное короткое видео',
        bestPaidTools: ['Veo', 'Runway', 'Sora'],
        bestFreeTools: ['Kling', 'Pika', 'Kensa'],
        localOptions: ['ComfyUI', 'Stable Diffusion video workflows'],
        recommendedWorkflow: 'Фабрика коротких AI-видео',
        estimatedCost: 'Бесплатный тестовый путь, Pro-качество через кредиты',
        workflowId: 'ai-short-video-factory',
        agentIds: [
          'director-agent',
          'content-factory-agent',
          'tool-router-agent',
        ],
        toolIds: ['kling', 'pika', 'veo', 'runway', 'canva'],
        useCaseIds: ['make-10-reels-for-track', 'build-ai-influencer'],
        freePath: [
          'Тестовые кредиты Kling/Pika',
          'Бесплатная сборка в Canva',
          'Ручной монтаж',
        ],
        proPath: [
          'Финальный проход через Veo или Runway',
          'Озвучка ElevenLabs',
          'Платные субтитры или монтаж',
        ],
        manualSteps: [
          'утвердить сцены',
          'выбрать лучшие дубли',
          'финальная проверка человеком',
        ],
        automationPotential:
            'Полуавтоматизация: промпты и чеклист сейчас, генерация позже',
        monetizationIdea:
            'Потенциал для контента или клиентской услуги. Сначала проверь спрос аудитории или клиента.',
        notes: [
          'Начни с режиссерского AI-помощника перед генерацией.',
          'Используй стабильные кадры и финальный жест для управления вниманием.',
        ],
      );
    }
    if (q.contains('music') ||
        q.contains('song') ||
        q.contains('track') ||
        q.contains('музык') ||
        q.contains('трек') ||
        q.contains('релиз')) {
      return const RoutingRecommendation(
        task: 'Промо музыки или релиза',
        bestPaidTools: ['Suno Pro', 'Udio paid', 'ElevenLabs'],
        bestFreeTools: ['BandLab', 'Suno free tests', 'Udio free tests'],
        localOptions: ['Локальная DAW + open audio tools'],
        recommendedWorkflow: 'Промо-пак музыкального релиза',
        estimatedCost:
            'План бесплатно, платная генерация только для финального качества',
        workflowId: 'music-release-promo-pack',
        agentIds: [
          'music-promo-agent',
          'content-factory-agent',
          'director-agent',
        ],
        toolIds: ['suno', 'udio', 'bandlab', 'kling', 'canva'],
        useCaseIds: ['make-10-reels-for-track'],
        freePath: ['BandLab', 'Canva Free', 'Бесплатные тесты Kling/Pika'],
        proPath: ['Платные генерации Suno/Udio', 'Финальный проход в Runway'],
        manualSteps: [
          'выбрать хуки',
          'утвердить визуал',
          'поставить посты в календарь',
        ],
        automationPotential: 'Помощь в пакетном планировании',
        monetizationIdea:
            'Потенциальный промо-пак для артиста. Нужны качество трека и проверка аудитории.',
        notes: [
          'Сначала преврати настроение в визуальную систему, потом делай клипы.',
        ],
      );
    }
    if (q.contains('code') ||
        q.contains('flutter') ||
        q.contains('app') ||
        q.contains('код') ||
        q.contains('прилож') ||
        q.contains('автомат')) {
      return const RoutingRecommendation(
        task: 'Код, приложение или автоматизация',
        bestPaidTools: ['Cursor', 'GitHub Copilot'],
        bestFreeTools: ['ChatGPT free', 'Replit free tier'],
        localOptions: ['Ollama + local coding model'],
        recommendedWorkflow: 'Планировщик Flutter-фичи',
        estimatedCost:
            'Планирование бесплатно, платный IDE-помощник опционально',
        workflowId: 'ai-tool-finder',
        agentIds: [
          'code-builder-agent',
          'qa-critic-agent',
          'tool-router-agent',
        ],
        toolIds: ['cursor', 'copilot', 'windsurf', 'ollama'],
        useCaseIds: ['build-n8n-workflow'],
        freePath: ['План в Ollama', 'Ручная реализация Flutter'],
        proPath: ['Ускорение через Cursor/Copilot'],
        manualSteps: ['проверить код', 'запустить тесты', 'проверить UX'],
        automationPotential: 'Помощь в кодинге, ревью человеком обязательно',
        monetizationIdea:
            'Потенциал SaaS или клиентской разработки только после валидации задачи.',
        notes: [
          'Используй AI-помощника разработки и добавь тесты до UI-полировки.',
        ],
      );
    }
    return const RoutingRecommendation(
      task: 'Общая AI-задача',
      bestPaidTools: ['ChatGPT', 'Claude', 'Perplexity Pro'],
      bestFreeTools: ['ChatGPT Free', 'Gemini', 'NotebookLM'],
      localOptions: ['Ollama', 'LM Studio', 'Open WebUI'],
      recommendedWorkflow: 'Подбор AI-инструментов',
      estimatedCost:
          'Начни бесплатно, платный апгрейд только после понятного узкого места',
      workflowId: 'ai-tool-finder',
      agentIds: ['tool-router-agent', 'research-agent', 'free-stack-agent'],
      toolIds: ['chatgpt', 'perplexity', 'notebooklm', 'ollama'],
      useCaseIds: ['competitor-analysis', 'build-n8n-workflow'],
      freePath: ['ChatGPT/Gemini free', 'NotebookLM', 'Ollama local'],
      proPath: ['ChatGPT Plus/Pro', 'Claude', 'Perplexity Pro'],
      manualSteps: [
        'уточнить ограничения',
        'сравнить альтернативы',
        'принять решение человеком',
      ],
      automationPotential: 'Помощь в планировании',
      monetizationIdea:
          'Только потенциальная возможность. Проверь проблему, покупателя и путь доставки.',
      notes: ['Маршрутизируй по типу результата, бюджету и приватности.'],
    );
  }
}
