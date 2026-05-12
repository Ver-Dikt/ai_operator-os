import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai_operator_app.dart';
import '../data/seed_free_credits.dart';
import '../models/ai_agent.dart';
import '../models/ai_tool.dart';
import '../models/monetization.dart';
import '../models/routing_recommendation.dart';
import '../models/use_case.dart';
import '../models/workflow_template.dart';
import '../services/graph_repository.dart';
import '../services/router_service.dart';
import '../services/url_service.dart';
import '../state/app_settings.dart';

enum _WorkMode { agents, text, design, video, audio, toolkit }

enum _ActiveViewType {
  empty,
  routePlan,
  workflow,
  agent,
  tool,
  useCase,
  session,
  project,
}

T? _firstOrNull<T>(List<T> items) => items.isEmpty ? null : items.first;

class _ActiveStateSnapshot {
  const _ActiveStateSnapshot({
    required this.viewType,
    this.workflowId,
    this.agentId,
    this.toolId,
    this.useCaseId,
    this.summaryTitle,
    this.summarySubtitle,
  });

  final _ActiveViewType viewType;
  final String? workflowId;
  final String? agentId;
  final String? toolId;
  final String? useCaseId;
  final String? summaryTitle;
  final String? summarySubtitle;
}

Future<void> _copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Скопировано в буфер')));
}

class _ModeSettingConfig {
  const _ModeSettingConfig(this.title, this.values);

  final String title;
  final List<String> values;
}

class _WorkModeConfig {
  const _WorkModeConfig({
    required this.label,
    required this.icon,
    required this.title,
    required this.description,
    required this.promptPlaceholder,
    required this.modelTitle,
    required this.modelHelper,
    required this.models,
    required this.settings,
    required this.quickActions,
    required this.recommendedToolIds,
    required this.emptyStateHints,
    this.showModelSelector = true,
  });

  final String label;
  final IconData icon;
  final String title;
  final String description;
  final String promptPlaceholder;
  final String modelTitle;
  final String modelHelper;
  final List<String> models;
  final List<_ModeSettingConfig> settings;
  final List<({String label, String task})> quickActions;
  final List<String> recommendedToolIds;
  final List<String> emptyStateHints;
  final bool showModelSelector;
}

extension _WorkModeUi on _WorkMode {
  _WorkModeConfig get config {
    return switch (this) {
      _WorkMode.agents => const _WorkModeConfig(
        label: 'AI-помощники',
        icon: Icons.smart_toy_outlined,
        title: 'Команда агентов',
        description:
            'Поставь задачу - OS подберет агентов, роли и ручные/автоматические шаги.',
        promptPlaceholder: 'Опиши задачу для команды агентов...',
        modelTitle: 'AI-помощник',
        modelHelper: 'Кто ведет задачу и распределяет роли.',
        models: [
          'Авто-агент',
          'Агент-маршрутизатор',
          'Агент-режиссер',
          'Агент фриланса',
          'Агент локализации',
          'Агент автоматизации',
        ],
        settings: [
          _ModeSettingConfig('Режим', [
            'Черновик',
            'Под контролем',
            'Авто позже',
          ]),
          _ModeSettingConfig('Память', [
            'Без памяти',
            'Проектная',
            'Локальная позже',
          ]),
          _ModeSettingConfig('Подтверждения', [
            'Включены',
            'Только важные',
            'Скоро авто',
          ]),
        ],
        quickActions: [
          (
            label: 'Подобрать агентов',
            task: 'Подобрать агентов под мою задачу',
          ),
          (label: 'Назначить задачу', task: 'Разбить задачу между агентами'),
          (
            label: 'Проверить результат',
            task: 'Проверить результат через QA Agent',
          ),
        ],
        recommendedToolIds: ['openai-agents-sdk', 'langgraph', 'crewai'],
        emptyStateHints: ['агенты', 'роли', 'ручные шаги'],
      ),
      _WorkMode.text => const _WorkModeConfig(
        label: 'Текст',
        icon: Icons.notes_rounded,
        title: 'Текстовый оператор',
        description: 'Идеи, статьи, анализ, код, research, промпты.',
        promptPlaceholder:
            'Что написать, объяснить, проанализировать или улучшить?',
        modelTitle: 'Текстовая модель',
        modelHelper: 'Основная модель для текста, анализа и промптов.',
        models: ['ChatGPT', 'Claude', 'Gemini', 'Mistral', 'Ollama Local'],
        settings: [
          _ModeSettingConfig('Тип задачи', [
            'Идея',
            'Текст',
            'Анализ',
            'Код',
            'Research',
          ]),
          _ModeSettingConfig('Длина', ['Коротко', 'Средне', 'Подробно']),
          _ModeSettingConfig('Стиль', [
            'Просто',
            'Профессионально',
            'Продающе',
            'Технически',
          ]),
        ],
        quickActions: [
          (label: 'Research-бриф', task: 'Собрать research brief по теме'),
          (label: 'Посты', task: 'Написать серию постов для соцсетей'),
          (label: 'Промпт', task: 'Улучшить промпт под конкретную модель'),
        ],
        recommendedToolIds: [
          'chatgpt',
          'claude',
          'gemini',
          'mistral-chat',
          'ollama',
        ],
        emptyStateHints: ['анализ', 'текст', 'промпт'],
      ),
      _WorkMode.design => const _WorkModeConfig(
        label: 'Изображения',
        icon: Icons.auto_awesome_mosaic_outlined,
        title: 'Студия изображений',
        description:
            'Генерация изображений, обложки, постеры, брендинг, AI-инфлюенсеры.',
        promptPlaceholder: 'Опиши изображение, стиль, постер или обложку...',
        modelTitle: 'Дизайн-модель',
        modelHelper:
            'Основной движок генерации изображений и визуального стиля.',
        models: [
          'Midjourney',
          'ChatGPT Images',
          'Nano Banana',
          'Gemini image tools',
          'Leonardo',
          'Ideogram',
          'PicLumen',
          'Freepik AI',
          'ComfyUI Local',
        ],
        settings: [
          _ModeSettingConfig('Формат', ['1:1', '4:5', '9:16', '16:9']),
          _ModeSettingConfig('Стиль', [
            'Cinematic',
            'Minimal',
            'Product',
            'Poster',
            'AI Influencer',
          ]),
          _ModeSettingConfig('Референсы', [
            'Стиль +',
            'Объект +',
            'Без референса',
          ]),
        ],
        quickActions: [
          (
            label: 'Постер',
            task: 'Сделать визуальный стиль и промпт для постера',
          ),
          (label: 'Обложка', task: 'Собрать prompt pack для обложки'),
          (label: 'Брендинг', task: 'Собрать AI brand moodboard'),
        ],
        recommendedToolIds: [
          'midjourney',
          'chatgpt-images',
          'nano-banana',
          'gemini-image-tools',
          'leonardo',
          'ideogram',
          'piclumen',
          'freepik-ai',
          'comfyui',
          'stable-diffusion',
        ],
        emptyStateHints: ['постер', 'обложка', 'референс'],
      ),
      _WorkMode.video => const _WorkModeConfig(
        label: 'Видео',
        icon: Icons.movie_creation_outlined,
        title: 'Видео-режиссер',
        description:
            'Сцены, shot plan, storyboard, camera motion, visual beats и cinematic prompts.',
        promptPlaceholder: 'Опиши сцену, ролик, Reels или видео-идею...',
        modelTitle: 'Видео-модель',
        modelHelper:
            'Основной движок генерации видео. ChatGPT здесь только помощник для промпта.',
        models: ['Kling', 'Veo / Flow', 'Runway', 'Pika', 'Luma', 'Sora'],
        settings: [
          _ModeSettingConfig('Формат', ['9:16', '16:9', '1:1']),
          _ModeSettingConfig('Длина', ['5 сек', '10 сек', '30 сек', '60 сек']),
          _ModeSettingConfig('Режим', [
            'Text-to-video',
            'Image-to-video',
            'Scene plan — план сцены',
            'Batch shorts — серия коротких видео',
          ]),
          _ModeSettingConfig('Качество', ['Черновик', 'Сбалансировано', 'Pro']),
        ],
        quickActions: [
          (label: 'AI Reels', task: 'Сделать 10 Reels для трека'),
          (label: 'Раскадровка', task: 'Собрать storyboard и shot plan'),
          (label: 'Трейлер', task: 'Собрать AI trailer plan'),
          (label: 'Сборка сцены', task: 'Собрать cinematic AI scene builder'),
          (label: 'Кино-кадр', task: 'Собрать cinematic shot с camera motion'),
          (
            label: 'Локализация',
            task: 'Локализовать видео: перевод, голос, субтитры',
          ),
        ],
        recommendedToolIds: [
          'kling',
          'runway',
          'pika',
          'veo',
          'google-flow',
          'luma',
          'sora',
        ],
        emptyStateHints: ['сцены', 'shot plan', 'camera motion'],
      ),
      _WorkMode.audio => const _WorkModeConfig(
        label: 'Аудио',
        icon: Icons.graphic_eq_rounded,
        title: 'Аудио-студия',
        description: 'Озвучка, музыка, голос, дубляж и транскрибация.',
        promptPlaceholder: 'Опиши голос, музыку, озвучку или аудио-задачу...',
        modelTitle: 'Аудио-модель',
        modelHelper:
            'Основной движок для голоса, музыки, дубляжа или транскрибации.',
        models: ['ElevenLabs', 'Suno', 'Udio', 'Stable Audio', 'Whisper'],
        settings: [
          _ModeSettingConfig('Тип', [
            'Озвучка',
            'Идея песни',
            'Промо музыки',
            'Дубляж',
            'Транскрибация',
          ]),
          _ModeSettingConfig('Голос', [
            'Авто',
            'Мужской',
            'Женский',
            'Кинематографичный',
          ]),
          _ModeSettingConfig('Длина', ['Коротко', 'Средне', 'Длинно']),
          _ModeSettingConfig('Язык', ['Auto', 'RU', 'EN']),
        ],
        quickActions: [
          (
            label: 'Озвучка',
            task: 'Подготовить voiceover и инструменты озвучки',
          ),
          (label: 'Промо музыки', task: 'Продвинуть музыкальный релиз'),
          (label: 'Дубляж', task: 'Собрать сценарий дубляжа видео'),
        ],
        recommendedToolIds: [
          'elevenlabs',
          'suno',
          'udio',
          'stable-audio',
          'whisper',
        ],
        emptyStateHints: ['voiceover', 'музыка', 'дубляж'],
      ),
      _WorkMode.toolkit => const _WorkModeConfig(
        label: 'База AI',
        icon: Icons.grid_view_rounded,
        title: 'База нейросетей',
        description:
            'Поиск нейросетей, сервисов и сравнение free/pro/local/API вариантов.',
        promptPlaceholder: 'Какую нейросеть или инструмент ищем?',
        modelTitle: 'Поиск инструментов',
        modelHelper: 'Фильтры и категории вместо выбора генеративной модели.',
        models: [],
        showModelSelector: false,
        settings: [
          _ModeSettingConfig('Категория', [
            'Все',
            'Бесплатные',
            'Видео',
            'Дизайн',
            'Аудио',
            'Код',
            'Автоматизация',
            'Локальные',
          ]),
          _ModeSettingConfig('Фильтры', [
            'Free',
            'Has API',
            'Local',
            'No card',
            'Лучшее качество',
          ]),
        ],
        quickActions: [
          (
            label: 'Бесплатный стек',
            task: 'Найти бесплатный AI stack под задачу',
          ),
          (
            label: 'Сравнить',
            task: 'Сравнить платные и бесплатные AI инструменты',
          ),
          (label: 'Local-вариант', task: 'Подобрать локальные AI инструменты'),
        ],
        recommendedToolIds: [
          'chatgpt',
          'kling',
          'nano-banana',
          'midjourney',
          'gemini-image-tools',
          'piclumen',
          'elevenlabs',
          'n8n',
          'ollama',
        ],
        emptyStateHints: ['поиск', 'сравнение', 'фильтры'],
      ),
    };
  }

