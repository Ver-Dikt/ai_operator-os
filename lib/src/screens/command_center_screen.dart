import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai_operator_app.dart';
import '../data/seed_free_credits.dart';
import '../models/ai_agent.dart';
import '../models/ai_tool.dart';
import '../models/execution_mode.dart';
import '../models/monetization.dart';
import '../models/route_plan.dart';
import '../models/routing_recommendation.dart';
import '../models/use_case.dart';
import '../models/workflow_template.dart';
import '../models/workspace_memory.dart';
import '../services/graph_repository.dart';
import '../services/router_service.dart';
import '../services/storage_service.dart';
import '../services/tool_launcher_service.dart';
import '../state/app_settings.dart';

enum _WorkMode { agents, text, design, video, audio, toolkit }

enum _ActiveViewType {
  empty,
  routePlan,
  creativeSession,
  workflow,
  agent,
  tool,
  useCase,
  session,
  project,
}

T? _firstOrNull<T>(List<T> items) => items.isEmpty ? null : items.first;

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

String _formatSessionTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

IconData _routeIcon(String key) {
  return switch (key) {
    'script' => Icons.article_outlined,
    'storyboard' => Icons.view_timeline_outlined,
    'video' => Icons.movie_creation_outlined,
    'edit' => Icons.cut_rounded,
    'audio' => Icons.graphic_eq_rounded,
    'export' => Icons.ios_share_rounded,
    'image' => Icons.image_outlined,
    'prompt' => Icons.text_fields_rounded,
    'research' => Icons.manage_search_rounded,
    'send' => Icons.send_outlined,
    'qa' => Icons.fact_check_outlined,
    'automation' => Icons.account_tree_outlined,
    'nodes' => Icons.hub_outlined,
    'api' => Icons.api_rounded,
    'local' => Icons.dns_outlined,
    'route' => Icons.route_outlined,
    _ => Icons.auto_awesome_rounded,
  };
}

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

class _TaskSession {
  const _TaskSession({
    required this.title,
    required this.mode,
    required this.route,
    required this.timestamp,
  });

  final String title;
  final String mode;
  final RoutePlan route;
  final DateTime timestamp;
}

class _CreativeSession {
  const _CreativeSession({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.outputTitle,
    required this.output,
    required this.sections,
    required this.promptBlocks,
    required this.timestamp,
  });

  final _WorkMode mode;
  final String title;
  final String subtitle;
  final String outputTitle;
  final String output;
  final List<({String title, String value})> sections;
  final List<String> promptBlocks;
  final DateTime timestamp;
}

Future<void> _copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Скопировано в буфер')));
}

