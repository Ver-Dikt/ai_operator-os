import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai_operator_app.dart';
import '../data/seed_free_credits.dart';
import '../models/ai_agent.dart';
import '../models/ai_tool.dart';
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
        label: 'GPT Агенты',
        icon: Icons.smart_toy_outlined,
        title: 'Команда агентов',
        description:
            'Поставь задачу - OS подберет агентов, роли и ручные/автоматические шаги.',
        promptPlaceholder: 'Опиши задачу для команды агентов...',
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
          (label: 'Research brief', task: 'Собрать research brief по теме'),
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
        label: 'Дизайн',
        icon: Icons.auto_awesome_mosaic_outlined,
        title: 'Дизайн-студия',
        description: 'Изображения, обложки, постеры, брендинг, AI-инфлюенсеры.',
        promptPlaceholder: 'Опиши изображение, стиль, постер или обложку...',
        models: [
          'Midjourney',
          'ChatGPT Images',
          'Leonardo',
          'Ideogram',
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
          'leonardo',
          'ideogram',
          'freepik-ai',
          'comfyui',
        ],
        emptyStateHints: ['постер', 'обложка', 'референс'],
      ),
      _WorkMode.video => const _WorkModeConfig(
        label: 'Видео',
        icon: Icons.movie_creation_outlined,
        title: 'Видео-режиссер',
        description: 'Сцены, Reels, Shorts, image-to-video, cinematic prompts.',
        promptPlaceholder: 'Опиши сцену, ролик, Reels или видео-идею...',
        models: ['Kling', 'Runway', 'Pika', 'Veo / Flow', 'Luma', 'Sora'],
        settings: [
          _ModeSettingConfig('Формат', ['9:16', '16:9', '1:1']),
          _ModeSettingConfig('Длина', ['5 сек', '10 сек', '30 сек', '60 сек']),
          _ModeSettingConfig('Режим', [
            'Text-to-video',
            'Image-to-video',
            'Scene plan',
            'Batch shorts',
          ]),
          _ModeSettingConfig('Качество', ['Draft', 'Balanced', 'Pro']),
        ],
        quickActions: [
          (label: 'AI Reels', task: 'Сделать 10 Reels для трека'),
          (label: 'Сцена', task: 'Собрать cinematic AI scene builder'),
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
        emptyStateHints: ['сцена', 'кадр', 'монтаж'],
      ),
      _WorkMode.audio => const _WorkModeConfig(
        label: 'Аудио',
        icon: Icons.graphic_eq_rounded,
        title: 'Аудио-студия',
        description: 'Voiceover, музыка, озвучка, дубляж, транскрибация.',
        promptPlaceholder: 'Опиши голос, музыку, озвучку или аудио-задачу...',
        models: ['ElevenLabs', 'Suno', 'Udio', 'Stable Audio', 'Whisper'],
        settings: [
          _ModeSettingConfig('Тип', [
            'Voiceover',
            'Song idea',
            'Music promo',
            'Dubbing',
            'Transcription',
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
            label: 'Voiceover',
            task: 'Подготовить voiceover и инструменты озвучки',
          ),
          (label: 'Music promo', task: 'Продвинуть музыкальный релиз'),
          (label: 'Dubbing', task: 'Собрать workflow дубляжа видео'),
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
        label: 'Тул-кит',
        icon: Icons.grid_view_rounded,
        title: 'База нейросетей',
        description: 'Поиск, сравнение и подбор AI-инструментов под задачу.',
        promptPlaceholder: 'Какую нейросеть или инструмент ищем?',
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
            'Best quality',
          ]),
        ],
        quickActions: [
          (label: 'Free stack', task: 'Найти бесплатный AI stack под задачу'),
          (
            label: 'Сравнить',
            task: 'Сравнить платные и бесплатные AI инструменты',
          ),
          (label: 'Local', task: 'Подобрать локальные AI инструменты'),
        ],
        recommendedToolIds: [
          'chatgpt',
          'kling',
          'midjourney',
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
  String _historyTab = 'Сессии';
  String _model = _WorkMode.design.config.models.first;
  String _aspect = '9:16';
  String _quality = 'Balanced';

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
      _clearActiveIds();
    });
  }

  void _openWorkflow(String? id) {
    setState(() {
      _activeViewType = _ActiveViewType.workflow;
      _clearActiveIds();
      _activeWorkflowId = id;
    });
  }

  void _openAgent(String? id) {
    setState(() {
      _activeViewType = _ActiveViewType.agent;
      _clearActiveIds();
      _activeAgentId = id;
    });
  }

  void _openTool(String? id) {
    setState(() {
      _activeViewType = _ActiveViewType.tool;
      _clearActiveIds();
      _activeToolId = id;
    });
  }

  void _openUseCase(String? id) {
    setState(() {
      _activeViewType = _ActiveViewType.useCase;
      _clearActiveIds();
      _activeUseCaseId = id;
    });
  }

  void _openSessionSummary(String title, String subtitle) {
    setState(() {
      _activeViewType = _ActiveViewType.session;
      _clearActiveIds();
      _activeSummaryTitle = title;
      _activeSummarySubtitle = subtitle;
    });
  }

  void _openProjectSummary(String title, String subtitle) {
    setState(() {
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
      _clearActiveIds();
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
      _model = 'Auto Router';
      _aspect = '9:16';
      _quality = 'Balanced';
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
          height: 420,
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
                  _ModeTabs(mode: mode, onMode: onMode),
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
  const _ModeTabs({required this.mode, required this.onMode});

  final _WorkMode mode;
  final ValueChanged<_WorkMode> onMode;

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
                    horizontal: 13,
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
                      fontSize: 12,
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onNewSession,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Новая сессия'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onOpenProject(
                      'Новый проект',
                      'Проект: постоянная работа с сессиями, сценариями и результатами',
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
                    'Найти сессию, проект, агент, сценарий или инструмент...',
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
                for (final item in ['Сессии', 'Проекты', 'Избранное'])
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
            if (tab == 'Сессии') ...[
              const _PanelLabel('ТЕКУЩАЯ СЕССИЯ'),
              _HistoryItem(
                title: '10 Reels для трека',
                subtitle: 'активная сессия',
                type: 'сессия',
                icon: Icons.bolt_rounded,
                onTap: () => onOpenSession(
                  '10 Reels для трека',
                  'Активная сессия: workflow, агенты и инструменты остаются внутри Workstation',
                ),
              ),
              const SizedBox(height: 14),
              const _PanelLabel('ПОСЛЕДНИЕ СЕССИИ'),
              _HistoryItem(
                title: 'AI-фриланс разведка',
                subtitle: 'сессия',
                type: 'сессия',
                icon: Icons.manage_search_rounded,
                onTap: () => onOpenUseCase('find-ai-freelance-jobs'),
              ),
              _HistoryItem(
                title: 'Оживление фото',
                subtitle: 'сессия',
                type: 'сессия',
                icon: Icons.photo_library_outlined,
                onTap: () => onOpenUseCase('restore-old-photos-service'),
              ),
              _HistoryItem(
                title: 'Локализация видео',
                subtitle: 'сессия',
                type: 'сессия',
                icon: Icons.subtitles_outlined,
                onTap: () => onOpenUseCase('video-localization'),
              ),
              const SizedBox(height: 14),
              const _PanelLabel('СЦЕНАРИИ - ГОТОВЫЕ МАРШРУТЫ'),
              _HistoryItem(
                title: 'AI Short Video Factory',
                subtitle: 'сценарий',
                type: 'сценарий',
                icon: Icons.schema_outlined,
                onTap: () => onOpenWorkflow('ai-short-video-factory'),
              ),
              _HistoryItem(
                title: 'Music Promo Pack',
                subtitle: 'сценарий',
                type: 'сценарий',
                icon: Icons.queue_music_outlined,
                onTap: () => onOpenWorkflow('music-release-promo-pack'),
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
                  'Постоянный проект: сессии, сценарии и результаты',
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
              const _PanelLabel('АГЕНТЫ'),
              _HistoryItem(
                title: 'Агент-режиссер',
                subtitle: 'агент',
                type: 'агент',
                icon: Icons.smart_toy_outlined,
                onTap: () => onOpenAgent('director-agent'),
              ),
              const SizedBox(height: 10),
              const _PanelLabel('СЦЕНАРИИ'),
              _HistoryItem(
                title: 'AI Short Video Factory',
                subtitle: 'сценарий',
                type: 'сценарий',
                icon: Icons.schema_outlined,
                onTap: () => onOpenWorkflow('ai-short-video-factory'),
              ),
              const SizedBox(height: 10),
              const _PanelLabel('ИНСТРУМЕНТЫ'),
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
    final sessionName = recommendation?.task ?? 'Новая рабочая сессия';
    final activeWork = switch (activeViewType) {
      _ActiveViewType.empty => 'без активного объекта',
      _ActiveViewType.routePlan => 'AI-маршрут',
      _ActiveViewType.workflow => 'workflow открыт',
      _ActiveViewType.agent => 'агент активен',
      _ActiveViewType.tool => 'инструмент открыт',
      _ActiveViewType.useCase => 'кейс открыт',
      _ActiveViewType.session => 'сессия открыта',
      _ActiveViewType.project => 'проект открыт',
    };
    final status = switch (activeViewType) {
      _ActiveViewType.empty => 'draft',
      _ActiveViewType.routePlan => 'planning',
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
            Text(
              mode.title,
              style: const TextStyle(
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
                hintText: 'Найти нейросеть...',
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
                _SoftBadge('Free'),
                _SoftBadge('Has API'),
                _SoftBadge('Local'),
                _SoftBadge('No card'),
                _SoftBadge('Best quality'),
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
            child: const Text('Открыть внутри OS'),
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
            _RouteLine('Сценарий', recommendation.recommendedWorkflow),
            _RouteLine('Агенты', agents.map((item) => item.name).join(' / ')),
            _RouteLine(
              'Инструменты',
              tools.map((item) => item.name).join(' / '),
            ),
            _RouteLine(
              'Следующие шаги',
              recommendation.manualSteps.take(3).join(' → '),
            ),
            const SizedBox(height: 8),
            const Text(
              'Сейчас OS работает в ручном режиме: она собирает маршрут, промпты и инструменты. На следующих этапах мы подключим OpenAI API, Ollama и автоматические агенты.',
              style: TextStyle(
                color: Color(0xFF8B8F9A),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => onOpenWorkflow(recommendation.workflowId),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Открыть сценарий'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpenAgent(firstAgentId),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Агент'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpenTool(firstToolId),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Тул-кит'),
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
      ),
      _ActiveViewType.session || _ActiveViewType.project => _SummaryStage(
        title: activeSummaryTitle ?? 'Рабочая область',
        subtitle:
            activeSummarySubtitle ??
            'Здесь будут сессии, сценарии, агенты, инструменты и результаты.',
        type: activeViewType == _ActiveViewType.session ? 'сессия' : 'проект',
        onOpenWorkflow: onOpenWorkflow,
        onOpenUseCase: onOpenUseCase,
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
  });

  final WorkflowTemplate? workflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    if (workflow == null) {
      return const _MissingEntityStage('Сценарий не найден');
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
              const _PanelLabel('АКТИВНЫЙ СЦЕНАРИЙ'),
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
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _SoftBadge(workflow!.category),
                  _SoftBadge(workflow!.estimatedTime),
                  _SoftBadge(workflow!.automationLevel.name),
                  _SoftBadge(workflow!.monetizationPotential.name),
                ],
              ),
              const SizedBox(height: 18),
              for (final step in workflow!.steps.take(5))
                _StageStep(step: step, onOpenTool: onOpenTool),
              const SizedBox(height: 12),
              _LinkedNames(
                title: 'Агенты',
                names: agents.map((item) => item.name).toList(),
              ),
              _LinkedNames(
                title: 'Инструменты',
                names: tools.map((item) => item.name).toList(),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Сценарий запущен в ручном режиме'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Начать'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copyText(context, firstPrompt),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Скопировать промпт'),
                  ),
                  OutlinedButton.icon(
                    onPressed: tools.isEmpty
                        ? null
                        : () => onOpenTool(tools.first.id),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Открыть инструмент'),
                  ),
                  OutlinedButton.icon(
                    onPressed: agents.isEmpty
                        ? null
                        : () => onOpenAgent(agents.first.id),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Агент'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Сохранено в проект')),
                      );
                    },
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Сохранить'),
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
  });

  final AiAgent? agent;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenTool;

  @override
  Widget build(BuildContext context) {
    if (agent == null) return const _MissingEntityStage('Агент не найден');

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
            const _PanelLabel('АКТИВНЫЙ АГЕНТ'),
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
                _SoftBadge(agent!.status.name),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              agent!.description,
              style: const TextStyle(color: Color(0xFFE5E7EC), height: 1.35),
            ),
            const SizedBox(height: 16),
            _LinkedNames(
              title: 'Инструменты агента',
              names: tools.map((item) => item.name).toList(),
            ),
            _LinkedNames(
              title: 'Сценарии',
              names: workflows.map((item) => item.title).toList(),
            ),
            const SizedBox(height: 14),
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
                        content: Text('${agent!.name}: mock output готов'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Назначить задачу'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyText(context, agent!.systemPrompt),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Промпт агента'),
                ),
                OutlinedButton.icon(
                  onPressed: tools.isEmpty
                      ? null
                      : () => onOpenTool(tools.first.id),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Инструмент'),
                ),
                OutlinedButton.icon(
                  onPressed: workflows.isEmpty
                      ? null
                      : () => onOpenWorkflow(workflows.first.id),
                  icon: const Icon(Icons.schema_outlined),
                  label: const Text('Сценарий'),
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
  });

  final AiTool? tool;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenWorkflow;

  @override
  Widget build(BuildContext context) {
    if (tool == null) return const _MissingEntityStage('Инструмент не найден');

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
            const _PanelLabel('АКТИВНЫЙ ИНСТРУМЕНТ'),
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _SoftBadge(tool!.category.label),
                _SoftBadge(tool!.pricingType.label),
                _SoftBadge(tool!.integrationType.label),
                if (tool!.isLocal) const _SoftBadge('local'),
              ],
            ),
            const SizedBox(height: 16),
            _RouteLine('Лучше для', tool!.bestFor),
            _RouteLine('Бесплатно', tool!.freeCreditsInfo),
            _RouteLine('Ограничения', tool!.limitations),
            _LinkedNames(
              title: 'Агенты',
              names: agents.map((item) => item.name).toList(),
            ),
            _LinkedNames(
              title: 'Сценарии',
              names: workflows.map((item) => item.title).toList(),
            ),
            const SizedBox(height: 14),
            const _ManualModeBox(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => const UrlService().open(tool!.url),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Открыть сайт'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyText(context, prompt),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать промпт'),
                ),
                OutlinedButton.icon(
                  onPressed: agents.isEmpty
                      ? null
                      : () => onOpenAgent(agents.first.id),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Агент'),
                ),
                OutlinedButton.icon(
                  onPressed: workflows.isEmpty
                      ? null
                      : () => onOpenWorkflow(workflows.first.id),
                  icon: const Icon(Icons.schema_outlined),
                  label: const Text('Сценарий'),
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
  });

  final UseCase? useCase;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;

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
                _SoftBadge(useCase!.monetizationPotential.name),
                _SoftBadge(
                  useCase!.requiresHumanReview ? 'human review' : 'assisted',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LinkedNames(
              title: 'Сценарии',
              names: workflows.map((item) => item.title).toList(),
            ),
            _LinkedNames(
              title: 'Агенты',
              names: agents.map((item) => item.name).toList(),
            ),
            _LinkedNames(
              title: 'Инструменты',
              names: tools.map((item) => item.name).toList(),
            ),
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
                  label: const Text('Открыть сценарий'),
                ),
                OutlinedButton.icon(
                  onPressed: agents.isEmpty
                      ? null
                      : () => onOpenAgent(agents.first.id),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Агент'),
                ),
                OutlinedButton.icon(
                  onPressed: tools.isEmpty
                      ? null
                      : () => onOpenTool(tools.first.id),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Инструмент'),
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
  });

  final String title;
  final String subtitle;
  final String type;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenUseCase;

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
                  label: const Text('Открыть сценарий'),
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