  String get label => config.label;
  String get title => config.title;
  String get description => config.description;
  IconData get icon => config.icon;
  String get placeholder => config.promptPlaceholder;
  List<({String label, String task})> get quickActions => config.quickActions;
}

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key, required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  final TextEditingController _taskController = TextEditingController();
  _WorkMode _mode = _WorkMode.design;
  RoutingRecommendation? _recommendation;
  _ActiveViewType _activeViewType = _ActiveViewType.empty;
  String? _activeWorkflowId;
  String? _activeAgentId;
  String? _activeToolId;
  String? _activeUseCaseId;
  String? _activeSummaryTitle;
  String? _activeSummarySubtitle;
  final List<_ActiveStateSnapshot> _activeViewHistory = [];
  String _historyTab = 'Задачи';
  String _model = _WorkMode.design.config.models.first;
  String _aspect = '9:16';
  String _quality = 'Сбалансировано';

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.25,
            colors: [Color(0xFF171820), Color(0xFF050608)],
          ),
        ),
        child: SafeArea(
          child: isWide
              ? _DesktopStation(
                  mode: _mode,
                  historyTab: _historyTab,
                  taskController: _taskController,
                  recommendation: _recommendation,
                  activeViewType: _activeViewType,
                  activeWorkflowId: _activeWorkflowId,
                  activeAgentId: _activeAgentId,
                  activeToolId: _activeToolId,
                  activeUseCaseId: _activeUseCaseId,
                  activeSummaryTitle: _activeSummaryTitle,
                  activeSummarySubtitle: _activeSummarySubtitle,
                  model: _model,
                  aspect: _aspect,
                  quality: _quality,
                  settings: settings,
                  onMode: _switchMode,
                  onHistoryTab: (tab) => setState(() => _historyTab = tab),
                  onSubmit: _buildPlan,
                  onQuickGoal: _quickGoal,
                  onOpenWorkflow: _openWorkflow,
                  onOpenAgent: _openAgent,
                  onOpenTool: _openTool,
                  onOpenUseCase: _openUseCase,
                  onOpenSession: _openSessionSummary,
                  onOpenProject: _openProjectSummary,
                  onNewSession: _newSession,
                  onBack: _goBackInline,
                  onModel: (value) => setState(() => _model = value),
                  onAspect: (value) => setState(() => _aspect = value),
                  onQuality: (value) => setState(() => _quality = value),
                  onReset: _resetParameters,
                  onNavigate: widget.onNavigate,
                )
              : _MobileStation(
                  mode: _mode,
                  taskController: _taskController,
                  recommendation: _recommendation,
                  activeViewType: _activeViewType,
                  activeWorkflowId: _activeWorkflowId,
                  activeAgentId: _activeAgentId,
                  activeToolId: _activeToolId,
                  activeUseCaseId: _activeUseCaseId,
                  activeSummaryTitle: _activeSummaryTitle,
                  activeSummarySubtitle: _activeSummarySubtitle,
                  model: _model,
                  aspect: _aspect,
                  quality: _quality,
                  settings: settings,
                  onMode: _switchMode,
                  onSubmit: _buildPlan,
                  onQuickGoal: _quickGoal,
                  onOpenWorkflow: _openWorkflow,
                  onOpenAgent: _openAgent,
                  onOpenTool: _openTool,
                  onOpenUseCase: _openUseCase,
                  onBack: _goBackInline,
                  onModel: (value) => setState(() => _model = value),
                  onAspect: (value) => setState(() => _aspect = value),
                  onQuality: (value) => setState(() => _quality = value),
                  onReset: _resetParameters,
                ),
        ),
      ),
    );
  }

  void _quickGoal(String task) {
    _taskController.text = task;
    _buildPlan();
  }

  void _switchMode(_WorkMode mode) {
    setState(() {
      _mode = mode;
      _model = mode.config.models.isEmpty ? '' : mode.config.models.first;
      _activeViewType = _ActiveViewType.empty;
      _activeViewHistory.clear();
      _clearActiveIds();
    });
  }

  void _buildPlan() {
    final task = _taskController.text.trim().isEmpty
        ? 'Собрать AI-сценарий'
        : _taskController.text.trim();
    setState(() {
      _recommendation = const RouterService().recommend(task);
      _activeViewType = _ActiveViewType.routePlan;
      _activeViewHistory.clear();
      _clearActiveIds();
    });
  }

  void _openWorkflow(String? id) {
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.workflow;
      _clearActiveIds();
      _activeWorkflowId = id;
    });
  }

  void _openAgent(String? id) {
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.agent;
      _clearActiveIds();
      _activeAgentId = id;
    });
  }

  void _openTool(String? id) {
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.tool;
      _clearActiveIds();
      _activeToolId = id;
    });
  }

  void _openUseCase(String? id) {
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.useCase;
      _clearActiveIds();
      _activeUseCaseId = id;
    });
  }

  void _openSessionSummary(String title, String subtitle) {
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.session;
      _clearActiveIds();
      _activeSummaryTitle = title;
      _activeSummarySubtitle = subtitle;
    });
  }

  void _openProjectSummary(String title, String subtitle) {
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.project;
      _clearActiveIds();
      _activeSummaryTitle = title;
      _activeSummarySubtitle = subtitle;
    });
  }

  void _newSession() {
    setState(() {
      _taskController.clear();
      _recommendation = null;
      _activeViewType = _ActiveViewType.empty;
      _activeViewHistory.clear();
      _clearActiveIds();
    });
  }

  void _rememberActiveState() {
    if (_activeViewType == _ActiveViewType.empty) return;
    _activeViewHistory.add(
      _ActiveStateSnapshot(
        viewType: _activeViewType,
        workflowId: _activeWorkflowId,
        agentId: _activeAgentId,
        toolId: _activeToolId,
        useCaseId: _activeUseCaseId,
        summaryTitle: _activeSummaryTitle,
        summarySubtitle: _activeSummarySubtitle,
      ),
    );
    if (_activeViewHistory.length > 12) {
      _activeViewHistory.removeAt(0);
    }
  }

  void _goBackInline() {
    setState(() {
      if (_activeViewHistory.isEmpty) {
        _activeViewType = _ActiveViewType.empty;
        _clearActiveIds();
        return;
      }
      final previous = _activeViewHistory.removeLast();
      _activeViewType = previous.viewType;
      _activeWorkflowId = previous.workflowId;
      _activeAgentId = previous.agentId;
      _activeToolId = previous.toolId;
      _activeUseCaseId = previous.useCaseId;
      _activeSummaryTitle = previous.summaryTitle;
      _activeSummarySubtitle = previous.summarySubtitle;
    });
  }

  void _clearActiveIds() {
    _activeWorkflowId = null;
    _activeAgentId = null;
    _activeToolId = null;
    _activeUseCaseId = null;
    _activeSummaryTitle = null;
    _activeSummarySubtitle = null;
  }

  void _resetParameters() {
    setState(() {
      _model = _mode.config.models.isEmpty ? '' : _mode.config.models.first;
      _aspect = '9:16';
      _quality = 'Сбалансировано';
    });
  }
}