Future<void> _launchToolWebsite(BuildContext context, AiTool tool) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Подготовка prompt bundle для ${tool.name}...')),
  );
  await const ToolLauncherService().openExternalTool(tool);
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
        promptPlaceholder: 'Опиши задачу, и OS построит AI-маршрут',
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
        promptPlaceholder: '',
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
  final FocusNode _shortcutFocusNode = FocusNode();
  _WorkMode _mode = _WorkMode.design;
  RoutePlan? _routePlan;
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
  _TaskSession? _currentTaskSession;
  final Map<_WorkMode, _CreativeSession> _creativeSessions = {};
  final StorageService _storage = const StorageService();
  final ToolLauncherService _toolLauncher = const ToolLauncherService();
  List<WorkspaceSession> _memorySessions = const [];
  List<MemoryProject> _memoryProjects = const [];
  String? _activeSessionId;
  ExecutionMode _executionMode = ExecutionMode.manual;

  @override
  void initState() {
    super.initState();
    _loadMemory();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _shortcutFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMemory() async {
    final sessions = await _storage.loadSessions();
    final projects = await _storage.loadProjects();
    if (!mounted) return;
    setState(() {
      _memorySessions = sessions;
      _memoryProjects = projects;
      _activeSessionId = sessions.isEmpty ? null : sessions.first.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _closeActiveWork,
      },
      child: KeyboardListener(
        autofocus: true,
        focusNode: _shortcutFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _closeActiveWork();
          }
        },
        child: Scaffold(
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
                      routePlan: _routePlan,
                      recommendation: _recommendation,
                      creativeSession: _creativeSessions[_mode],
                      currentTaskSession: _currentTaskSession,
                      sessions: _memorySessions,
                      projects: _memoryProjects,
                      activeSessionId: _activeSessionId,
                      executionMode: _executionMode,
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
                      onCloseActive: _closeActiveWork,
                      onSaveToProject: _saveActiveSessionToProject,
                      onWorkspaceExecution: _handleWorkspaceExecution,
                      onOpenWorkflow: _openWorkflow,
                      onOpenAgent: _openAgent,
                      onOpenTool: _openTool,
                      onOpenUseCase: _openUseCase,
                      onOpenSession: _openSessionById,
                      onOpenProject: _openProjectById,
                      onCreateProject: _createProjectFromActiveSession,
                      onToggleSessionPinned: _toggleSessionPinned,
                      onToggleSessionFavorite: _toggleSessionFavorite,
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
                      routePlan: _routePlan,
                      recommendation: _recommendation,
                      creativeSession: _creativeSessions[_mode],
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
                      executionMode: _executionMode,
                      onMode: _switchMode,
                      onSubmit: _buildPlan,
                      onQuickGoal: _quickGoal,
                      onCloseActive: _closeActiveWork,
                      onSaveToProject: _saveActiveSessionToProject,
                      onWorkspaceExecution: _handleWorkspaceExecution,
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
      _activeViewType = switch (mode) {
        _WorkMode.agents =>
          _routePlan == null
              ? _ActiveViewType.empty
              : _ActiveViewType.routePlan,
        _WorkMode.toolkit => _ActiveViewType.empty,
        _ =>
          _creativeSessions[mode] == null
              ? _ActiveViewType.empty
              : _ActiveViewType.creativeSession,
      };
      _activeViewHistory.clear();
      _clearActiveIds();
    });
  }

  void _buildPlan() {
    final task = _taskController.text.trim().isEmpty
        ? _defaultTaskForMode(_mode)
        : _taskController.text.trim();
    WorkspaceSession? sessionToSave;
    setState(() {
      if (_mode == _WorkMode.toolkit) {
        _activeViewType = _ActiveViewType.empty;
      } else if (_mode == _WorkMode.agents) {
        final router = const RouterService();
        _routePlan = router.buildRoutePlan(task);
        _recommendation = router.recommend(task);
        _currentTaskSession = _TaskSession(
          title: _routePlan!.title,
          mode: _routePlan!.recommendedMode,
          route: _routePlan!,
          timestamp: DateTime.now(),
        );
        sessionToSave = _routeSessionFromPlan(_routePlan!, task);
        _historyTab = 'Задачи';
        _activeViewType = _ActiveViewType.routePlan;
      } else {
        final creativeSession = _buildCreativeSession(_mode, task);
        _creativeSessions[_mode] = creativeSession;
        sessionToSave = _memorySessionFromCreative(creativeSession, task);
        _activeViewType = _ActiveViewType.creativeSession;
      }
      _activeViewHistory.clear();
      _clearActiveIds();
    });
    if (sessionToSave != null) {
      _upsertMemorySession(sessionToSave!);
    }
  }

  String _defaultTaskForMode(_WorkMode mode) {
    return switch (mode) {
      _WorkMode.agents => 'Собрать AI-сценарий',
      _WorkMode.text => 'Написать и улучшить текст',
      _WorkMode.design => 'Создать image prompt',
      _WorkMode.video => 'Создать cinematic scene prompt',
      _WorkMode.audio => 'Создать audio prompt',
      _WorkMode.toolkit => '',
    };
  }

  _CreativeSession _buildCreativeSession(_WorkMode mode, String task) {
    final now = DateTime.now();
    return switch (mode) {
      _WorkMode.text => _CreativeSession(
        mode: mode,
        title: 'Text Workspace',
        subtitle: 'AI writer / research station / prompt lab',
        outputTitle: 'Черновик ответа',
        output:
            'Готовый рабочий черновик по запросу: "$task".\n\nСтруктура: тезис, основной текст, уточнения, финальная версия. Можно продолжать писать, сокращать, переписывать или превращать в промпт.',
        sections: const [
          (title: 'Фокус', value: 'ясность, структура, стиль'),
          (title: 'Формат', value: 'пост / brief / research / rewrite'),
          (
            title: 'Следующий шаг',
            value: 'уточнить тон или попросить варианты',
          ),
        ],
        promptBlocks: [
          'Rewrite: улучши текст про "$task" без потери смысла.',
          'Research: собери краткий обзор, риски и вопросы по теме "$task".',
          'Prompt lab: преврати "$task" в точный production prompt.',
        ],
        timestamp: now,
      ),
      _WorkMode.design => _CreativeSession(
        mode: mode,
        title: 'Image Prompt Workspace',
        subtitle: 'composition / style / lighting / model-ready prompt',
        outputTitle: 'Image prompt blocks',
        output:
            'Subject: $task\nStyle: cinematic, polished, intentional\nComposition: strong focal point, clean silhouette, readable negative space\nLighting: controlled key light, soft contrast, practical highlights\nNegative prompt: clutter, random details, bad hands, warped text',
        sections: const [
          (
            title: 'Композиция',
            value: 'главный объект, фон, глубина, safe zones',
          ),
          (title: 'Свет', value: 'key light, rim light, мягкий контраст'),
          (title: 'Референсы', value: 'стиль, объект, палитра, материал'),
        ],
        promptBlocks: [
          'Midjourney: $task, cinematic composition, refined lighting, clean background',
          'Product shot: $task, premium studio light, sharp focus, commercial detail',
          'Thumbnail: $task, bold readable subject, high contrast, simple layout',
        ],
        timestamp: now,
      ),
      _WorkMode.video => _CreativeSession(
        mode: mode,
        title: 'Video Production Workspace',
        subtitle: 'scene prompt / shot breakdown / camera logic',
        outputTitle: 'Scene prompt',
        output:
            'Scene: $task\nCamera: motivated slow movement, stable framing, no random zoom\nVisual beat: establish space, reveal tension, end on a clear gesture\nLight: cinematic practical light, atmospheric depth\nNegative prompt: overcutting, shaky camera, incoherent motion, glossy stock look',
        sections: const [
          (
            title: 'Shot breakdown',
            value: 'wide establishing, medium action, close final gesture',
          ),
          (title: 'Camera', value: 'движение только по драматической причине'),
          (title: 'Sequence', value: 'hook, build, visual turn, final frame'),
        ],
        promptBlocks: [
          'Kling/Veo: $task, cinematic scene, stable camera, motivated motion',
          'Storyboard: разбей "$task" на 5 визуальных кадров.',
          'Music sync: подгони движение сцены "$task" под музыкальный акцент.',
        ],
        timestamp: now,
      ),
      _WorkMode.audio => _CreativeSession(
        mode: mode,
        title: 'Audio Workspace',
        subtitle: 'voiceover / music prompt / dubbing / sound design',
        outputTitle: 'Audio prompt',
        output:
            'Audio idea: $task\nVoice: clear, intimate, controlled dynamics\nMusic: restrained pulse, warm texture, emotional lift\nStructure: intro cue, main phrase, pause, final resolve\nNotes: keep noise low, avoid overcompressed sound.',
        sections: const [
          (title: 'Voice style', value: 'тембр, темп, эмоция, язык'),
          (
            title: 'Music references',
            value: 'жанр, ритм, инструменты, настроение',
          ),
          (title: 'Sound design', value: 'атмосфера, паузы, переходы'),
        ],
        promptBlocks: [
          'Voiceover: озвучь "$task" спокойным cinematic tone.',
          'Music prompt: $task, sparse pulse, warm analog texture, emotional build.',
          'Dubbing: адаптируй "$task" под EN/RU voiceover с естественным темпом.',
        ],
        timestamp: now,
      ),
      _ => _CreativeSession(
        mode: mode,
        title: 'Workspace',
        subtitle: 'рабочая сессия',
        outputTitle: 'Результат',
        output: task,
        sections: const [],
        promptBlocks: const [],
        timestamp: now,
      ),
    };
  }

  WorkspaceSession _memorySessionFromCreative(
    _CreativeSession session,
    String task,
  ) {
    final existing = _activeSessionForMode(session.mode);
    final now = DateTime.now();
    return WorkspaceSession(
      id: existing?.id ?? _newMemoryId('session'),
      title: _compactTitle(task, fallback: session.title),
      type: _sessionTypeForMode(session.mode),
      category: session.mode.label,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      preview: session.subtitle,
      workspaceType: session.mode.name,
      pinned: existing?.pinned ?? false,
      favorite: existing?.favorite ?? false,
      promptBlocks: session.promptBlocks,
      output: session.output,
      openedTools: existing?.openedTools ?? const [],
      generatedPrompts: existing?.generatedPrompts ?? [session.output],
      launchedFlows: existing?.launchedFlows ?? const [],
      copiedPrompts: existing?.copiedPrompts ?? const [],
      usedHelpers: existing?.usedHelpers ?? const [],
      workflowIds: existing?.workflowIds ?? const [],
      routeSeed: task,
      projectId: existing?.projectId,
    );
  }

  WorkspaceSession _routeSessionFromPlan(RoutePlan plan, String task) {
    final existing = _activeSessionId == null
        ? null
        : _sessionById(_activeSessionId!);
    final now = DateTime.now();
    return WorkspaceSession(
      id: existing?.id ?? _newMemoryId('route'),
      title: plan.title,
      type: WorkspaceSessionType.workflow,
      category: plan.routeType,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      preview: plan.detectedGoal,
      workspaceType: _WorkMode.agents.name,
      pinned: true,
      favorite: existing?.favorite ?? false,
      promptBlocks: plan.promptSuggestions,
      output: plan.steps.map((step) => step.title).join(' → '),
      openedTools: plan.toolIds,
      generatedPrompts: existing?.generatedPrompts ?? plan.promptSuggestions,
      launchedFlows: existing?.launchedFlows ?? const [],
      copiedPrompts: existing?.copiedPrompts ?? const [],
      usedHelpers: plan.agentIds,
      workflowIds: plan.workflowIds,
      routeSeed: task,
      projectId: existing?.projectId,
    );
  }

  WorkspaceSession? _activeSessionForMode(_WorkMode mode) {
    if (_activeSessionId == null) return null;
    final session = _sessionById(_activeSessionId!);
    if (session?.workspaceType == mode.name) return session;
    return null;
  }

  WorkspaceSession? _sessionById(String id) {
    for (final session in _memorySessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  WorkspaceSessionType _sessionTypeForMode(_WorkMode mode) {
    return switch (mode) {
      _WorkMode.text => WorkspaceSessionType.text,
      _WorkMode.design => WorkspaceSessionType.image,
      _WorkMode.video => WorkspaceSessionType.video,
      _WorkMode.audio => WorkspaceSessionType.audio,
      _WorkMode.agents => WorkspaceSessionType.workflow,
      _WorkMode.toolkit => WorkspaceSessionType.workflow,
    };
  }

  String _newMemoryId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _compactTitle(String value, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length <= 36 ? trimmed : '${trimmed.substring(0, 36)}...';
  }

  void _openWorkflow(String? id) {
    final workflow = _firstOrNull(
      const GraphRepository().workflowsByIds([id ?? 'ai-short-video-factory']),
    );
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.workflow;
      _clearActiveIds();
      _activeWorkflowId = id;
    });
    if (workflow != null) {
      _upsertMemorySession(
        _entityMemorySession(
          title: workflow.title,
          preview: workflow.description,
          type: WorkspaceSessionType.workflow,
          category: 'план работы',
          entityId: workflow.id,
          workflowIds: [workflow.id],
        ),
      );
    }
  }

  void _openAgent(String? id) {
    final agent = _firstOrNull(
      const GraphRepository().agentsByIds([id ?? 'tool-router-agent']),
    );
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.agent;
      _clearActiveIds();
      _activeAgentId = id;
    });
    if (agent != null) {
      _upsertMemorySession(
        _entityMemorySession(
          title: agent.name,
          preview: agent.role,
          type: WorkspaceSessionType.helper,
          category: 'AI-помощник',
          entityId: agent.id,
          usedHelpers: [agent.id],
        ),
      );
    }
  }

  void _openTool(String? id) {
    final tool = _firstOrNull(
      const GraphRepository().toolsByIds([id ?? 'chatgpt']),
    );
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.tool;
      _clearActiveIds();
      _activeToolId = id;
    });
    if (tool != null) {
      _touchActiveSession(openedToolId: tool.id);
    }
  }

  void _openUseCase(String? id) {
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.useCase;
      _clearActiveIds();
      _activeUseCaseId = id;
    });
  }

  WorkspaceSession _entityMemorySession({
    required String title,
    required String preview,
    required WorkspaceSessionType type,
    required String category,
    required String entityId,
    List<String> workflowIds = const [],
    List<String> usedHelpers = const [],
  }) {
    final existing = _firstWhereOrNull(
      _memorySessions,
      (session) => session.entityId == entityId && session.type == type,
    );
    final now = DateTime.now();
    return WorkspaceSession(
      id: existing?.id ?? _newMemoryId(type.name),
      title: title,
      type: type,
      category: category,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      preview: preview,
      workspaceType: type == WorkspaceSessionType.helper
          ? _WorkMode.agents.name
          : _WorkMode.agents.name,
      pinned: existing?.pinned ?? false,
      favorite: existing?.favorite ?? false,
      promptBlocks: existing?.promptBlocks ?? const [],
      output: preview,
      openedTools: existing?.openedTools ?? const [],
      generatedPrompts: existing?.generatedPrompts ?? const [],
      launchedFlows: existing?.launchedFlows ?? const [],
      copiedPrompts: existing?.copiedPrompts ?? const [],
      usedHelpers: usedHelpers,
      workflowIds: workflowIds,
      entityId: entityId,
      projectId: existing?.projectId,
    );
  }

  void _openSessionById(String id) {
    final session = _sessionById(id);
    if (session == null) return;
    setState(() {
      _activeSessionId = session.id;
      _taskController.text = session.routeSeed ?? session.title;
      _activeViewHistory.clear();
      _clearActiveIds();
      if (session.type == WorkspaceSessionType.workflow &&
          session.workflowIds.isNotEmpty) {
        _mode = _WorkMode.agents;
        _activeViewType = _ActiveViewType.workflow;
        _activeWorkflowId = session.workflowIds.first;
      } else if (session.type == WorkspaceSessionType.helper &&
          session.usedHelpers.isNotEmpty) {
        _mode = _WorkMode.agents;
        _activeViewType = _ActiveViewType.agent;
        _activeAgentId = session.usedHelpers.first;
      } else if (session.workspaceType == _WorkMode.agents.name) {
        _mode = _WorkMode.agents;
        final router = const RouterService();
        _routePlan = router.buildRoutePlan(session.routeSeed ?? session.title);
        _recommendation = router.recommend(session.routeSeed ?? session.title);
        _currentTaskSession = _TaskSession(
          title: session.title,
          mode: _routePlan!.recommendedMode,
          route: _routePlan!,
          timestamp: session.updatedAt,
        );
        _activeViewType = _ActiveViewType.routePlan;
      } else {
        final restoredMode = _modeFromSession(session);
        _mode = restoredMode;
        _creativeSessions[restoredMode] = _creativeSessionFromMemory(session);
        _activeViewType = _ActiveViewType.creativeSession;
      }
      _historyTab = 'Задачи';
    });
    _touchSession(id);
  }

  void _openProjectById(String id) {
    final project = _firstWhereOrNull(
      _memoryProjects,
      (project) => project.id == id,
    );
    if (project == null) return;
    setState(() {
      _rememberActiveState();
      _activeViewType = _ActiveViewType.project;
      _clearActiveIds();
      _activeSummaryTitle = project.title;
      _activeSummarySubtitle =
          '${project.description}\n${project.sessionIds.length} сессий • updated ${_formatSessionTime(project.updatedAt)}';
      _historyTab = 'Проекты';
    });
  }

  _WorkMode _modeFromSession(WorkspaceSession session) {
    return _WorkMode.values.firstWhere(
      (mode) => mode.name == session.workspaceType,
      orElse: () {
        return switch (session.type) {
          WorkspaceSessionType.text => _WorkMode.text,
          WorkspaceSessionType.image => _WorkMode.design,
          WorkspaceSessionType.video => _WorkMode.video,
          WorkspaceSessionType.audio => _WorkMode.audio,
          WorkspaceSessionType.helper ||
          WorkspaceSessionType.workflow => _WorkMode.agents,
        };
      },
    );
  }

  _CreativeSession _creativeSessionFromMemory(WorkspaceSession session) {
    final mode = _modeFromSession(session);
    return _CreativeSession(
      mode: mode,
      title: session.title,
      subtitle: 'Восстановлено из памяти OS • ${session.category}',
      outputTitle: 'Сохраненный результат',
      output: session.output.isEmpty ? session.preview : session.output,
      sections: [
        (
          title: 'Memory',
          value:
              'created ${_formatSessionTime(session.createdAt)}, updated ${_formatSessionTime(session.updatedAt)}',
        ),
        (title: 'Project', value: session.projectId ?? 'не назначен'),
        (
          title: 'Opened tools',
          value: session.openedTools.isEmpty
              ? 'пока нет'
              : session.openedTools.join(', '),
        ),
        (
          title: 'Execution history',
          value: session.launchedFlows.isEmpty
              ? 'новый runtime flow'
              : session.launchedFlows.take(2).join(' / '),
        ),
      ],
      promptBlocks: session.promptBlocks,
      timestamp: session.updatedAt,
    );
  }

  void _newSession() {
    setState(() {
      _taskController.clear();
      if (_mode == _WorkMode.agents) {
        _routePlan = null;
        _recommendation = null;
        _currentTaskSession = null;
      } else if (_mode != _WorkMode.toolkit) {
        _creativeSessions.remove(_mode);
      }
      _activeViewType = _ActiveViewType.empty;
      _activeViewHistory.clear();
      _clearActiveIds();
    });
  }

  void _upsertMemorySession(WorkspaceSession session) {
    final next = [
      session,
      ..._memorySessions.where((item) => item.id != session.id),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    setState(() {
      _memorySessions = next.take(60).toList();
      _activeSessionId = session.id;
    });
    _storage.saveSessions(_memorySessions);
  }

  void _touchSession(String id) {
    final session = _sessionById(id);
    if (session == null) return;
    _upsertMemorySession(session.copyWith(updatedAt: DateTime.now()));
  }

  void _touchActiveSession({String? openedToolId}) {
    if (_activeSessionId == null) return;
    final session = _sessionById(_activeSessionId!);
    if (session == null) return;
    final tools = [...session.openedTools];
    if (openedToolId != null && !tools.contains(openedToolId)) {
      tools.insert(0, openedToolId);
    }
    _upsertMemorySession(
      session.copyWith(
        updatedAt: DateTime.now(),
        openedTools: tools.take(8).toList(),
      ),
    );
  }

  Future<void> _handleWorkspaceExecution(
    _WorkspaceActionSpec action,
    String prompt,
  ) async {
    final nextMode = action.toolId != null
        ? ExecutionMode.browserLaunch
        : action.copyOutput
        ? ExecutionMode.manual
        : ExecutionMode.manual;
    setState(() => _executionMode = nextMode);

    if (action.copyOutput) {
      await _toolLauncher.copyPrompt(prompt);
      _recordExecutionHistory(copiedPrompt: prompt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Final production prompt скопирован')),
      );
      return;
    }

    if (action.toolId != null) {
      final tool = _firstOrNull(
        const GraphRepository().toolsByIds([action.toolId!]),
      );
      if (tool != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Открытие ${tool.name}... prompt уже в буфере'),
          ),
        );
        await _toolLauncher.continueInTool(tool, prompt);
        _recordExecutionHistory(
          openedToolId: tool.id,
          launchedFlow: '${action.label} → ${tool.name}',
          generatedPrompt: prompt,
        );
      } else {
        _recordExecutionHistory(launchedFlow: action.label);
      }
      return;
    }

    _recordExecutionHistory(
      generatedPrompt: prompt,
      launchedFlow: action.flowEvent ?? action.label,
    );
  }

  void _recordExecutionHistory({
    String? openedToolId,
    String? generatedPrompt,
    String? launchedFlow,
    String? copiedPrompt,
  }) {
    if (_activeSessionId == null) return;
    final session = _sessionById(_activeSessionId!);
    if (session == null) return;
    final tools = [...session.openedTools];
    if (openedToolId != null && !tools.contains(openedToolId)) {
      tools.insert(0, openedToolId);
    }
    final generated = [...session.generatedPrompts];
    if (generatedPrompt != null && generatedPrompt.trim().isNotEmpty) {
      generated.insert(0, generatedPrompt);
    }
    final launched = [...session.launchedFlows];
    if (launchedFlow != null && launchedFlow.trim().isNotEmpty) {
      launched.insert(
        0,
        '${_formatSessionTime(DateTime.now())} • $launchedFlow',
      );
    }
    final copied = [...session.copiedPrompts];
    if (copiedPrompt != null && copiedPrompt.trim().isNotEmpty) {
      copied.insert(0, copiedPrompt);
    }
    _upsertMemorySession(
      session.copyWith(
        updatedAt: DateTime.now(),
        openedTools: tools.take(10).toList(),
        generatedPrompts: generated.take(12).toList(),
        launchedFlows: launched.take(12).toList(),
        copiedPrompts: copied.take(12).toList(),
      ),
    );
  }

  void _toggleSessionPinned(String id) {
    final session = _sessionById(id);
    if (session == null) return;
    _upsertMemorySession(
      session.copyWith(pinned: !session.pinned, updatedAt: DateTime.now()),
    );
  }

  void _toggleSessionFavorite(String id) {
    final session = _sessionById(id);
    if (session == null) return;
    _upsertMemorySession(
      session.copyWith(favorite: !session.favorite, updatedAt: DateTime.now()),
    );
  }

  void _saveActiveSessionToProject() {
    if (_activeSessionId == null || _memoryProjects.isEmpty) return;
    final session = _sessionById(_activeSessionId!);
    if (session == null) return;
    final preferred = _projectForSession(session) ?? _memoryProjects.first;
    final ids = [
      session.id,
      ...preferred.sessionIds.where((id) => id != session.id),
    ];
    final updatedProject = preferred.copyWith(
      sessionIds: ids,
      updatedAt: DateTime.now(),
    );
    setState(() {
      _memoryProjects = [
        updatedProject,
        ..._memoryProjects.where((project) => project.id != preferred.id),
      ];
    });
    _storage.saveProjects(_memoryProjects);
    _upsertMemorySession(
      session.copyWith(projectId: preferred.id, updatedAt: DateTime.now()),
    );
  }

  void _createProjectFromActiveSession() {
    final now = DateTime.now();
    final session = _activeSessionId == null
        ? null
        : _sessionById(_activeSessionId!);
    final project = MemoryProject(
      id: _newMemoryId('project'),
      title: session == null ? 'Новый проект' : 'Проект: ${session.title}',
      description: session == null
          ? 'Локальный проект для будущих сессий и результатов.'
          : 'Создан из активной сессии: ${session.preview}',
      category: session?.type.label ?? 'workspace',
      sessionIds: session == null ? const [] : [session.id],
      createdAt: now,
      updatedAt: now,
      pinned: true,
    );
    setState(() {
      _memoryProjects = [project, ..._memoryProjects];
      _historyTab = 'Проекты';
    });
    _storage.saveProjects(_memoryProjects);
    if (session != null) {
      _upsertMemorySession(
        session.copyWith(projectId: project.id, updatedAt: now),
      );
    }
  }

  MemoryProject? _projectForSession(WorkspaceSession session) {
    return _firstWhereOrNull(
      _memoryProjects,
      (project) =>
          project.category == session.type.label ||
          project.id == session.projectId,
    );
  }

  void _closeActiveWork() {
    setState(() {
      if (_mode == _WorkMode.agents) {
        _routePlan = null;
        _recommendation = null;
        _currentTaskSession = null;
      } else if (_mode != _WorkMode.toolkit) {
        _creativeSessions.remove(_mode);
      }
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
    required this.routePlan,
    required this.recommendation,
    required this.creativeSession,
    required this.currentTaskSession,
    required this.sessions,
    required this.projects,
    required this.activeSessionId,
    required this.executionMode,
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
    required this.onCloseActive,
    required this.onSaveToProject,
    required this.onWorkspaceExecution,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onOpenUseCase,
    required this.onOpenSession,
    required this.onOpenProject,
    required this.onCreateProject,
    required this.onToggleSessionPinned,
    required this.onToggleSessionFavorite,
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
  final RoutePlan? routePlan;
  final RoutingRecommendation? recommendation;
  final _CreativeSession? creativeSession;
  final _TaskSession? currentTaskSession;
  final List<WorkspaceSession> sessions;
  final List<MemoryProject> projects;
  final String? activeSessionId;
  final ExecutionMode executionMode;
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
  final VoidCallback onCloseActive;
  final VoidCallback onSaveToProject;
  final void Function(_WorkspaceActionSpec action, String prompt)
  onWorkspaceExecution;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final ValueChanged<String?> onOpenUseCase;
  final ValueChanged<String> onOpenSession;
  final ValueChanged<String> onOpenProject;
  final VoidCallback onCreateProject;
  final ValueChanged<String> onToggleSessionPinned;
  final ValueChanged<String> onToggleSessionFavorite;
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
                  routePlan: routePlan,
                  recommendation: recommendation,
                  creativeSession: creativeSession,
                  activeViewType: activeViewType,
                  activeWorkflowId: activeWorkflowId,
                  activeAgentId: activeAgentId,
                  activeToolId: activeToolId,
                  activeUseCaseId: activeUseCaseId,
                  activeSummaryTitle: activeSummaryTitle,
                  activeSummarySubtitle: activeSummarySubtitle,
                  executionMode: executionMode,
                  onOpenWorkflow: onOpenWorkflow,
                  onOpenAgent: onOpenAgent,
                  onOpenTool: onOpenTool,
                  onOpenUseCase: onOpenUseCase,
                  onBack: onBack,
                  onCloseActive: onCloseActive,
                  onSaveToProject: onSaveToProject,
                  onWorkspaceExecution: onWorkspaceExecution,
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
            currentTaskSession: currentTaskSession,
            sessions: sessions,
            projects: projects,
            activeSessionId: activeSessionId,
            onTab: onHistoryTab,
            onNavigate: onNavigate,
            onOpenWorkflow: onOpenWorkflow,
            onOpenAgent: onOpenAgent,
            onOpenTool: onOpenTool,
            onOpenUseCase: onOpenUseCase,
            onOpenSession: onOpenSession,
            onOpenProject: onOpenProject,
            onCreateProject: onCreateProject,
            onToggleSessionPinned: onToggleSessionPinned,
            onToggleSessionFavorite: onToggleSessionFavorite,
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
            executionMode: executionMode,
            onModel: onModel,
            onAspect: onAspect,
            onQuality: onQuality,
            onReset: onReset,
            onOpenWorkflow: onOpenWorkflow,
            onOpenTool: onOpenTool,
          ),
        ),
        if (mode != _WorkMode.toolkit)
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
    required this.routePlan,
    required this.recommendation,
    required this.creativeSession,
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
    required this.executionMode,
    required this.onMode,
    required this.onSubmit,
    required this.onQuickGoal,
    required this.onCloseActive,
    required this.onSaveToProject,
    required this.onWorkspaceExecution,
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
  final RoutePlan? routePlan;
  final RoutingRecommendation? recommendation;
  final _CreativeSession? creativeSession;
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
  final ExecutionMode executionMode;
  final ValueChanged<_WorkMode> onMode;
  final VoidCallback onSubmit;
  final ValueChanged<String> onQuickGoal;
  final VoidCallback onCloseActive;
  final VoidCallback onSaveToProject;
  final void Function(_WorkspaceActionSpec action, String prompt)
  onWorkspaceExecution;
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
            routePlan: routePlan,
            recommendation: recommendation,
            creativeSession: creativeSession,
            activeViewType: activeViewType,
            activeWorkflowId: activeWorkflowId,
            activeAgentId: activeAgentId,
            activeToolId: activeToolId,
            activeUseCaseId: activeUseCaseId,
            activeSummaryTitle: activeSummaryTitle,
            activeSummarySubtitle: activeSummarySubtitle,
            executionMode: executionMode,
            onOpenWorkflow: onOpenWorkflow,
            onOpenAgent: onOpenAgent,
            onOpenTool: onOpenTool,
            onOpenUseCase: onOpenUseCase,
            onBack: onBack,
            onCloseActive: onCloseActive,
            onSaveToProject: onSaveToProject,
            onWorkspaceExecution: onWorkspaceExecution,
          ),
        ),
        const SizedBox(height: 14),
        if (mode != _WorkMode.toolkit) ...[
          _PromptComposer(
            mode: mode,
            controller: taskController,
            onSubmit: onSubmit,
            onQuickGoal: onQuickGoal,
          ),
          const SizedBox(height: 14),
        ],
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
          executionMode: executionMode,
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
    required this.currentTaskSession,
    required this.sessions,
    required this.projects,
    required this.activeSessionId,
    required this.onTab,
    required this.onNavigate,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onOpenUseCase,
    required this.onOpenSession,
    required this.onOpenProject,
    required this.onCreateProject,
    required this.onToggleSessionPinned,
    required this.onToggleSessionFavorite,
    required this.onNewSession,
  });

  final String tab;
  final _TaskSession? currentTaskSession;
  final List<WorkspaceSession> sessions;
  final List<MemoryProject> projects;
  final String? activeSessionId;
  final ValueChanged<String> onTab;
  final ValueChanged<AppDestination> onNavigate;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final ValueChanged<String?> onOpenUseCase;
  final ValueChanged<String> onOpenSession;
  final ValueChanged<String> onOpenProject;
  final VoidCallback onCreateProject;
  final ValueChanged<String> onToggleSessionPinned;
  final ValueChanged<String> onToggleSessionFavorite;
  final VoidCallback onNewSession;

  @override
  Widget build(BuildContext context) {
    final activeSessions = [
      ...sessions.where((session) => session.id == activeSessionId),
      ...sessions.where(
        (session) => session.pinned && session.id != activeSessionId,
      ),
    ].take(4).toList();
    final recentSessions = sessions.take(6).toList();
    final favoriteSessions = sessions
        .where((session) => session.favorite || session.pinned)
        .take(6)
        .toList();
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
                    onPressed: onCreateProject,
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
              const _PanelLabel('АКТИВНЫЕ ЗАДАЧИ'),
              const _SectionHint('то, над чем работаешь сейчас'),
              if (activeSessions.isEmpty && currentTaskSession == null)
                _HistoryItem(
                  title: '10 Reels для трека',
                  subtitle: 'активная задача',
                  type: 'задача',
                  icon: Icons.bolt_rounded,
                  active: true,
                  onTap: () => onOpenWorkflow('ai-short-video-factory'),
                )
              else if (activeSessions.isNotEmpty)
                for (final session in activeSessions)
                  _MemorySessionItem(
                    session: session,
                    active: session.id == activeSessionId,
                    onOpen: () => onOpenSession(session.id),
                    onPin: () => onToggleSessionPinned(session.id),
                    onFavorite: () => onToggleSessionFavorite(session.id),
                  )
              else if (currentTaskSession != null)
                _HistoryItem(
                  title: 'Текущая задача',
                  subtitle:
                      '${currentTaskSession!.mode} • ${_formatSessionTime(currentTaskSession!.timestamp)}',
                  type: currentTaskSession!.route.routeType,
                  icon: Icons.route_rounded,
                  active: true,
                  onTap: () => onOpenWorkflow(
                    _firstOrNull(currentTaskSession!.route.workflowIds),
                  ),
                ),
              const SizedBox(height: 14),
              const _PanelLabel('ПОСЛЕДНИЕ СЕССИИ'),
              const _SectionHint('быстрый возврат к прошлым рабочим сессиям'),
              if (recentSessions.isEmpty) ...[
                _HistoryItem(
                  title: 'AI-фриланс разведка',
                  subtitle: 'mock session',
                  type: 'задача',
                  icon: Icons.manage_search_rounded,
                  onTap: () => onOpenUseCase('find-ai-freelance-jobs'),
                ),
              ] else
                for (final session in recentSessions)
                  _MemorySessionItem(
                    session: session,
                    active: session.id == activeSessionId,
                    onOpen: () => onOpenSession(session.id),
                    onPin: () => onToggleSessionPinned(session.id),
                    onFavorite: () => onToggleSessionFavorite(session.id),
                  ),
              const SizedBox(height: 14),
              const _PanelLabel('ПРОЕКТЫ'),
              const _SectionHint('долгие направления работы'),
              for (final project in projects.take(3))
                _ProjectMemoryItem(
                  project: project,
                  onOpen: () => onOpenProject(project.id),
                ),
              const SizedBox(height: 14),
              const _PanelLabel('AI HELPERS'),
              const _SectionHint('AI-помощники для отдельных этапов'),
              _HistoryItem(
                title: 'AI-помощник-режиссер',
                subtitle: 'сцены и раскадровка',
                type: 'помощник',
                icon: Icons.smart_toy_outlined,
                onTap: () => onOpenAgent('director-agent'),
              ),
              _HistoryItem(
                title: 'Prompt operator',
                subtitle: 'промпты и улучшения',
                type: 'помощник',
                icon: Icons.psychology_alt_outlined,
                onTap: () => onOpenAgent('prompt-engineer-agent'),
              ),
              const SizedBox(height: 14),
              const _PanelLabel('ИНСТРУМЕНТЫ'),
              const _SectionHint('нейросети и сервисы под рукой'),
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
            ],
            if (tab == 'Проекты') ...[
              const _PanelLabel('ПРОЕКТЫ'),
              const _SectionHint('project memory, сессии и продолжение работы'),
              for (final project in projects)
                _ProjectMemoryItem(
                  project: project,
                  onOpen: () => onOpenProject(project.id),
                ),
            ],
            if (tab == 'Избранное') ...[
              const _PanelLabel('ИЗБРАННЫЕ СЕССИИ'),
              const _SectionHint('pin/favorite для быстрого возврата'),
              if (favoriteSessions.isEmpty)
                const _SectionHint('добавь сессию в избранное звездочкой')
              else
                for (final session in favoriteSessions)
                  _MemorySessionItem(
                    session: session,
                    active: session.id == activeSessionId,
                    onOpen: () => onOpenSession(session.id),
                    onPin: () => onToggleSessionPinned(session.id),
                    onFavorite: () => onToggleSessionFavorite(session.id),
                  ),
              const SizedBox(height: 10),
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
    required this.routePlan,
    required this.creativeSession,
    required this.recommendation,
    required this.activeViewType,
    required this.activeWorkflowId,
    required this.activeAgentId,
    required this.activeToolId,
    required this.activeUseCaseId,
    required this.activeSummaryTitle,
    required this.activeSummarySubtitle,
    required this.executionMode,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onOpenUseCase,
    required this.onBack,
    required this.onCloseActive,
    required this.onSaveToProject,
    required this.onWorkspaceExecution,
  });

  final _WorkMode mode;
  final RoutePlan? routePlan;
  final _CreativeSession? creativeSession;
  final RoutingRecommendation? recommendation;
  final _ActiveViewType activeViewType;
  final String? activeWorkflowId;
  final String? activeAgentId;
  final String? activeToolId;
  final String? activeUseCaseId;
  final String? activeSummaryTitle;
  final String? activeSummarySubtitle;
  final ExecutionMode executionMode;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final ValueChanged<String?> onOpenUseCase;
  final VoidCallback onBack;
  final VoidCallback onCloseActive;
  final VoidCallback onSaveToProject;
  final void Function(_WorkspaceActionSpec action, String prompt)
  onWorkspaceExecution;

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
    } else if (activeViewType == _ActiveViewType.creativeSession) {
      stage = creativeSession == null
          ? _EmptyModeStage(mode: mode, key: ValueKey(mode))
          : _CreativeWorkspaceStage(
              session: creativeSession!,
              onClose: onCloseActive,
              onSaveToProject: onSaveToProject,
              onWorkspaceExecution: onWorkspaceExecution,
              executionMode: executionMode,
              key: ValueKey(
                'creative-${creativeSession!.mode.name}-${creativeSession!.timestamp.millisecondsSinceEpoch}',
              ),
            );
    } else if (activeViewType == _ActiveViewType.routePlan) {
      stage = routePlan == null
          ? mode == _WorkMode.toolkit
                ? _ToolkitSearchStage(
                    mode: mode,
                    onOpenTool: onOpenTool,
                    key: const ValueKey('toolkit-search'),
                  )
                : _EmptyModeStage(mode: mode, key: ValueKey(mode))
          : _RouteStage(
              routePlan: routePlan!,
              onOpenWorkflow: onOpenWorkflow,
              onOpenAgent: onOpenAgent,
              onOpenTool: onOpenTool,
              onClose: onCloseActive,
              onSaveToProject: onSaveToProject,
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
        onClose: onCloseActive,
        key: ValueKey(
          '${activeViewType.name}-${activeWorkflowId ?? activeAgentId ?? activeToolId ?? activeUseCaseId ?? activeSummaryTitle ?? 'default'}',
        ),
      );
    }

    return Column(
      children: [
        _SessionHeader(
          mode: mode,
          routePlan: routePlan,
          creativeSession: creativeSession,
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
    required this.routePlan,
    required this.creativeSession,
    required this.recommendation,
    required this.activeViewType,
  });

  final _WorkMode mode;
  final RoutePlan? routePlan;
  final _CreativeSession? creativeSession;
  final RoutingRecommendation? recommendation;
  final _ActiveViewType activeViewType;

  @override
  Widget build(BuildContext context) {
    final sessionName = switch (activeViewType) {
      _ActiveViewType.routePlan =>
        routePlan?.detectedGoal ??
            recommendation?.task ??
            'AI-маршрут в рабочей станции',
      _ActiveViewType.creativeSession =>
        creativeSession?.title ?? 'Рабочее пространство',
      _ => 'Новая задача в рабочей станции',
    };
    final activeWork = switch (activeViewType) {
      _ActiveViewType.empty => 'без активного объекта',
      _ActiveViewType.routePlan => 'AI-маршрут',
      _ActiveViewType.creativeSession => 'рабочее пространство',
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
      _ActiveViewType.creativeSession => 'production',
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
                  'Опиши сцену, кадр или reel. OS соберет cinematic prompt и storyboard.',
                _WorkMode.toolkit => 'Найди подходящую нейросеть под задачу.',
                _WorkMode.agents =>
                  'AI-помощники помогают закрывать отдельные этапы работы.',
                _WorkMode.text =>
                  'Пиши, исследуй, редактируй и превращай идеи в рабочие тексты.',
                _WorkMode.design =>
                  'Собери промпт, стиль, композицию и референсы для генерации изображения.',
                _WorkMode.audio =>
                  'Опиши голос, музыку или дубляж. OS соберет звуковой бриф.',
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
    required this.routePlan,
    required this.onOpenWorkflow,
    required this.onOpenAgent,
    required this.onOpenTool,
    required this.onClose,
    required this.onSaveToProject,
  });

  final RoutePlan routePlan;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final VoidCallback onClose;
  final VoidCallback onSaveToProject;

  @override
  Widget build(BuildContext context) {
    final firstAgentId = routePlan.agentIds.isEmpty
        ? null
        : routePlan.agentIds.first;
    final firstToolId = routePlan.toolIds.isEmpty
        ? null
        : routePlan.toolIds.first;
    final firstWorkflowId = routePlan.workflowIds.isEmpty
        ? null
        : routePlan.workflowIds.first;
    return Center(
      child: _GlassPanel(
        key: const ValueKey('recommended-plan'),
        width: 720,
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: _PanelLabel('AI-маршрут')),
                  TextButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Закрыть'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                routePlan.detectedGoal,
                style: const TextStyle(
                  color: Color(0xFFF2F3F5),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _SoftBadge(routePlan.recommendedMode),
                  _SoftBadge(routePlan.routeType),
                  _SoftBadge(routePlan.estimatedComplexity),
                  if (routePlan.freePossible) const _SoftBadge('FREE'),
                  if (routePlan.localPossible) const _SoftBadge('LOCAL'),
                ],
              ),
              const SizedBox(height: 14),
              _RouteLine(
                'Рекомендованный план',
                routePlan.workflows.join(' / '),
              ),
              _RouteLine('Стоимость', routePlan.estimatedCost),
              const SizedBox(height: 8),
              const _PanelLabel('EXECUTION ROUTE'),
              const SizedBox(height: 10),
              for (var index = 0; index < routePlan.steps.length; index++)
                _RouteStepCard(step: routePlan.steps[index], index: index + 1),
              const SizedBox(height: 12),
              _RouteEntityStrip(
                title: 'Recommended tools',
                items: routePlan.tools,
                ids: routePlan.toolIds,
                icon: Icons.grid_view_rounded,
                onOpen: onOpenTool,
              ),
              const SizedBox(height: 10),
              _RouteEntityStrip(
                title: 'Recommended AI helpers',
                items: routePlan.agents,
                ids: routePlan.agentIds,
                icon: Icons.smart_toy_outlined,
                onOpen: onOpenAgent,
              ),
              const SizedBox(height: 12),
              const _PanelLabel('ROUTE OPTIONS'),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 560;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final option in routePlan.executionOptions)
                        SizedBox(
                          width: twoColumns
                              ? (constraints.maxWidth - 10) / 2
                              : constraints.maxWidth,
                          child: _ExecutionOptionCard(option: option),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const _PanelLabel('PROMPT SUGGESTIONS'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final prompt in routePlan.promptSuggestions.take(5))
                    _PromptSuggestionChip(text: prompt),
                ],
              ),
              const SizedBox(height: 16),
              _ResponsiveActionBar(
                children: [
                  FilledButton.icon(
                    onPressed: () => onOpenWorkflow(firstWorkflowId),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Continue workflow'),
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
                  OutlinedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Новый запрос'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSaveToProject,
                    icon: const Icon(Icons.drive_file_move_outline),
                    label: const Text('Save to project'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.keyboard_return_rounded),
                    label: const Text('Reopen workspace'),
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

class _RouteStepCard extends StatelessWidget {
  const _RouteStepCard({required this.step, required this.index});

  final RouteStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        border: Border.all(color: const Color(0x14FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0x126BE4C9),
              border: Border.all(color: const Color(0x336BE4C9)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_routeIcon(step.iconKey), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${step.title}',
                  style: const TextStyle(
                    color: Color(0xFFF2F3F5),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.explanation,
                  style: const TextStyle(
                    color: Color(0xFF9AA0AA),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _StateBadge(step.state.label),
                    for (final badge in step.badges) _RouteBadge(badge),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreativeWorkspaceStage extends StatelessWidget {
  const _CreativeWorkspaceStage({
    super.key,
    required this.session,
    required this.onClose,
    required this.onSaveToProject,
    required this.onWorkspaceExecution,
    required this.executionMode,
  });

  final _CreativeSession session;
  final VoidCallback onClose;
  final VoidCallback onSaveToProject;
  final void Function(_WorkspaceActionSpec action, String prompt)
  onWorkspaceExecution;
  final ExecutionMode executionMode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassPanel(
        width: 680,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PanelLabel(session.mode.label.toUpperCase()),
                  ),
                  TextButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Закрыть'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                session.title,
                style: const TextStyle(
                  color: Color(0xFFF2F3F5),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                session.subtitle,
                style: const TextStyle(
                  color: Color(0xFF9AA0AA),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              _ExecutionModeStrip(mode: executionMode),
              const SizedBox(height: 12),
              _WorkspaceOutputBlock(
                title: 'FINAL PRODUCTION PROMPT',
                value: _productionPromptForSession(session),
              ),
              const SizedBox(height: 12),
              _WorkspaceModeBoard(
                session: session,
                onExecute: onWorkspaceExecution,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final section in session.sections)
                    _WorkspaceMiniBlock(
                      title: section.title,
                      value: section.value,
                    ),
                ],
              ),
              if (session.promptBlocks.isNotEmpty) ...[
                const SizedBox(height: 14),
                const _PanelLabel('PROMPT BLOCKS'),
                const SizedBox(height: 8),
                for (final block in session.promptBlocks)
                  _WorkspacePromptLine(text: block),
              ],
              const SizedBox(height: 14),
              _ResponsiveActionBar(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onWorkspaceExecution(
                      const _WorkspaceActionSpec(
                        'Copy final prompt',
                        Icons.copy_rounded,
                        false,
                        copyOutput: true,
                      ),
                      _productionPromptForSession(session),
                    ),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy final prompt'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copyText(context, session.output),
                    icon: const Icon(Icons.copy_all_rounded),
                    label: const Text('Duplicate session'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Очистить'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSaveToProject,
                    icon: const Icon(Icons.drive_file_move_outline),
                    label: const Text('Save to project'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSaveToProject,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Continue project'),
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

class _WorkspaceOutputBlock extends StatelessWidget {
  const _WorkspaceOutputBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        border: Border.all(color: const Color(0x14FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: const TextStyle(
              color: Color(0xFFE5E7EC),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

String _productionPromptForSession(_CreativeSession session) {
  final blocks = session.promptBlocks.isEmpty
      ? session.output
      : session.promptBlocks.join('\n\n');
  final modeNote = switch (session.mode) {
    _WorkMode.text => 'Production mode: AI Writer IDE',
    _WorkMode.design => 'Production mode: Image Direction Lab',
    _WorkMode.video => 'Production mode: Cinematic Production Table',
    _WorkMode.audio => 'Production mode: Sound Lab',
    _ => 'Production mode: AI Operator OS',
  };
  return '$modeNote\n\n${session.output}\n\nExecution prompt:\n$blocks';
}

class _WorkspaceModeBoard extends StatelessWidget {
  const _WorkspaceModeBoard({required this.session, required this.onExecute});

  final _CreativeSession session;
  final void Function(_WorkspaceActionSpec action, String prompt) onExecute;

  @override
  Widget build(BuildContext context) {
    final spec = _WorkspaceBoardSpec.forMode(session.mode);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(spec.icon, size: 17, color: const Color(0xFFFF9A78)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  spec.title,
                  style: const TextStyle(
                    color: Color(0xFFF2F3F5),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const _StateBadge('Ready'),
            ],
          ),
          const SizedBox(height: 10),
          _NextStepCard(text: spec.nextStep),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final block in spec.blocks)
                _WorkspaceBoardBlock(
                  icon: block.icon,
                  title: block.title,
                  value: block.value,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ResponsiveActionBar(
            children: [
              for (final action in spec.actions)
                action.primary
                    ? FilledButton.icon(
                        onPressed: () => _runWorkspaceAction(
                          context,
                          action,
                          _productionPromptForSession(session),
                          onExecute,
                        ),
                        icon: Icon(action.icon),
                        label: Text(action.label),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => _runWorkspaceAction(
                          context,
                          action,
                          _productionPromptForSession(session),
                          onExecute,
                        ),
                        icon: Icon(action.icon),
                        label: Text(action.label),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkspaceBoardBlock extends StatelessWidget {
  const _WorkspaceBoardBlock({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x08FFFFFF),
          border: Border.all(color: const Color(0x10FFFFFF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFB0B4BE)),
            const SizedBox(height: 7),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF8B8F9A),
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x12FF7A4D),
        border: Border.all(color: const Color(0x24FF7A4D)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: Color(0xFFFF9A78),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Следующий шаг: $text',
              style: const TextStyle(
                color: Color(0xFFF2F3F5),
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceBoardSpec {
  const _WorkspaceBoardSpec({
    required this.title,
    required this.nextStep,
    required this.icon,
    required this.blocks,
    required this.actions,
  });

  final String title;
  final String nextStep;
  final IconData icon;
  final List<_WorkspaceBoardBlockSpec> blocks;
  final List<_WorkspaceActionSpec> actions;

  static _WorkspaceBoardSpec forMode(_WorkMode mode) {
    return switch (mode) {
      _WorkMode.text => const _WorkspaceBoardSpec(
        title: 'AI writer IDE',
        nextStep:
            '1. открыть ChatGPT/Claude 2. вставить prompt 3. получить draft 4. refine',
        icon: Icons.edit_note_rounded,
        blocks: [
          _WorkspaceBoardBlockSpec(
            Icons.article_outlined,
            'Draft',
            'основной текст',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.auto_fix_high_rounded,
            'Rewrite',
            'варианты тона',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.subject_rounded,
            'Summarize',
            'короткая версия',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.manage_search_rounded,
            'Research',
            'факты и тезисы',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.terminal_rounded,
            'Prompt lab',
            'инструкция для модели',
          ),
        ],
        actions: [
          _WorkspaceActionSpec(
            'Continue in ChatGPT',
            Icons.open_in_new_rounded,
            true,
            toolId: 'chatgpt',
          ),
          _WorkspaceActionSpec(
            'Open Claude',
            Icons.open_in_new_rounded,
            false,
            toolId: 'claude',
          ),
          _WorkspaceActionSpec(
            'Open Gemini',
            Icons.open_in_new_rounded,
            false,
            toolId: 'gemini',
          ),
          _WorkspaceActionSpec(
            'Copy production prompt',
            Icons.copy_rounded,
            false,
            copyOutput: true,
          ),
        ],
      ),
      _WorkMode.design => const _WorkspaceBoardSpec(
        title: 'Image direction lab',
        nextStep: '1. открыть Leonardo 2. вставить prompt 3. upscale 4. export',
        icon: Icons.auto_awesome_mosaic_outlined,
        blocks: [
          _WorkspaceBoardBlockSpec(
            Icons.image_search_outlined,
            'Reference slots',
            '0/4 референса',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.grid_on_rounded,
            'Composition',
            'объект, фон, баланс',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.camera_alt_outlined,
            'Framing',
            'камера и ракурс',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.palette_outlined,
            'Style refs',
            'цвет, материал, жанр',
          ),
        ],
        actions: [
          _WorkspaceActionSpec(
            'Generate prompt',
            Icons.auto_awesome_rounded,
            true,
            flowEvent: 'generate_prompt',
          ),
          _WorkspaceActionSpec(
            'Refine prompt',
            Icons.auto_fix_high_rounded,
            false,
            flowEvent: 'refine_prompt',
          ),
          _WorkspaceActionSpec(
            'Open Leonardo',
            Icons.open_in_new_rounded,
            false,
            toolId: 'leonardo',
          ),
          _WorkspaceActionSpec(
            'Open Midjourney',
            Icons.open_in_new_rounded,
            false,
            toolId: 'midjourney',
          ),
          _WorkspaceActionSpec(
            'Open Flux',
            Icons.open_in_new_rounded,
            false,
            toolId: 'flux-playground',
          ),
          _WorkspaceActionSpec(
            'Open Playground',
            Icons.open_in_new_rounded,
            false,
            toolId: 'flux-playground',
          ),
          _WorkspaceActionSpec(
            'Copy final prompt',
            Icons.copy_rounded,
            false,
            copyOutput: true,
          ),
        ],
      ),
      _WorkMode.video => const _WorkspaceBoardSpec(
        title: 'Cinematic production table',
        nextStep:
            '1. открыть Kling 2. вставить prompt 3. сгенерировать preview 4. открыть Runway 5. сделать polish',
        icon: Icons.local_movies_outlined,
        blocks: [
          _WorkspaceBoardBlockSpec(
            Icons.view_timeline_outlined,
            'Storyboard',
            'кадры и beat points',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.movie_creation_outlined,
            'Shot cards',
            'камера, свет, действие',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.linear_scale_rounded,
            'Timeline',
            'начало, пик, финал',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.center_focus_strong,
            'Motion',
            'движение камеры',
          ),
        ],
        actions: [
          _WorkspaceActionSpec(
            'Generate prompt',
            Icons.play_arrow_rounded,
            true,
            flowEvent: 'generate_prompt',
          ),
          _WorkspaceActionSpec(
            'Refine prompt',
            Icons.auto_fix_high_rounded,
            false,
            flowEvent: 'refine_prompt',
          ),
          _WorkspaceActionSpec(
            'Open Kling',
            Icons.open_in_new_rounded,
            false,
            toolId: 'kling',
          ),
          _WorkspaceActionSpec(
            'Open Veo',
            Icons.open_in_new_rounded,
            false,
            toolId: 'veo',
          ),
          _WorkspaceActionSpec(
            'Open Runway',
            Icons.open_in_new_rounded,
            false,
            toolId: 'runway',
          ),
          _WorkspaceActionSpec(
            'Copy final prompt',
            Icons.copy_rounded,
            false,
            copyOutput: true,
          ),
          _WorkspaceActionSpec(
            'Continue flow',
            Icons.skip_next_rounded,
            false,
            flowEvent: 'continue_flow',
          ),
        ],
      ),
      _WorkMode.audio => const _WorkspaceBoardSpec(
        title: 'Sound lab',
        nextStep:
            '1. открыть ElevenLabs/Suno 2. вставить prompt 3. preview 4. export',
        icon: Icons.graphic_eq_rounded,
        blocks: [
          _WorkspaceBoardBlockSpec(
            Icons.record_voice_over_outlined,
            'Voice chain',
            'голос, тембр, эмоция',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.library_music_outlined,
            'Soundtrack refs',
            'жанр и темп',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.subtitles_outlined,
            'Dubbing flow',
            'текст, паузы, синк',
          ),
          _WorkspaceBoardBlockSpec(
            Icons.tune_rounded,
            'Voice presets',
            'warm, clean, trailer',
          ),
        ],
        actions: [
          _WorkspaceActionSpec(
            'Open ElevenLabs',
            Icons.open_in_new_rounded,
            true,
            toolId: 'elevenlabs',
          ),
          _WorkspaceActionSpec(
            'Open Suno',
            Icons.open_in_new_rounded,
            false,
            toolId: 'suno',
          ),
          _WorkspaceActionSpec(
            'Generate prompt',
            Icons.auto_awesome_rounded,
            false,
            flowEvent: 'generate_prompt',
          ),
          _WorkspaceActionSpec(
            'Copy final prompt',
            Icons.copy_rounded,
            false,
            copyOutput: true,
          ),
          _WorkspaceActionSpec(
            'Create dubbing chain',
            Icons.account_tree_outlined,
            false,
          ),
        ],
      ),
      _ => const _WorkspaceBoardSpec(
        title: 'Workspace',
        nextStep: 'продолжить работу в выбранном режиме',
        icon: Icons.dashboard_customize_outlined,
        blocks: [],
        actions: [],
      ),
    };
  }
}

class _WorkspaceBoardBlockSpec {
  const _WorkspaceBoardBlockSpec(this.icon, this.title, this.value);

  final IconData icon;
  final String title;
  final String value;
}

class _WorkspaceActionSpec {
  const _WorkspaceActionSpec(
    this.label,
    this.icon,
    this.primary, {
    this.toolId,
    this.copyOutput = false,
    this.flowEvent,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final String? toolId;
  final bool copyOutput;
  final String? flowEvent;
}

void _runWorkspaceAction(
  BuildContext context,
  _WorkspaceActionSpec action,
  String output,
  void Function(_WorkspaceActionSpec action, String prompt) onExecute,
) {
  if (action.copyOutput || action.toolId != null || action.flowEvent != null) {
    onExecute(action, output);
    return;
  }
  onExecute(action, output);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${action.label}: готово к ручному шагу')),
  );
}

class _WorkspaceMiniBlock extends StatelessWidget {
  const _WorkspaceMiniBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 198,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          border: Border.all(color: const Color(0x12FFFFFF)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF9AA0AA),
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspacePromptLine extends StatelessWidget {
  const _WorkspacePromptLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        border: Border.all(color: const Color(0x10FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 11, height: 1.35),
      ),
    );
  }
}

class _ExecutionOptionCard extends StatelessWidget {
  const _ExecutionOptionCard({required this.option});

  final RouteExecutionOption option;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            option.description,
            style: const TextStyle(
              color: Color(0xFF9AA0AA),
              fontSize: 11,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [for (final badge in option.badges) _RouteBadge(badge)],
          ),
          const SizedBox(height: 8),
          Text(
            option.items.join(' / '),
            style: const TextStyle(color: Color(0xFFE5E7EC), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RouteEntityStrip extends StatelessWidget {
  const _RouteEntityStrip({
    required this.title,
    required this.items,
    required this.ids,
    required this.icon,
    required this.onOpen,
  });

  final String title;
  final List<String> items;
  final List<String> ids;
  final IconData icon;
  final ValueChanged<String?> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelLabel(title),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var index = 0; index < items.length; index++)
              ActionChip(
                avatar: Icon(icon, size: 15),
                label: Text(items[index]),
                onPressed: () => onOpen(index < ids.length ? ids[index] : null),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

class _PromptSuggestionChip extends StatelessWidget {
  const _PromptSuggestionChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final label = text.split(':').first;
    return Tooltip(message: text, child: _SoftBadge(label));
  }
}

class _RouteBadge extends StatelessWidget {
  const _RouteBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x116BE4C9),
        border: Border.all(color: const Color(0x226BE4C9)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9CF5E2),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        border: Border.all(color: const Color(0x18FFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD8DBE2),
          fontSize: 9,
          fontWeight: FontWeight.w800,
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
    required this.onClose,
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
  final VoidCallback onClose;

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
        onClose: onClose,
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
        onClose: onClose,
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
        onClose: onClose,
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
        onClose: onClose,
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
        onClose: onClose,
      ),
      _ActiveViewType.empty ||
      _ActiveViewType.creativeSession ||
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
    required this.onClose,
  });

  final WorkflowTemplate? workflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final VoidCallback onBack;
  final VoidCallback onClose;

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
                onClose: onClose,
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
    required this.onClose,
  });

  final AiAgent? agent;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenTool;
  final VoidCallback onBack;
  final VoidCallback onClose;

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
              onClose: onClose,
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
    required this.onClose,
  });

  final AiTool? tool;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenWorkflow;
  final VoidCallback onBack;
  final VoidCallback onClose;

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
              onClose: onClose,
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
                  onPressed: () => _launchToolWebsite(context, tool!),
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
    required this.onClose,
  });

  final UseCase? useCase;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenAgent;
  final ValueChanged<String?> onOpenTool;
  final VoidCallback onBack;
  final VoidCallback onClose;

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
              onClose: onClose,
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
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final String type;
  final ValueChanged<String?> onOpenWorkflow;
  final ValueChanged<String?> onOpenUseCase;
  final VoidCallback onBack;
  final VoidCallback onClose;

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
              onClose: onClose,
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
  const _InlineBackHeader({
    required this.breadcrumb,
    required this.onBack,
    required this.onClose,
  });

  final String breadcrumb;
  final VoidCallback onBack;
  final VoidCallback onClose;

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
        const SizedBox(width: 8),
        IconButton(
          onPressed: onClose,
          tooltip: 'Закрыть',
          icon: const Icon(Icons.close_rounded, size: 16),
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
    final smartSuggestions = switch (mode) {
      _WorkMode.agents => [
        ...mode.quickActions,
        const (label: 'AI Shorts', task: 'Сделать 10 AI Shorts по одной идее'),
        const (
          label: 'AI Automation',
          task: 'Собрать n8n workflow для AI-автоматизации',
        ),
        const (
          label: 'Freelance Outreach',
          task: 'Найти клиентов и написать outreach для AI-услуги',
        ),
        const (
          label: 'Video Localization',
          task: 'Локализовать видео: перевод, озвучка и субтитры',
        ),
      ],
      _WorkMode.text => [
        ...mode.quickActions,
        const (label: 'Rewrite', task: 'Переписать текст яснее и сильнее'),
        const (label: 'Summarize', task: 'Кратко пересказать материал'),
        const (label: 'Brainstorm', task: 'Сгенерировать идеи по теме'),
      ],
      _WorkMode.design => [
        ...mode.quickActions,
        const (
          label: 'Thumbnail Pack',
          task: 'Сделать thumbnail pack для YouTube',
        ),
        const (label: 'Product Shot', task: 'Создать premium product shot'),
        const (label: 'AI Influencer', task: 'Создать портрет AI-инфлюенсера'),
      ],
      _WorkMode.video => [
        ...mode.quickActions,
        const (label: 'Cinematic opener', task: 'Создать cinematic opener'),
        const (label: 'Camera shot', task: 'Описать camera shot для сцены'),
        const (
          label: 'Music promo',
          task: 'Сделать scene prompts для music promo',
        ),
      ],
      _WorkMode.audio => [
        ...mode.quickActions,
        const (label: 'Voice style', task: 'Подобрать voiceover стиль'),
        const (label: 'Sound design', task: 'Создать sound design prompt'),
        const (label: 'Music prompt', task: 'Написать music generation prompt'),
      ],
      _WorkMode.toolkit => mode.quickActions,
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
                        tooltip: mode == _WorkMode.agents
                            ? 'Собрать AI-маршрут'
                            : 'Создать результат',
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
            for (final goal in smartSuggestions.take(10))
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
    required this.executionMode,
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
  final ExecutionMode executionMode;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ExecutionModeStrip(mode: executionMode),
                  const SizedBox(height: 8),
                  _PathRow('Ручной запуск', Icons.open_in_new_rounded),
                  _PathRow('API позже', Icons.api_rounded),
                  _PathRow('Локально позже', Icons.dns_outlined),
                  const SizedBox(height: 6),
                  const Text(
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

class _ExecutionModeStrip extends StatelessWidget {
  const _ExecutionModeStrip({required this.mode});

  final ExecutionMode mode;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _RouteBadge(mode.label.toUpperCase()),
        const _StateBadge('Runtime foundation'),
        const _StateBadge('No API yet'),
      ],
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
      _ActiveViewType.creativeSession => 'Рабочее пространство',
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
      _ActiveViewType.creativeSession => const [
        ('Production output', Icons.auto_awesome_rounded),
        ('Промпты и варианты', Icons.text_fields_rounded),
        ('Ручной экспорт', Icons.ios_share_rounded),
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
      _ActiveViewType.creativeSession =>
        'Продолжай production: копируй блоки, уточняй промпт или создай новый запрос.',
      _ActiveViewType.session || _ActiveViewType.project =>
        'Продолжи задачу: открой быстрый план или подбери инструмент.',
      _ActiveViewType.empty => switch (mode) {
        _WorkMode.agents =>
          'Опиши orchestration-задачу: OS построит маршрут, workflow и помощников.',
        _WorkMode.text =>
          'Напиши запрос для текста, research, rewrite или prompt lab.',
        _WorkMode.design =>
          'Опиши изображение: получишь prompt blocks, стиль и композицию.',
        _WorkMode.video =>
          'Опиши сцену: получишь scene prompt, shot breakdown и camera logic.',
        _WorkMode.audio =>
          'Опиши музыку, voiceover или sound design для audio workspace.',
        _WorkMode.toolkit => 'Найди нейросеть и открой ее внутри OS.',
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

class _MemorySessionItem extends StatelessWidget {
  const _MemorySessionItem({
    required this.session,
    required this.active,
    required this.onOpen,
    required this.onPin,
    required this.onFavorite,
  });

  final WorkspaceSession session;
  final bool active;
  final VoidCallback onOpen;
  final VoidCallback onPin;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return _HistoryItem(
      title: session.title,
      subtitle:
          '${session.category} • updated ${_formatSessionTime(session.updatedAt)}',
      type: session.type.label,
      icon: _sessionIcon(session.type),
      active: active,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniMemoryButton(
            icon: session.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            onTap: onPin,
            active: session.pinned,
          ),
          _MiniMemoryButton(
            icon: session.favorite ? Icons.star : Icons.star_border_rounded,
            onTap: onFavorite,
            active: session.favorite,
          ),
        ],
      ),
      onTap: onOpen,
    );
  }
}

class _ProjectMemoryItem extends StatelessWidget {
  const _ProjectMemoryItem({required this.project, required this.onOpen});

  final MemoryProject project;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _HistoryItem(
      title: project.title,
      subtitle:
          '${project.category} • ${project.sessionIds.length} сессий • ${_formatSessionTime(project.updatedAt)}',
      type: project.pinned ? 'pinned' : 'проект',
      icon: Icons.folder_special_outlined,
      active: project.pinned,
      onTap: onOpen,
    );
  }
}

class _MiniMemoryButton extends StatelessWidget {
  const _MiniMemoryButton({
    required this.icon,
    required this.onTap,
    required this.active,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(
          icon,
          size: 13,
          color: active ? const Color(0xFFFF9A78) : const Color(0xFF6F7480),
        ),
      ),
    );
  }
}

IconData _sessionIcon(WorkspaceSessionType type) {
  return switch (type) {
    WorkspaceSessionType.text => Icons.article_outlined,
    WorkspaceSessionType.image => Icons.image_outlined,
    WorkspaceSessionType.video => Icons.movie_creation_outlined,
    WorkspaceSessionType.audio => Icons.graphic_eq_rounded,
    WorkspaceSessionType.helper => Icons.smart_toy_outlined,
    WorkspaceSessionType.workflow => Icons.schema_outlined,
  };
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String type;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0x12FF7A4D) : Colors.transparent,
          border: Border.all(
            color: active ? const Color(0x22FF7A4D) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? const Color(0xFFFF9A78) : const Color(0xFF8B8F9A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: active ? const Color(0xFFF2F3F5) : null,
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
            trailing ??
                Text(
                  type,
                  style: const TextStyle(
                    color: Color(0xFF6F7480),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Text(
                type,
                style: const TextStyle(
                  color: Color(0xFF6F7480),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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