class _LinkedNames extends StatelessWidget {
  const _LinkedNames({required this.title, required this.names});

  final String title;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _RouteLine(title, names.take(4).join(' / ')),
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
        'Демо-режим: OS готовит маршрут, ссылки и промпты. API и Local подключим позже без перестройки рабочего экрана.',
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
            title: config.showModelSelector
                ? 'Параметры режима: ${config.label}'
                : 'Фильтры инструментов',
            trailing: TextButton(
              onPressed: onReset,
              child: const Text('Сброс'),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        onPressed: () =>
                            onOpenTool(_firstOrNull(config.recommendedToolIds)),
                        icon: const Icon(Icons.grid_view_rounded, size: 16),
                        label: const Text('Открыть подборку'),
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
          _SettingsGroup(title: 'Контекст режима', child: _ModeContext(mode)),
          _SettingsGroup(
            title: 'Выполнение',
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
            title: 'Статус',
            child: Column(
              children: [
                _MetaLine('Режим', settings.operatorMode.name),
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
                  child: const Text('Сценарий'),
                ),
              ),
            ],
          ),
        ],
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
      width: width,
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
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(item)),
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
            'Сценарий',
      _ActiveViewType.agent =>
        _firstOrNull(
              graph.agentsByIds([activeAgentId ?? 'tool-router-agent']),
            )?.name ??
            'Агент',
      _ActiveViewType.tool =>
        _firstOrNull(graph.toolsByIds([activeToolId ?? 'chatgpt']))?.name ??
            'Инструмент',
      _ActiveViewType.useCase =>
        _firstOrNull(
              graph.useCasesByIds([
                activeUseCaseId ?? 'make-10-reels-for-track',
              ]),
            )?.title ??
            'Кейс',
      _ActiveViewType.routePlan => 'AI-маршрут',
      _ActiveViewType.session => 'Сессия',
      _ActiveViewType.project => 'Проект',
      _ActiveViewType.empty => 'Настройки режима',
    };
    final rows = switch (activeViewType) {
      _ActiveViewType.workflow => const [
        ('Настройки сценария', Icons.schema_outlined),
        ('Ручное выполнение', Icons.touch_app_outlined),
        ('Сохранить результаты', Icons.bookmark_add_outlined),
      ],
      _ActiveViewType.agent => const [
        ('Задача агента', Icons.smart_toy_outlined),
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
      title: 'Активный контекст',
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
        ('План сцены', Icons.movie_creation_outlined),
        ('Ручной рендер', Icons.open_in_new_rounded),
      ],
      _WorkMode.audio => const [
        ('Голосовая модель', Icons.record_voice_over_outlined),
        ('Музыкальное настроение', Icons.graphic_eq_rounded),
        ('Дубляж', Icons.subtitles_outlined),
      ],
      _WorkMode.toolkit => const [
        ('Free/pro/local', Icons.route_outlined),
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