class _DesktopStation extends StatelessWidget {
  const _DesktopStation({
    required this.mode,
    required this.historyTab,
    required this.taskController,
    required this.recommendation,
    required this.activeViewType,
    required this.activeWorkflowId,
    required this.activeAgentId,
    required this.activeToolId,
    required this.activeUseCaseId,
    required this.activeSummaryTitle,
    required this.activeSummarySubtitle,
    required this.model,
    required this.aspect,
    required this.quality,
    required this.settings,
    required this.onMode,
    required this.onHistoryTab,
    required this.onSubmit,
    required this.onQuickGoal,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onOpenUseCase,
    required this.onOpenSession,
    required this.onOpenProject,
    required this.onNewSession,
    required this.onBack,
    required this.onModel,
    required this.onAspect,
    required this.onQuality,
    required this.onReset,
    required this.onNavigate,
  });

  final _WorkMode mode;
  final String historyTab;
  final TextEditingController taskController;
  final RoutingRecommendation? recommendation;
  final _ActiveViewType activeViewType;
  final String? activeWorkflowId;
  final String? activeAgentId;
  final String? activeToolId;
  final String? activeUseCaseId;
  final String? activeSummaryTitle;
  final String? activeSummarySubtitle;
  final String model;
  final String aspect;
  final String quality;
  final AppSettings settings;
  final ValueChanged<_WorkMode> onMode;
  final ValueChanged<String> onHistoryTab;
  final VoidCallback onSubmit;
  final ValueChanged<String> onQuickGoal;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final ValueChanged<String?> onOpenUseCase;
  final void Function(String title, String subtitle) onOpenSession;
  final void Function(String title, String subtitle) onOpenProject;
  final VoidCallback onNewSession;
  final VoidCallback onBack;
  final ValueChanged<String> onModel;
  final ValueChanged<String> onAspect;
  final ValueChanged<String> onQuality;
  final VoidCallback onReset;
  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _TopBar(mode: mode, onMode: onMode),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(286, 18, 336, 118),
                child: _CenterStage(
                  mode: mode,
                  recommendation: recommendation,
                  activeViewType: activeViewType,
                  activeWorkflowId: activeWorkflowId,
                  activeAgentId: activeAgentId,
                  activeToolId: activeToolId,
                  activeUseCaseId: activeUseCaseId,
                  activeSummaryTitle: activeSummaryTitle,
                  activeSummarySubtitle: activeSummarySubtitle,
                  onOpenWorkflow: onOpenWorkflow,
                  onOpenAgent: onOpenAgent,
                  onOpenTool: onOpenTool,
                  onOpenUseCase: onOpenUseCase,
                  onBack: onBack,
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 22,
          top: 72,
          bottom: 24,
          width: 236,
          child: _HistoryPanel(
            tab: historyTab,
            onTab: onHistoryTab,
            onNavigate: onNavigate,
            onOpenWorkflow: onOpenWorkflow,
            onOpenAgent: onOpenAgent,
            onOpenTool: onOpenTool,
            onOpenUseCase: onOpenUseCase,
            onOpenSession: onOpenSession,
            onOpenProject: onOpenProject,
            onNewSession: onNewSession,
          ),
        ),
        Positioned(
          right: 22,
          top: 72,
          bottom: 24,
          width: 286,
          child: _SettingsPanel(
            model: model,
            aspect: aspect,
            quality: quality,
            mode: mode,
            settings: settings,
            activeViewType: activeViewType,
            activeWorkflowId: activeWorkflowId,
            activeAgentId: activeAgentId,
            activeToolId: activeToolId,
            activeUseCaseId: activeUseCaseId,
            onModel: onModel,
            onAspect: onAspect,
            onQuality: onQuality,
            onReset: onReset,
            onOpenWorkflow: onOpenWorkflow,
            onOpenTool: onOpenTool,
          ),
        ),
        Positioned(
          left: 330,
          right: 380,
          bottom: 24,
          child: _PromptComposer(
            mode: mode,
            controller: taskController,
            onSubmit: onSubmit,
            onQuickGoal: onQuickGoal,
          ),
        ),
      ],
    );
  }
}

class _MobileStation extends StatelessWidget {
  const _MobileStation({
    required this.mode,
    required this.taskController,
    required this.recommendation,
    required this.activeViewType,
    required this.activeWorkflowId,
    required this.activeAgentId,
    required this.activeToolId,
    required this.activeUseCaseId,
    required this.activeSummaryTitle,
    required this.activeSummarySubtitle,
    required this.model,
    required this.aspect,
    required this.quality,
    required this.settings,
    required this.onMode,
    required this.onSubmit,
    required this.onQuickGoal,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onOpenUseCase,
    required this.onBack,
    required this.onModel,
    required this.onAspect,
    required this.onQuality,
    required this.onReset,
  });

  final _WorkMode mode;
  final TextEditingController taskController;
  final RoutingRecommendation? recommendation;
  final _ActiveViewType activeViewType;
  final String? activeWorkflowId;
  final String? activeAgentId;
  final String? activeToolId;
  final String? activeUseCaseId;
  final String? activeSummaryTitle;
  final String? activeSummarySubtitle;
  final String model;
  final String aspect;
  final String quality;
  final AppSettings settings;
  final ValueChanged<_WorkMode> onMode;
  final VoidCallback onSubmit;
  final ValueChanged<String> onQuickGoal;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final ValueChanged<String?> onOpenUseCase;
  final VoidCallback onBack;
  final ValueChanged<String> onModel;
  final ValueChanged<String> onAspect;
  final ValueChanged<String> onQuality;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
      children: [
        _TopBar(mode: mode, onMode: onMode, compact: true),
        const SizedBox(height: 18),
        SizedBox(
          height: 520,
          child: _CenterStage(
            mode: mode,
            recommendation: recommendation,
            activeViewType: activeViewType,
            activeWorkflowId: activeWorkflowId,
            activeAgentId: activeAgentId,
            activeToolId: activeToolId,
            activeUseCaseId: activeUseCaseId,
            activeSummaryTitle: activeSummaryTitle,
            activeSummarySubtitle: activeSummarySubtitle,
            onOpenWorkflow: onOpenWorkflow,
            onOpenAgent: onOpenAgent,
            onOpenTool: onOpenTool,
            onOpenUseCase: onOpenUseCase,
            onBack: onBack,
          ),
        ),
        const SizedBox(height: 14),
        _PromptComposer(
          mode: mode,
          controller: taskController,
          onSubmit: onSubmit,
          onQuickGoal: onQuickGoal,
        ),
        const SizedBox(height: 14),
        _SettingsPanel(
          model: model,
          aspect: aspect,
          quality: quality,
          mode: mode,
          settings: settings,
          activeViewType: activeViewType,
          activeWorkflowId: activeWorkflowId,
          activeAgentId: activeAgentId,
          activeToolId: activeToolId,
          activeUseCaseId: activeUseCaseId,
          onModel: onModel,
          onAspect: onAspect,
          onQuality: onQuality,
          onReset: onReset,
          onOpenWorkflow: onOpenWorkflow,
          onOpenTool: onOpenTool,
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.mode,
    required this.onMode,
    this.compact = false,
  });

  final _WorkMode mode;
  final ValueChanged<_WorkMode> onMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 96 : 56,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 22),
        child: compact
            ? Column(
                children: [
                  _TopIdentity(compact: compact),
                  const SizedBox(height: 10),
                  _ModeTabs(mode: mode, onMode: onMode, compact: compact),
                ],
              )
            : Row(
                children: [
                  const SizedBox(width: 190, child: _TopIdentity()),
                  Expanded(
                    child: Center(
                      child: _ModeTabs(mode: mode, onMode: onMode),
                    ),
                  ),
                  const SizedBox(width: 190, child: _TopActions()),
                ],
              ),
      ),
    );
  }
}

class _TopIdentity extends StatelessWidget {
  const _TopIdentity({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF101218),
            border: Border.all(color: const Color(0x14FFFFFF)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.blur_on_rounded, size: 16),
        ),
        const SizedBox(width: 8),
        const Text(
          'AI Operator OS',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.dark_mode_outlined, size: 17, color: Color(0xFF8B8F9A)),
        SizedBox(width: 12),
        _SoftBadge('Hybrid'),
        SizedBox(width: 12),
        CircleAvatar(radius: 12, backgroundColor: Color(0xFF242833)),
      ],
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({
    required this.mode,
    required this.onMode,
    this.compact = false,
  });

  final _WorkMode mode;
  final ValueChanged<_WorkMode> onMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in _WorkMode.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onMode(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: mode == item
                        ? const Color(0x1AFF7A4D)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: mode == item
                          ? const Color(0xFFFF9A78)
                          : const Color(0xFFB0B4BE),
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.tab,
    required this.onTab,
    required this.onNavigate,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onOpenUseCase,
    required this.onOpenSession,
    required this.onOpenProject,
    required this.onNewSession,
  });

  final String tab;
  final ValueChanged<String> onTab;
  final ValueChanged<AppDestination> onNavigate;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final ValueChanged<String?> onOpenUseCase;
  final void Function(String title, String subtitle) onOpenSession;
  final void Function(String title, String subtitle) onOpenProject;
  final VoidCallback onNewSession;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Рабочее пространство',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Здесь хранятся текущие задачи, проекты, быстрые сценарии и избранные инструменты.',
              style: TextStyle(
                color: Color(0xFF7D828D),
                fontSize: 10,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onNewSession,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Новая задача'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onOpenProject(
                      'Новый проект',
                      'Проект: постоянная работа с задачами, планами и результатами',
                    ),
                    icon: const Icon(
                      Icons.create_new_folder_outlined,
                      size: 16,
                    ),
                    label: const Text('Новый проект'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 16),
                hintText:
                    'Найти задачу, проект, AI-помощника, план или инструмент...',
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0x12FFFFFF)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final item in ['Задачи', 'Проекты', 'Избранное'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _TinyTab(
                        label: item,
                        selected: tab == item,
                        onTap: () => onTab(item),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (tab == 'Задачи') ...[
              const _PanelLabel('АКТИВНАЯ ЗАДАЧА'),
              const _SectionHint('то, над чем работаешь сейчас'),
              _HistoryItem(
                title: '10 Reels для трека',
                subtitle: 'активная задача',
                type: 'задача',
                icon: Icons.bolt_rounded,
                onTap: () => onOpenSession(
                  '10 Reels для трека',
                  'Активная задача: план, AI-помощники и инструменты остаются внутри рабочей станции',
                ),
              ),
              const SizedBox(height: 14),
              const _PanelLabel('НЕДАВНИЕ ЗАДАЧИ'),
              const _SectionHint('быстрый возврат к прошлым рабочим сессиям'),
              _HistoryItem(
                title: 'AI-фриланс разведка',
                subtitle: 'задача',
                type: 'задача',
                icon: Icons.manage_search_rounded,
                onTap: () => onOpenUseCase('find-ai-freelance-jobs'),
              ),
              _HistoryItem(
                title: 'Оживление фото',
                subtitle: 'задача',
                type: 'задача',
                icon: Icons.photo_library_outlined,
                onTap: () => onOpenUseCase('restore-old-photos-service'),
              ),
              _HistoryItem(
                title: 'Локализация видео',
                subtitle: 'задача',
                type: 'задача',
                icon: Icons.subtitles_outlined,
                onTap: () => onOpenUseCase('video-localization'),
              ),
              const SizedBox(height: 14),
              const _PanelLabel('БЫСТРЫЕ СЦЕНАРИИ'),
              const _SectionHint('готовые планы работы'),
              _HistoryItem(
                title: 'Фабрика коротких AI-видео',
                subtitle: 'сценарий',
                type: 'сценарий',
                icon: Icons.schema_outlined,
                onTap: () => onOpenWorkflow('ai-short-video-factory'),
              ),
              _HistoryItem(
                title: 'Промо-пак музыкального релиза',
                subtitle: 'сценарий',
                type: 'сценарий',
                icon: Icons.queue_music_outlined,
                onTap: () => onOpenWorkflow('music-release-promo-pack'),
              ),
              _HistoryItem(
                title: 'Конструктор сториборда',
                subtitle: 'сценарий',
                type: 'сценарий',
                icon: Icons.view_timeline_outlined,
                onTap: () => onOpenWorkflow('cinematic-scene-builder'),
              ),
              _HistoryItem(
                title: 'Конструктор трейлера',
                subtitle: 'сценарий',
                type: 'сценарий',
                icon: Icons.local_movies_outlined,
                onTap: () => onOpenWorkflow('ai-short-video-factory'),
              ),
              const SizedBox(height: 14),
              const _PanelLabel('ПРОЕКТЫ'),
              const _SectionHint('долгие направления работы'),
              _HistoryItem(
                title: 'Музыкальный релиз',
                subtitle: 'проект',
                type: 'проект',
                icon: Icons.folder_outlined,
                onTap: () => onOpenProject(
                  'Музыкальный релиз',
                  'Постоянный проект: задачи, планы работы и результаты',
                ),
              ),
              _HistoryItem(
                title: 'Контент-завод',
                subtitle: 'проект',
                type: 'проект',
                icon: Icons.folder_outlined,
                onTap: () => onOpenProject(
                  'Контент-завод',
                  'Проект для пакетной генерации Shorts, Reels и постов',
                ),
              ),
              const SizedBox(height: 14),
              const _PanelLabel('ИЗБРАННЫЕ ИНСТРУМЕНТЫ'),
              const _SectionHint('нейросети, которые часто используешь'),
              _HistoryItem(
                title: 'Kling',
                subtitle: 'видео-инструмент',
                type: 'инструмент',
                icon: Icons.movie_creation_outlined,
                onTap: () => onOpenTool('kling'),
              ),
              _HistoryItem(
                title: 'ChatGPT',
                subtitle: 'текст / промпты',
                type: 'инструмент',
                icon: Icons.grid_view_rounded,
                onTap: () => onOpenTool('chatgpt'),
              ),
              _HistoryItem(
                title: 'n8n',
                subtitle: 'автоматизация',
                type: 'инструмент',
                icon: Icons.account_tree_outlined,
                onTap: () => onOpenTool('n8n'),
              ),
              _HistoryItem(
                title: 'Midjourney',
                subtitle: 'дизайн-инструмент',
                type: 'инструмент',
                icon: Icons.auto_awesome_mosaic_outlined,
                onTap: () => onOpenTool('midjourney'),
              ),
            ],
            if (tab == 'Проекты') ...[
              const _PanelLabel('ПРОЕКТЫ'),
              _HistoryItem(
                title: 'Музыкальный релиз',
                subtitle: 'проект',
                type: 'проект',
                icon: Icons.folder_outlined,
                onTap: () => onOpenProject(
                  'Музыкальный релиз',
                  'Постоянный проект: задачи, планы работы и результаты',
                ),
              ),
              _HistoryItem(
                title: 'Контент-фабрика',
                subtitle: 'проект',
                type: 'проект',
                icon: Icons.folder_outlined,
                onTap: () => onOpenProject(
                  'Контент-фабрика',
                  'Проект для пакетной генерации Shorts, Reels и постов',
                ),
              ),
              _HistoryItem(
                title: 'AI-сервисы для клиентов',
                subtitle: 'проект',
                type: 'проект',
                icon: Icons.folder_outlined,
                onTap: () => onOpenProject(
                  'AI-сервисы для клиентов',
                  'Проект для клиентских сценариев, предложений и результатов',
                ),
              ),
            ],
            if (tab == 'Избранное') ...[
              const _PanelLabel('AI-ПОМОЩНИКИ'),
              _HistoryItem(
                title: 'AI-помощник-режиссер',
                subtitle: 'AI-помощник',
                type: 'помощник',
                icon: Icons.smart_toy_outlined,
                onTap: () => onOpenAgent('director-agent'),
              ),
              const SizedBox(height: 10),
              const _PanelLabel('ПЛАНЫ РАБОТЫ'),
              _HistoryItem(
                title: 'Фабрика коротких AI-видео',
                subtitle: 'сценарий',
                type: 'сценарий',
                icon: Icons.schema_outlined,
                onTap: () => onOpenWorkflow('ai-short-video-factory'),
              ),
              const SizedBox(height: 10),
              const _PanelLabel('ИЗБРАННЫЕ ИНСТРУМЕНТЫ'),
              _HistoryItem(
                title: 'Kling',
                subtitle: 'инструмент',
                type: 'инструмент',
                icon: Icons.movie_creation_outlined,
                onTap: () => onOpenTool('kling'),
              ),
              _HistoryItem(
                title: 'ChatGPT',
                subtitle: 'инструмент',
                type: 'инструмент',
                icon: Icons.grid_view_rounded,
                onTap: () => onOpenTool('chatgpt'),
              ),
              _HistoryItem(
                title: 'n8n',
                subtitle: 'инструмент',
                type: 'инструмент',
                icon: Icons.account_tree_outlined,
                onTap: () => onOpenTool('n8n'),
              ),
            ],
            const SizedBox(height: 6),
            _HistoryFooter(
              onNavigate: onNavigate,
              onOpenWorkflow: onOpenWorkflow,
              onOpenAgent: onOpenAgent,
              onOpenTool: onOpenTool,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterStage extends StatelessWidget {
  const _CenterStage({
    required this.mode,
    required this.recommendation,
    required this.activeViewType,
    required this.activeWorkflowId,
    required this.activeAgentId,
    required this.activeToolId,
    required this.activeUseCaseId,
    required this.activeSummaryTitle,
    required this.activeSummarySubtitle,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onOpenUseCase,
    required this.onBack,
  });

  final _WorkMode mode;
  final RoutingRecommendation? recommendation;
  final _ActiveViewType activeViewType;
  final String? activeWorkflowId;
  final String? activeAgentId;
  final String? activeToolId;
  final String? activeUseCaseId;
  final String? activeSummaryTitle;
  final String? activeSummarySubtitle;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final ValueChanged<String?> onOpenUseCase;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final Widget stage;
    if (activeViewType == _ActiveViewType.empty) {
      stage = mode == _WorkMode.toolkit
          ? _ToolkitSearchStage(
              mode: mode,
              onOpenTool: onOpenTool,
              key: const ValueKey('toolkit-search'),
            )
          : _EmptyModeStage(mode: mode, key: ValueKey(mode));
    } else if (activeViewType == _ActiveViewType.routePlan) {
      stage = recommendation == null
          ? mode == _WorkMode.toolkit
                ? _ToolkitSearchStage(
                    mode: mode,
                    onOpenTool: onOpenTool,
                    key: const ValueKey('toolkit-search'),
                  )
                : _EmptyModeStage(mode: mode, key: ValueKey(mode))
          : _RouteStage(
              recommendation: recommendation!,
              onOpenWorkflow: onOpenWorkflow,
              onOpenAgent: onOpenAgent,
              onOpenTool: onOpenTool,
              key: const ValueKey('route-stage'),
            );
    } else {
      stage = _EntityStage(
        activeViewType: activeViewType,
        activeWorkflowId: activeWorkflowId,
        activeAgentId: activeAgentId,
        activeToolId: activeToolId,
        activeUseCaseId: activeUseCaseId,
        activeSummaryTitle: activeSummaryTitle,
        activeSummarySubtitle: activeSummarySubtitle,
        recommendation: recommendation,
        onOpenWorkflow: onOpenWorkflow,
        onOpenAgent: onOpenAgent,
        onOpenTool: onOpenTool,
        onOpenUseCase: onOpenUseCase,
        onBack: onBack,
        key: ValueKey(
          '${activeViewType.name}-${activeWorkflowId ?? activeAgentId ?? activeToolId ?? activeUseCaseId ?? activeSummaryTitle ?? 'default'}',
        ),
      );
    }

    return Column(
      children: [
        _SessionHeader(
          mode: mode,
          recommendation: recommendation,
          activeViewType: activeViewType,
        ),
        const SizedBox(height: 18),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: stage,
          ),
        ),
      ],
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.mode,
    required this.recommendation,
    required this.activeViewType,
  });

  final _WorkMode mode;
  final RoutingRecommendation? recommendation;
  final _ActiveViewType activeViewType;

  @override
  Widget build(BuildContext context) {
    final sessionName =
        recommendation?.task ?? 'Новая задача в рабочей станции';
    final activeWork = switch (activeViewType) {
      _ActiveViewType.empty => 'без активного объекта',
      _ActiveViewType.routePlan => 'AI-маршрут',
      _ActiveViewType.workflow => 'план работы открыт',
      _ActiveViewType.agent => 'AI-помощник подключен',
      _ActiveViewType.tool => 'инструмент открыт',
      _ActiveViewType.useCase => 'кейс открыт',
      _ActiveViewType.session => 'задача открыта',
      _ActiveViewType.project => 'проект открыт',
    };
    final status = switch (activeViewType) {
      _ActiveViewType.empty => 'черновик',
      _ActiveViewType.routePlan => 'планирование',
      _ActiveViewType.workflow ||
      _ActiveViewType.agent ||
      _ActiveViewType.tool ||
      _ActiveViewType.useCase => 'ручной запуск',
      _ActiveViewType.session || _ActiveViewType.project => 'готово',
    };

    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final badges = [
            _SoftBadge(mode.label),
            _SoftBadge(activeWork),
            _SoftBadge(status),
          ];
          final title = Row(
            children: [
              const Icon(Icons.radio_button_checked_rounded, size: 15),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sessionName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: badges),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 10),
              Wrap(spacing: 6, runSpacing: 6, children: badges),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyModeStage extends StatelessWidget {
  const _EmptyModeStage({super.key, required this.mode});

  final _WorkMode mode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                border: Border.all(color: const Color(0x14FFFFFF)),
                shape: BoxShape.circle,
              ),
              child: Icon(mode.icon, color: const Color(0xFFF2F3F5), size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              mode.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF2F3F5),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mode.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8B8F9A),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              switch (mode) {
                _WorkMode.video =>
                  'Опиши ролик или сцену. OS подберет план работы, видео-инструменты и AI-помощников.',
                _WorkMode.toolkit => 'Найди подходящую нейросеть под задачу.',
                _WorkMode.agents =>
                  'AI-помощники помогают закрывать отдельные этапы работы.',
                _ => 'Опиши задачу. OS соберет маршрут, промпты и инструменты.',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7D828D),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              alignment: WrapAlignment.center,
              children: [
                for (final action in mode.quickActions)
                  _SoftBadge(action.label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolkitSearchStage extends StatelessWidget {
  const _ToolkitSearchStage({
    super.key,
    required this.mode,
    required this.onOpenTool,
  });

  final _WorkMode mode;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final graph = const GraphRepository();
    final tools = graph.toolsByIds(mode.config.recommendedToolIds);
    return Center(
      child: _GlassPanel(
        width: 680,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelLabel('БАЗА НЕЙРОСЕТЕЙ'),
            const SizedBox(height: 10),
            const Text(
              'Найди нейросеть или сервис под задачу',
              style: TextStyle(
                color: Color(0xFFF2F3F5),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mode.description,
              style: const TextStyle(color: Color(0xFF9AA0AA), height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                hintText:
                    'Например: Kling, Nano Banana, Veo, ChatGPT, ComfyUI...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x12FFFFFF)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: const [
                _SoftBadge('Все'),
                _SoftBadge('Бесплатные'),
                _SoftBadge('Видео'),
                _SoftBadge('Изображения'),
                _SoftBadge('Аудио'),
                _SoftBadge('Текст'),
                _SoftBadge('Локальные'),
                _SoftBadge('API'),
                _SoftBadge('Free'),
              ],
            ),
            const SizedBox(height: 16),
            for (final tool in tools.take(5))
              _ToolSearchResult(tool: tool, onOpenTool: onOpenTool),
          ],
        ),
      ),
    );
  }
}

class _ToolSearchResult extends StatelessWidget {
  const _ToolSearchResult({required this.tool, required this.onOpenTool});

  final AiTool tool;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x10FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SoftBadge(tool.category.label),
                    _SoftBadge(tool.pricingType.label),
                    _SoftBadge(tool.integrationType.label),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => onOpenTool(tool.id),
            child: const Text('Открыть в OS'),
          ),
        ],
      ),
    );
  }
}

class _RouteStage extends StatelessWidget {
  const _RouteStage({
    super.key,
    required this.recommendation,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
  });

  final RoutingRecommendation recommendation;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final graph = const GraphRepository();
    final agents = graph.agentsByIds(recommendation.agentIds);
    final tools = graph.toolsByIds(recommendation.toolIds);
    final firstAgentId = recommendation.agentIds.isEmpty
        ? null
        : recommendation.agentIds.first;
    final firstToolId = recommendation.toolIds.isEmpty
        ? null
        : recommendation.toolIds.first;
    return Center(
      child: _GlassPanel(
        key: const ValueKey('recommended-plan'),
        width: 620,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelLabel('AI-маршрут'),
            const SizedBox(height: 10),
            Text(
              recommendation.task,
              style: const TextStyle(
                color: Color(0xFFF2F3F5),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            _RouteLine('Тип задачи', recommendation.estimatedCost),
            _RouteLine('План работы', recommendation.recommendedWorkflow),
            _RouteLine(
              'AI-помощники',
              agents.map((item) => item.name).join(' / '),
            ),
            _RouteLine(
              'Нейросети / Инструменты',
              tools.map((item) => item.name).join(' / '),
            ),
            _RouteLine(
              'Следующие шаги',
              recommendation.manualSteps.take(3).join(' → '),
            ),
            const SizedBox(height: 8),
            const Text(
              'Сейчас OS помогает вручную: собирает промпты, AI-маршрут и нужные нейросети. API и локальные агенты подключим позже.',
              style: TextStyle(
                color: Color(0xFF8B8F9A),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            _ResponsiveActionBar(
              children: [
                FilledButton.icon(
                  onPressed: () => onOpenWorkflow(recommendation.workflowId),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Открыть план работы'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpenAgent(firstAgentId),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Подключить AI-помощника'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpenTool(firstToolId),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Открыть инструменты'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityStage extends StatelessWidget {
  const _EntityStage({
    super.key,
    required this.activeViewType,
    required this.activeWorkflowId,
    required this.activeAgentId,
    required this.activeToolId,
    required this.activeUseCaseId,
    required this.activeSummaryTitle,
    required this.activeSummarySubtitle,
    required this.recommendation,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onOpenUseCase,
    required this.onBack,
  });

  final _ActiveViewType activeViewType;
  final String? activeWorkflowId;
  final String? activeAgentId;
  final String? activeToolId;
  final String? activeUseCaseId;
  final String? activeSummaryTitle;
  final String? activeSummarySubtitle;
  final RoutingRecommendation? recommendation;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final ValueChanged<String?> onOpenUseCase;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final graph = const GraphRepository();
    return switch (activeViewType) {
      _ActiveViewType.workflow => _WorkflowStage(
        workflow: _firstOrNull(
          graph.workflowsByIds([
            activeWorkflowId ??
                recommendation?.workflowId ??
                'ai-short-video-factory',
          ]),
        ),
        onOpenAgent: onOpenAgent,
        onOpenTool: onOpenTool,
        onBack: onBack,
      ),
      _ActiveViewType.agent => _AgentStage(
        agent: _firstOrNull(
          graph.agentsByIds([
            activeAgentId ??
                _firstOrNull(recommendation?.agentIds ?? const []) ??
                'tool-router-agent',
          ]),
        ),
        onOpenWorkflow: onOpenWorkflow,
        onOpenTool: onOpenTool,
        onBack: onBack,
      ),
      _ActiveViewType.tool => _ToolStage(
        tool: _firstOrNull(
          graph.toolsByIds([
            activeToolId ??
                _firstOrNull(recommendation?.toolIds ?? const []) ??
                'chatgpt',
          ]),
        ),
        onOpenAgent: onOpenAgent,
        onOpenWorkflow: onOpenWorkflow,
        onBack: onBack,
      ),
      _ActiveViewType.useCase => _UseCaseStage(
        useCase: _firstOrNull(
          graph.useCasesByIds([
            activeUseCaseId ??
                _firstOrNull(recommendation?.useCaseIds ?? const []) ??
                'make-10-reels-for-track',
          ]),
        ),
        onOpenWorkflow: onOpenWorkflow,
        onOpenAgent: onOpenAgent,
        onOpenTool: onOpenTool,
        onBack: onBack,
      ),
      _ActiveViewType.session || _ActiveViewType.project => _SummaryStage(
        title: activeSummaryTitle ?? 'Рабочая область',
        subtitle:
            activeSummarySubtitle ??
            'Здесь будут задачи, планы работы, AI-помощники, инструменты и результаты.',
        type: activeViewType == _ActiveViewType.session ? 'задача' : 'проект',
        onOpenWorkflow: onOpenWorkflow,
        onOpenUseCase: onOpenUseCase,
        onBack: onBack,
      ),
      _ActiveViewType.empty ||
      _ActiveViewType.routePlan => const SizedBox.shrink(),
    };
  }
}

class _WorkflowStage extends StatelessWidget {
  const _WorkflowStage({
    required this.workflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onBack,
  });

  final WorkflowTemplate? workflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (workflow == null) {
      return const _MissingEntityStage('План работы не найден');
    }

    final graph = const GraphRepository();
    final agents = graph.agentsByIds([
      ...workflow!.agentIds,
      for (final step in workflow!.steps)
        if (step.agentId != null) step.agentId!,
    ]);
    final tools = graph.toolsByIds([
      ...workflow!.requiredTools,
      ...workflow!.optionalTools,
      ...workflow!.toolIds,
      for (final step in workflow!.steps) ...step.toolIds,
    ]);
    final firstPrompt = workflow!.steps.isEmpty
        ? workflow!.description
        : workflow!.steps.first.promptTemplate;

    return Center(
      child: _GlassPanel(
        width: 680,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _InlineBackHeader(
                breadcrumb: 'Рабочая станция / План работы',
                onBack: onBack,
              ),
              const SizedBox(height: 14),
              const _PanelLabel('ПЛАН РАБОТЫ'),
              const SizedBox(height: 10),
              Text(
                workflow!.title,
                style: const TextStyle(
                  color: Color(0xFFF2F3F5),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                workflow!.description,
                style: const TextStyle(color: Color(0xFF9AA0AA), height: 1.35),
              ),
              const SizedBox(height: 8),
              const Text(
                'Пошаговый AI-сценарий для выполнения задачи.',
                style: TextStyle(color: Color(0xFF7D828D), fontSize: 12),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _SoftBadge(workflow!.category),
                  _SoftBadge(workflow!.estimatedTime),
                  _SoftBadge(workflow!.automationLevel.label),
                  _SoftBadge(workflow!.monetizationPotential.label),
                ],
              ),
              const SizedBox(height: 18),
              for (final step in workflow!.steps.take(5))
                _StageStep(step: step, onOpenTool: onOpenTool),
              const SizedBox(height: 12),
              _LinkedNames(
                title: 'AI-помощники',
                names: agents.map((item) => item.name).toList(),
                ids: agents.map((item) => item.id).toList(),
                onOpen: onOpenAgent,
                helper: 'AI-помощники для отдельных этапов работы.',
              ),
              _LinkedNames(
                title: 'Нейросети / Инструменты',
                names: tools.map((item) => item.name).toList(),
                ids: tools.map((item) => item.id).toList(),
                onOpen: onOpenTool,
                helper: 'Нейросети и сервисы, используемые в этом плане.',
              ),
              const SizedBox(height: 18),
              const _DemoModeNotice(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('План работы запущен вручную'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Начать план вручную'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copyText(context, firstPrompt),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Скопировать стартовый промпт'),
                  ),
                  OutlinedButton.icon(
                    onPressed: tools.isEmpty
                        ? null
                        : () => onOpenTool(tools.first.id),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Открыть инструмент / сайт'),
                  ),
                  OutlinedButton.icon(
                    onPressed: agents.isEmpty
                        ? null
                        : () => onOpenAgent(agents.first.id),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Подключить AI-помощника к задаче'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Сохранено в проект')),
                      );
                    },
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Сохранить результат'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentStage extends StatelessWidget {
  const _AgentStage({
    required this.agent,
    required this.onOpenWorkflow,
    required this.onOpenTool,
    required this.onBack,
  });

  final AiAgent? agent;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenTool;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (agent == null) {
      return const _MissingEntityStage('AI-помощник не найден');
    }

    final graph = const GraphRepository();
    final tools = graph.toolsByIds([
      ...agent!.toolIds,
      ...agent!.recommendedTools,
    ]);
    final workflows = graph.workflowsByIds(agent!.workflowIds);

    return Center(
      child: _GlassPanel(
        width: 620,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InlineBackHeader(
              breadcrumb: 'Рабочая станция / AI-помощник',
              onBack: onBack,
            ),
            const SizedBox(height: 14),
            const _PanelLabel('AI-ПОМОЩНИК'),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(agent!.avatarEmoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent!.name,
                        style: const TextStyle(
                          color: Color(0xFFF2F3F5),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        agent!.role,
                        style: const TextStyle(color: Color(0xFF9AA0AA)),
                      ),
                    ],
                  ),
                ),
                _SoftBadge(agent!.status.label),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              agent!.description,
              style: const TextStyle(color: Color(0xFFE5E7EC), height: 1.35),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-помощник закрывает отдельный этап работы и подсказывает следующий ручной шаг.',
              style: TextStyle(color: Color(0xFF7D828D), fontSize: 12),
            ),
            const SizedBox(height: 16),
            _LinkedNames(
              title: 'Нейросети / Инструменты',
              names: tools.map((item) => item.name).toList(),
              ids: tools.map((item) => item.id).toList(),
              onOpen: onOpenTool,
            ),
            _LinkedNames(
              title: 'Планы работы',
              names: workflows.map((item) => item.title).toList(),
              ids: workflows.map((item) => item.id).toList(),
              onOpen: onOpenWorkflow,
            ),
            const SizedBox(height: 14),
            const _DemoModeNotice(),
            const SizedBox(height: 12),
            const _ManualModeBox(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${agent!.name}: демо-ответ готов'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Подключить AI-помощника к задаче'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyText(context, agent!.systemPrompt),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать стартовый промпт'),
                ),
                OutlinedButton.icon(
                  onPressed: tools.isEmpty
                      ? null
                      : () => onOpenTool(tools.first.id),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Открыть инструмент / сайт'),
                ),
                OutlinedButton.icon(
                  onPressed: workflows.isEmpty
                      ? null
                      : () => onOpenWorkflow(workflows.first.id),
                  icon: const Icon(Icons.schema_outlined),
                  label: const Text('Открыть план работы'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolStage extends StatelessWidget {
  const _ToolStage({
    required this.tool,
    required this.onOpenAgent,
    required this.onOpenWorkflow,
    required this.onBack,
  });

  final AiTool? tool;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenWorkflow;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (tool == null) {
      return const _MissingEntityStage('Нейросеть / инструмент не найдены');
    }

    final graph = const GraphRepository();
    final agents = graph.agentsByIds(tool!.agentIds);
    final workflows = graph.workflowsByIds(tool!.workflowIds);
    final prompt =
        'Задача: {{task}}\nИнструмент: ${tool!.name}\nРежим: ручной запуск\nНужно: подготовь точный промпт и шаги запуска.';

    return Center(
      child: _GlassPanel(
        width: 620,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InlineBackHeader(
              breadcrumb: 'Рабочая станция / Инструмент',
              onBack: onBack,
            ),
            const SizedBox(height: 14),
            const _PanelLabel('НЕЙРОСЕТЬ / ИНСТРУМЕНТ'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tool!.name,
                    style: const TextStyle(
                      color: Color(0xFFF2F3F5),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _SoftBadge(tool!.integrationType.label),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tool!.description,
              style: const TextStyle(color: Color(0xFFE5E7EC), height: 1.35),
            ),
            const SizedBox(height: 8),
            const Text(
              'Это сервис из рабочего стека. Сейчас он запускается вручную: открой сайт и вставь подготовленный промпт.',
              style: TextStyle(color: Color(0xFF7D828D), fontSize: 12),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _SoftBadge(tool!.category.label),
                _SoftBadge(tool!.pricingType.label),
                _SoftBadge(tool!.integrationType.label),
                if (tool!.isLocal) const _SoftBadge('Local'),
              ],
            ),
            const SizedBox(height: 16),
            _RouteLine('Лучше для', tool!.bestFor),
            _RouteLine('Бесплатно', tool!.freeCreditsInfo),
            _RouteLine('Ограничения', tool!.limitations),
            _LinkedNames(
              title: 'AI-помощники',
              names: agents.map((item) => item.name).toList(),
              ids: agents.map((item) => item.id).toList(),
              onOpen: onOpenAgent,
            ),
            _LinkedNames(
              title: 'Планы работы',
              names: workflows.map((item) => item.title).toList(),
              ids: workflows.map((item) => item.id).toList(),
              onOpen: onOpenWorkflow,
            ),
            const SizedBox(height: 14),
            const _DemoModeNotice(),
            const SizedBox(height: 12),
            const _ManualModeBox(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => const UrlService().open(tool!.url),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Открыть инструмент / сайт'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyText(context, prompt),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать стартовый промпт'),
                ),
                OutlinedButton.icon(
                  onPressed: agents.isEmpty
                      ? null
                      : () => onOpenAgent(agents.first.id),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Подключить AI-помощника к задаче'),
                ),
                OutlinedButton.icon(
                  onPressed: workflows.isEmpty
                      ? null
                      : () => onOpenWorkflow(workflows.first.id),
                  icon: const Icon(Icons.schema_outlined),
                  label: const Text('Добавить в план работы'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UseCaseStage extends StatelessWidget {
  const _UseCaseStage({
    required this.useCase,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onBack,
  });

  final UseCase? useCase;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (useCase == null) return const _MissingEntityStage('Кейс не найден');

    final graph = const GraphRepository();
    final agents = graph.agentsByIds(useCase!.recommendedAgentIds);
    final tools = graph.toolsByIds(useCase!.recommendedToolIds);
    final workflows = graph.workflowsByIds(useCase!.recommendedWorkflowIds);

    return Center(
      child: _GlassPanel(
        width: 660,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InlineBackHeader(
              breadcrumb: 'Рабочая станция / Задача',
              onBack: onBack,
            ),
            const SizedBox(height: 14),
            const _PanelLabel('АКТИВНЫЙ КЕЙС'),
            const SizedBox(height: 10),
            Text(
              useCase!.title,
              style: const TextStyle(
                color: Color(0xFFF2F3F5),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              useCase!.description,
              style: const TextStyle(color: Color(0xFFE5E7EC), height: 1.35),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _SoftBadge(useCase!.category),
                _SoftBadge(useCase!.monetizationPotential.label),
                _SoftBadge(
                  useCase!.requiresHumanReview
                      ? 'проверка человеком'
                      : 'с поддержкой OS',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LinkedNames(
              title: 'Планы работы',
              names: workflows.map((item) => item.title).toList(),
              ids: workflows.map((item) => item.id).toList(),
              onOpen: onOpenWorkflow,
            ),
            _LinkedNames(
              title: 'AI-помощники',
              names: agents.map((item) => item.name).toList(),
              ids: agents.map((item) => item.id).toList(),
              onOpen: onOpenAgent,
            ),
            _LinkedNames(
              title: 'Нейросети / Инструменты',
              names: tools.map((item) => item.name).toList(),
              ids: tools.map((item) => item.id).toList(),
              onOpen: onOpenTool,
            ),
            const SizedBox(height: 8),
            const _DemoModeNotice(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: workflows.isEmpty
                      ? null
                      : () => onOpenWorkflow(workflows.first.id),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Открыть план работы'),
                ),
                OutlinedButton.icon(
                  onPressed: agents.isEmpty
                      ? null
                      : () => onOpenAgent(agents.first.id),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Подключить AI-помощника к задаче'),
                ),
                OutlinedButton.icon(
                  onPressed: tools.isEmpty
                      ? null
                      : () => onOpenTool(tools.first.id),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Открыть инструмент / сайт'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStage extends StatelessWidget {
  const _SummaryStage({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.onOpenWorkflow,
    required this.onOpenUseCase,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final String type;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenUseCase;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassPanel(
        width: 560,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InlineBackHeader(
              breadcrumb:
                  'Рабочая станция / ${type == 'задача' ? 'Задача' : 'Проект'}',
              onBack: onBack,
            ),
            const SizedBox(height: 14),
            _PanelLabel(type.toUpperCase()),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF2F3F5),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF9AA0AA), height: 1.35),
            ),
            const SizedBox(height: 16),
            const _ManualModeBox(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => onOpenWorkflow('ai-short-video-factory'),
                  icon: const Icon(Icons.schema_outlined),
                  label: const Text('Открыть план работы'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpenUseCase('make-10-reels-for-track'),
                  icon: const Icon(Icons.route_outlined),
                  label: const Text('Открыть кейс'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageStep extends StatelessWidget {
  const _StageStep({required this.step, required this.onOpenTool});

  final WorkflowStep step;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x10FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            step.isAutomatable
                ? Icons.auto_awesome_rounded
                : Icons.touch_app_outlined,
            color: const Color(0xFF8B8F9A),
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.instruction,
                  style: const TextStyle(
                    color: Color(0xFF9AA0AA),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (step.toolIds.isNotEmpty)
            IconButton(
              onPressed: () => onOpenTool(step.toolIds.first),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              tooltip: 'Открыть инструмент',
            ),
        ],
      ),
    );
  }
}

class _InlineBackHeader extends StatelessWidget {
  const _InlineBackHeader({required this.breadcrumb, required this.onBack});

  final String breadcrumb;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('Назад'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            breadcrumb,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8B8F9A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveActionBar extends StatelessWidget {
  const _ResponsiveActionBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Wrap(spacing: 8, runSpacing: 8, children: children);
      },
    );
  }
}

class _DemoModeNotice extends StatelessWidget {
  const _DemoModeNotice();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Демо-режим: сейчас действия готовят план и промпты. Реальный запуск через API/локальные модели будет позже.',
      style: TextStyle(color: Color(0xFF7D828D), fontSize: 12, height: 1.35),
    );
  }
}

class _LinkedNames extends StatelessWidget {
  const _LinkedNames({
    required this.title,
    required this.names,
    this.ids = const [],
    this.onOpen,
    this.helper,
  });

  final String title;
  final List<String> names;
  final List<String> ids;
  final ValueChanged<String?>? onOpen;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteLine(title, names.take(4).join(' / ')),
          if (onOpen != null && ids.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 118),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (
                    var index = 0;
                    index < names.length && index < ids.length && index < 4;
                    index++
                  )
                    ActionChip(
                      label: Text(names[index]),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onOpen!(ids[index]),
                    ),
                ],
              ),
            ),
          ],
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(left: 118, top: 4),
              child: Text(
                helper!,
                style: const TextStyle(
                  color: Color(0xFF7D828D),
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ManualModeBox extends StatelessWidget {
  const _ManualModeBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Сейчас OS помогает вручную: собирает промпты, маршруты и инструменты. API, Local и автоматические агенты подключим позже.',
        style: TextStyle(color: Color(0xFF9AA0AA), fontSize: 12, height: 1.35),
      ),
    );
  }
}

class _MissingEntityStage extends StatelessWidget {
  const _MissingEntityStage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassPanel(
        width: 420,
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _PromptComposer extends StatelessWidget {
  const _PromptComposer({
    required this.mode,
    required this.controller,
    required this.onSubmit,
    required this.onQuickGoal,
  });

  final _WorkMode mode;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final ValueChanged<String> onQuickGoal;

  @override
  Widget build(BuildContext context) {
    final config = mode.config;
    final showMic =
        mode == _WorkMode.agents ||
        mode == _WorkMode.video ||
        mode == _WorkMode.audio;
    final formatBadge = switch (mode) {
      _WorkMode.design || _WorkMode.video => const _SoftBadge('9:16'),
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassPanel(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Column(
            children: [
              TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: mode.placeholder,
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(width: 10),
                      Icon(Icons.attach_file_rounded, size: 17),
                      SizedBox(width: 9),
                      Icon(Icons.image_outlined, size: 17),
                      SizedBox(width: 9),
                      Icon(Icons.lock_outline_rounded, size: 16),
                    ],
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showMic) ...[
                        const Icon(Icons.mic_none_rounded, size: 18),
                        const SizedBox(width: 8),
                      ],
                      if (formatBadge != null) ...[
                        formatBadge,
                        const SizedBox(width: 8),
                      ],
                      IconButton.filled(
                        key: const ValueKey('build-plan-button'),
                        onPressed: onSubmit,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        tooltip: 'Собрать план',
                      ),
                    ],
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 86),
                  suffixIconConstraints: const BoxConstraints(minWidth: 112),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          alignment: WrapAlignment.center,
          children: [
            for (final goal in mode.quickActions)
              ActionChip(
                label: Text(goal.label),
                onPressed: () => onQuickGoal(goal.task),
                visualDensity: VisualDensity.compact,
              ),
            for (final hint in config.emptyStateHints.take(2)) _SoftBadge(hint),
          ],
        ),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.model,
    required this.aspect,
    required this.quality,
    required this.mode,
    required this.settings,
    required this.activeViewType,
    required this.activeWorkflowId,
    required this.activeAgentId,
    required this.activeToolId,
    required this.activeUseCaseId,
    required this.onModel,
    required this.onAspect,
    required this.onQuality,
    required this.onReset,
    required this.onOpenWorkflow,
    required this.onOpenTool,
  });

  final String model;
  final String aspect;
  final String quality;
  final _WorkMode mode;
  final AppSettings settings;
  final _ActiveViewType activeViewType;
  final String? activeWorkflowId;
  final String? activeAgentId;
  final String? activeToolId;
  final String? activeUseCaseId;
  final ValueChanged<String> onModel;
  final ValueChanged<String> onAspect;
  final ValueChanged<String> onQuality;
  final VoidCallback onReset;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final config = mode.config;
    return _GlassPanel(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActiveContextPanel(
              activeViewType: activeViewType,
              activeWorkflowId: activeWorkflowId,
              activeAgentId: activeAgentId,
              activeToolId: activeToolId,
              activeUseCaseId: activeUseCaseId,
            ),
            const SizedBox(height: 12),
            _SettingsGroup(
              title: config.modelTitle,
              trailing: TextButton(
                onPressed: onReset,
                child: const Text('Сброс'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.modelHelper,
                    style: const TextStyle(
                      color: Color(0xFF8B8F9A),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (config.showModelSelector) ...[
                    _SelectLine(
                      value: model,
                      values: config.models,
                      onChanged: onModel,
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (final section in config.settings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _ModeSettingLine(section: section),
                    ),
                  if (!config.showModelSelector)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => onOpenTool(
                            _firstOrNull(config.recommendedToolIds),
                          ),
                          icon: const Icon(Icons.grid_view_rounded, size: 16),
                          label: const Text('Открыть инструменты'),
                        ),
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(
                            Icons.compare_arrows_rounded,
                            size: 16,
                          ),
                          label: const Text('Сравнить скоро'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            _SettingsGroup(
              title: 'AI-помощники и контекст',
              child: _ModeContext(mode),
            ),
            _SettingsGroup(
              title: 'Режим выполнения',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PathRow('Ручной запуск', Icons.open_in_new_rounded),
                  _PathRow('API позже', Icons.api_rounded),
                  _PathRow('Локально позже', Icons.dns_outlined),
                  SizedBox(height: 6),
                  Text(
                    'Сейчас OS работает в ручном режиме: она собирает маршрут, промпты и инструменты. На следующих этапах подключим OpenAI API, Ollama и автоматические агенты.',
                    style: TextStyle(
                      color: Color(0xFF8B8F9A),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _SettingsGroup(
              title: 'Следующее действие',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NextActionHint(mode: mode, activeViewType: activeViewType),
                  const SizedBox(height: 8),
                  _MetaLine('Режим OS', settings.operatorMode.label),
                  _MetaLine('Ollama', settings.ollamaBaseUrl),
                  if (seedFreeCredits.isNotEmpty)
                    _MetaLine('Бесплатно', seedFreeCredits.first.service),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReset,
                    child: const Text('Сброс'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => onOpenWorkflow(null),
                    child: const Text('Открыть план'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.padding, this.width, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == null ? null : double.infinity,
      constraints: width == null ? null : BoxConstraints(maxWidth: width!),
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xB814161C),
        border: Border.all(color: const Color(0x14FFFFFF)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _PanelLabel(title)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SelectLine extends StatelessWidget {
  const _SelectLine({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: values.contains(value) ? value : values.first,
      isDense: true,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
      items: [
        for (final item in values)
          DropdownMenuItem(
            value: item,
            child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _SegmentedValues extends StatelessWidget {
  const _SegmentedValues({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: _TinyTab(
                label: item,
                selected: item == value,
                onTap: () => onChanged(item),
              ),
            ),
          ),
      ],
    );
  }
}

class _ModeSettingLine extends StatefulWidget {
  const _ModeSettingLine({required this.section});

  final _ModeSettingConfig section;

  @override
  State<_ModeSettingLine> createState() => _ModeSettingLineState();
}

class _ModeSettingLineState extends State<_ModeSettingLine> {
  late String _value = widget.section.values.first;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.section.title,
          style: const TextStyle(
            color: Color(0xFF8B8F9A),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        _SegmentedValues(
          value: _value,
          values: widget.section.values,
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
    );
  }
}

class _ActiveContextPanel extends StatelessWidget {
  const _ActiveContextPanel({
    required this.activeViewType,
    required this.activeWorkflowId,
    required this.activeAgentId,
    required this.activeToolId,
    required this.activeUseCaseId,
  });

  final _ActiveViewType activeViewType;
  final String? activeWorkflowId;
  final String? activeAgentId;
  final String? activeToolId;
  final String? activeUseCaseId;

  @override
  Widget build(BuildContext context) {
    final graph = const GraphRepository();
    final title = switch (activeViewType) {
      _ActiveViewType.workflow =>
        _firstOrNull(
              graph.workflowsByIds([
                activeWorkflowId ?? 'ai-short-video-factory',
              ]),
            )?.title ??
            'План работы',
      _ActiveViewType.agent =>
        _firstOrNull(
              graph.agentsByIds([activeAgentId ?? 'tool-router-agent']),
            )?.name ??
            'AI-помощник',
      _ActiveViewType.tool =>
        _firstOrNull(graph.toolsByIds([activeToolId ?? 'chatgpt']))?.name ??
            'Нейросеть / Инструмент',
      _ActiveViewType.useCase =>
        _firstOrNull(
              graph.useCasesByIds([
                activeUseCaseId ?? 'make-10-reels-for-track',
              ]),
            )?.title ??
            'Кейс',
      _ActiveViewType.routePlan => 'AI-маршрут',
      _ActiveViewType.session => 'Текущая задача',
      _ActiveViewType.project => 'Проект',
      _ActiveViewType.empty => 'Настройки режима',
    };
    final rows = switch (activeViewType) {
      _ActiveViewType.workflow => const [
        ('Настройки плана', Icons.schema_outlined),
        ('Ручное выполнение', Icons.touch_app_outlined),
        ('Сохранить результаты', Icons.bookmark_add_outlined),
      ],
      _ActiveViewType.agent => const [
        ('Задача помощника', Icons.smart_toy_outlined),
        ('Демо-режим', Icons.science_outlined),
        ('API позже', Icons.api_rounded),
      ],
      _ActiveViewType.tool => const [
        ('Статус интеграции', Icons.hub_outlined),
        ('Ручной запуск', Icons.open_in_new_rounded),
        ('Копировать промпт', Icons.copy_rounded),
      ],
      _ActiveViewType.useCase => const [
        ('Рекомендованный стек', Icons.route_outlined),
        ('Потенциал, не обещание', Icons.trending_up_rounded),
        ('Проверка человеком', Icons.verified_user_outlined),
      ],
      _ => const [
        ('Настройки режима', Icons.tune_rounded),
        ('Ручной запуск', Icons.open_in_new_rounded),
        ('Local/API позже', Icons.dns_outlined),
      ],
    };

    return _SettingsGroup(
      title: activeViewType == _ActiveViewType.empty
          ? 'Активный режим'
          : 'Активный объект',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final row in rows) _PathRow(row.$1, row.$2),
        ],
      ),
    );
  }
}

class _ModeContext extends StatelessWidget {
  const _ModeContext(this.mode);

  final _WorkMode mode;

  @override
  Widget build(BuildContext context) {
    final graph = const GraphRepository();
    final tools = graph.toolsByIds(mode.config.recommendedToolIds);
    final rows = switch (mode) {
      _WorkMode.agents => const [
        ('Активный агент', Icons.smart_toy_outlined),
        ('Передача задачи', Icons.swap_horiz_rounded),
        ('Подтверждение человеком', Icons.verified_user_outlined),
      ],
      _WorkMode.text => const [
        ('Глубина анализа', Icons.manage_search_rounded),
        ('Тон текста', Icons.tune_rounded),
        ('Копировать результат', Icons.copy_rounded),
      ],
      _WorkMode.design => const [
        ('Референс стиля', Icons.image_outlined),
        ('Настроение бренда', Icons.palette_outlined),
        ('Формат', Icons.crop_rounded),
      ],
      _WorkMode.video => const [
        ('Формат кадра', Icons.aspect_ratio_rounded),
        ('Shot plan / сцены', Icons.movie_creation_outlined),
        ('Ручная генерация', Icons.open_in_new_rounded),
      ],
      _WorkMode.audio => const [
        ('Голосовая модель', Icons.record_voice_over_outlined),
        ('Музыкальное настроение', Icons.graphic_eq_rounded),
        ('Дубляж', Icons.subtitles_outlined),
      ],
      _WorkMode.toolkit => const [
        ('Бесплатно / Pro / Local', Icons.route_outlined),
        ('Статус интеграции', Icons.hub_outlined),
        ('Альтернативы', Icons.compare_arrows_rounded),
      ],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) _PathRow(row.$1, row.$2),
        if (tools.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            tools.take(3).map((tool) => tool.name).join(' / '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9AA0AA), fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _NextActionHint extends StatelessWidget {
  const _NextActionHint({required this.mode, required this.activeViewType});

  final _WorkMode mode;
  final _ActiveViewType activeViewType;

  @override
  Widget build(BuildContext context) {
    final text = switch (activeViewType) {
      _ActiveViewType.workflow =>
        mode == _WorkMode.video
            ? 'Скопируй первый промпт и открой видео-инструмент.'
            : 'Начни вручную: скопируй первый промпт и открой нужный инструмент.',
      _ActiveViewType.agent =>
        'Назначь задачу AI-помощнику и используй демо-ответ как план действий.',
      _ActiveViewType.tool =>
        'Открой сайт инструмента и вставь подготовленный промпт.',
      _ActiveViewType.useCase =>
        'Открой план работы, чтобы увидеть шаги, помощников и инструменты.',
      _ActiveViewType.routePlan =>
        'Выбери план работы, AI-помощника или инструмент из AI-маршрута.',
      _ActiveViewType.session || _ActiveViewType.project =>
        'Продолжи задачу: открой быстрый план или подбери инструмент.',
      _ActiveViewType.empty => switch (mode) {
        _WorkMode.video =>
          'Опиши ролик: OS соберет сцены, shot plan и видео-инструменты.',
        _WorkMode.toolkit => 'Найди нейросеть и открой ее внутри OS.',
        _ => 'Опиши задачу внизу, чтобы собрать AI-маршрут.',
      },
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.arrow_forward_rounded,
          size: 14,
          color: Color(0xFFFFA07A),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD7D9DF),
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TinyTab extends StatelessWidget {
  const _TinyTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x24FF7A4D) : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0x44FF9A78) : const Color(0x10FFFFFF),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? const Color(0xFFFFA07A) : const Color(0xFF9CA1AD),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String type;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF8B8F9A)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7D828D),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              type,
              style: const TextStyle(
                color: Color(0xFF6F7480),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter({
    required this.onNavigate,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
  });

  final ValueChanged<AppDestination> onNavigate;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniIconButton(Icons.grid_view_rounded, () => onOpenTool('chatgpt')),
        _MiniIconButton(
          Icons.smart_toy_outlined,
          () => onOpenAgent('tool-router-agent'),
        ),
        _MiniIconButton(
          Icons.schema_outlined,
          () => onOpenWorkflow('ai-short-video-factory'),
        ),
        _MiniIconButton(
          Icons.tune_rounded,
          () => onNavigate(AppDestination.settings),
        ),
      ],
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton(this.icon, this.onTap);

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        color: const Color(0xFF8B8F9A),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B8F9A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFFE5E7EC), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow(this.label, this.icon);

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8B8F9A)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF8B8F9A), fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8B8F9A),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6F7480),
          fontSize: 10,
          height: 1.2,
        ),
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFC8CAD1),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
