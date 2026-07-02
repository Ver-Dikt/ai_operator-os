import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ai_operator_app.dart';
import '../../data/seed_browser_ai_tools.dart';
import '../../models/browser_ai_tool.dart';
import '../../models/execution_job.dart';
import '../../services/execution_queue.dart';
import '../../services/ollama_execution_service.dart';
import '../../services/ollama_prompt_brain_service.dart';
import '../../services/openai_compatible_text_service.dart';
import '../../state/app_settings.dart';
import '../../widgets/current_session_strip.dart';

enum TextRouteMode { localOllama, browser, apiPlaceholder, manual }

extension TextRouteModeLabel on TextRouteMode {
  String get label {
    return switch (this) {
      TextRouteMode.localOllama => 'Local Ollama',
      TextRouteMode.browser => 'Browser handoff',
      TextRouteMode.apiPlaceholder => 'API placeholder',
      TextRouteMode.manual => 'Manual',
    };
  }

  String get description {
    return switch (this) {
      TextRouteMode.localOllama =>
        'Реальный локальный запуск через Ollama, если runtime доступен.',
      TextRouteMode.browser =>
        'Промпт копируется и открывается во внешнем AI-сервисе вручную.',
      TextRouteMode.apiPlaceholder =>
        'Будущий облачный API-маршрут. Сейчас ответ не генерируется.',
      TextRouteMode.manual =>
        'Локальная сборка и копирование промпта без обращения к модели.',
    };
  }
}

class TextAiProvider {
  const TextAiProvider({
    required this.id,
    required this.name,
    required this.mode,
    this.browserToolId,
  });

  final String id;
  final String name;
  final TextRouteMode mode;
  final String? browserToolId;
}

const textAiProviders = <TextAiProvider>[
  TextAiProvider(
    id: 'ollama-local',
    name: 'Ollama Local',
    mode: TextRouteMode.localOllama,
  ),
  TextAiProvider(
    id: 'chatgpt-browser',
    name: 'ChatGPT Browser',
    mode: TextRouteMode.browser,
    browserToolId: 'chatgpt',
  ),
  TextAiProvider(
    id: 'gemini-browser',
    name: 'Gemini Browser',
    mode: TextRouteMode.browser,
    browserToolId: 'gemini',
  ),
  TextAiProvider(
    id: 'claude-browser',
    name: 'Claude Browser',
    mode: TextRouteMode.browser,
    browserToolId: 'claude',
  ),
  TextAiProvider(
    id: 'openrouter-api',
    name: 'OpenRouter API',
    mode: TextRouteMode.apiPlaceholder,
  ),
  TextAiProvider(
    id: 'omniroute-api',
    name: 'OmniRoute',
    mode: TextRouteMode.apiPlaceholder,
  ),
  TextAiProvider(
    id: 'deepseek-api',
    name: 'DeepSeek',
    mode: TextRouteMode.apiPlaceholder,
  ),
  TextAiProvider(
    id: 'qwen-api',
    name: 'Qwen',
    mode: TextRouteMode.apiPlaceholder,
  ),
];

class _OpenAiCompatibleProviderConfig {
  const _OpenAiCompatibleProviderConfig({
    required this.settingsProviderId,
    required this.providerName,
    required this.defaultModel,
    required this.defaultBaseUrl,
    required this.missingApiKeyMessage,
    required this.missingApiKeySnack,
    this.missingBaseUrlMessage,
  });

  final String settingsProviderId;
  final String providerName;
  final String defaultModel;
  final String defaultBaseUrl;
  final String missingApiKeyMessage;
  final String missingApiKeySnack;
  final String? missingBaseUrlMessage;
}

String? _settingsProviderIdForTextProvider(TextAiProvider provider) {
  return switch (provider.id) {
    'openrouter-api' => 'openrouter',
    'omniroute-api' => 'omniroute',
    _ => null,
  };
}

String _defaultModelForTextProvider(TextAiProvider provider) {
  return switch (provider.id) {
    'openrouter-api' => 'openai/gpt-4o-mini',
    'omniroute-api' => 'auto',
    _ => '',
  };
}

class TextWorkspaceScreen extends StatefulWidget {
  const TextWorkspaceScreen({super.key, required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  State<TextWorkspaceScreen> createState() => _TextWorkspaceScreenState();
}

class _TextWorkspaceScreenState extends State<TextWorkspaceScreen> {
  static final List<_ChatMessage> _cachedMessages = [];
  static final List<_SessionEvent> _cachedEvents = [];
  static String _cachedInputText = '';
  static String _cachedProviderId = textAiProviders.first.id;

  final _input = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      role: _MessageRole.assistant,
      text:
          'Здесь можно собрать сценарий, промпт, структуру ролика или production prompt.',
    ),
  ];
  final _events = <_SessionEvent>[];

  String _providerId = textAiProviders.first.id;
  bool _running = false;
  _BrowserHandoff? _handoff;
  bool _showInlineWebViewPlaceholder = false;
  bool _runtimeWorkspaceOpened = false;

  TextAiProvider get _provider =>
      textAiProviders.firstWhere((item) => item.id == _providerId);

  @override
  void initState() {
    super.initState();
    if (_cachedMessages.isNotEmpty) {
      _messages
        ..clear()
        ..addAll(_cachedMessages);
    }
    _events.addAll(_cachedEvents);
    _providerId = _cachedProviderId;
    _input.text = _cachedInputText;
    _input.addListener(_persistSession);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_runtimeWorkspaceOpened) return;
    _runtimeWorkspaceOpened = true;
    unawaited(FlutenRuntimeScope.read(context).updateCurrentWorkspace('text'));
  }

  @override
  void dispose() {
    _persistSession();
    _input.removeListener(_persistSession);
    _input.dispose();
    super.dispose();
  }

  void _persistSession() {
    _cachedMessages
      ..clear()
      ..addAll(_messages);
    _cachedEvents
      ..clear()
      ..addAll(_events);
    _cachedInputText = _input.text;
    _cachedProviderId = _providerId;
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final compact = MediaQuery.sizeOf(context).width < 900;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.15,
          colors: [Color(0xFF141C24), Color(0xFF05070B)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 28,
            compact ? 18 : 24,
            compact ? 16 : 28,
            compact ? 96 : 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(provider: _provider, settings: settings),
                  const SizedBox(height: 16),
                  const CurrentSessionStrip(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: compact
                        ? Column(
                            children: [
                              Expanded(
                                child: _ChatPanel(
                                  messages: _messages,
                                  onCopy: _copyText,
                                  onOpenExternal: _openHandoffExternalFor,
                                  onOpenInside: _openHandoffInsideFor,
                                  onOpenHub: _openHandoffInBrowserHub,
                                  onSaveManual: _saveManualHandoffFor,
                                  onSendImage: _sendTextToImageStudio,
                                  onSendVideo: _sendTextToVideoStudio,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_handoff != null)
                                _InlineHandoffPanel(
                                  handoff: _handoff!,
                                  showWebViewPlaceholder:
                                      _showInlineWebViewPlaceholder,
                                  onCopy: _copyHandoffPrompt,
                                  onOpenExternal: _openHandoffExternal,
                                  onOpenInside: _openHandoffInside,
                                  onSaveManual: _saveManualHandoff,
                                  onOpenHub: _openInBrowserHub,
                                )
                              else
                                _ControlPanel(
                                  providerId: _providerId,
                                  onProviderChanged: _setProvider,
                                  onImagePrompt: () =>
                                      unawaited(_buildImagePrompt()),
                                  onVideoPrompt: () =>
                                      unawaited(_buildVideoPrompt()),
                                  onCopy: _copyCurrentText,
                                  onBrowserHub: _openInBrowserHub,
                                  onSendImage: _sendCurrentToImageStudio,
                                  onSendVideo: _sendCurrentToVideoStudio,
                                  events: _events,
                                ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _ChatPanel(
                                  messages: _messages,
                                  onCopy: _copyText,
                                  onOpenExternal: _openHandoffExternalFor,
                                  onOpenInside: _openHandoffInsideFor,
                                  onOpenHub: _openHandoffInBrowserHub,
                                  onSaveManual: _saveManualHandoffFor,
                                  onSendImage: _sendTextToImageStudio,
                                  onSendVideo: _sendTextToVideoStudio,
                                ),
                              ),
                              const SizedBox(width: 14),
                              SizedBox(
                                width: 360,
                                child: _handoff != null
                                    ? _InlineHandoffPanel(
                                        handoff: _handoff!,
                                        showWebViewPlaceholder:
                                            _showInlineWebViewPlaceholder,
                                        onCopy: _copyHandoffPrompt,
                                        onOpenExternal: _openHandoffExternal,
                                        onOpenInside: _openHandoffInside,
                                        onSaveManual: _saveManualHandoff,
                                        onOpenHub: _openInBrowserHub,
                                      )
                                    : _ControlPanel(
                                        providerId: _providerId,
                                        onProviderChanged: _setProvider,
                                        onImagePrompt: () =>
                                            unawaited(_buildImagePrompt()),
                                        onVideoPrompt: () =>
                                            unawaited(_buildVideoPrompt()),
                                        onCopy: _copyCurrentText,
                                        onBrowserHub: _openInBrowserHub,
                                        onSendImage: _sendCurrentToImageStudio,
                                        onSendVideo: _sendCurrentToVideoStudio,
                                        events: _events,
                                      ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                  _Composer(
                    controller: _input,
                    running: _running,
                    provider: _provider,
                    onSend: _send,
                    onAttach: _showAttachmentPlaceholder,
                    onImage: () => unawaited(_buildImagePrompt()),
                    onVideo: () => unawaited(_buildVideoPrompt()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setProvider(String id) {
    setState(() {
      _providerId = id;
      if (_provider.mode != TextRouteMode.browser) {
        _handoff = null;
        _showInlineWebViewPlaceholder = false;
      }
    });
    _persistSession();
    unawaited(
      FlutenRuntimeScope.read(
        context,
      ).setActiveProvider(_provider.id, route: _provider.mode.name),
    );
    _recordEvent('Выбран провайдер: ${_provider.name}');
  }

  Future<void> _send() async {
    final prompt = _input.text.trim();
    if (prompt.isEmpty || _running) return;
    setState(() {
      _messages.add(_ChatMessage(role: _MessageRole.user, text: prompt));
      _input.clear();
    });
    _persistSession();
    unawaited(FlutenRuntimeScope.read(context).setActivePromptDraft(prompt));
    _recordEvent('Сообщение отправлено в ${_provider.name}');

    switch (_provider.mode) {
      case TextRouteMode.localOllama:
        await _runOllama(prompt);
      case TextRouteMode.browser:
        await _prepareInlineHandoff(prompt);
      case TextRouteMode.apiPlaceholder:
        if (_provider.id == 'openrouter-api') {
          await _runOpenAiCompatibleProvider(
            prompt,
            const _OpenAiCompatibleProviderConfig(
              settingsProviderId: 'openrouter',
              providerName: 'OpenRouter',
              defaultModel: 'openai/gpt-4o-mini',
              defaultBaseUrl: 'https://openrouter.ai/api/v1',
              missingApiKeyMessage:
                  'Нужен API-ключ OpenRouter. Добавьте его в Настройки запуска.',
              missingApiKeySnack: 'Нужен API-ключ OpenRouter.',
            ),
          );
          return;
        }
        if (_provider.id == 'omniroute-api') {
          await _runOpenAiCompatibleProvider(
            prompt,
            const _OpenAiCompatibleProviderConfig(
              settingsProviderId: 'omniroute',
              providerName: 'OmniRoute',
              defaultModel: 'auto',
              defaultBaseUrl: 'http://localhost:3000/v1',
              missingApiKeyMessage:
                  'Нужен API-ключ OmniRoute или настроенный локальный endpoint.',
              missingApiKeySnack:
                  'Нужен API-ключ OmniRoute или настроенный локальный endpoint.',
              missingBaseUrlMessage:
                  'Укажи Base URL OmniRoute в Execution Settings.',
            ),
          );
          return;
        }
        _addAssistant(
          'API для этого провайдера пока не подключен. Используйте Browser route или Ollama.',
        );
        _recordEvent('API placeholder: ${_provider.name}');
      case TextRouteMode.manual:
        await Clipboard.setData(ClipboardData(text: prompt));
        _addAssistant('Manual mode: промпт скопирован в буфер.');
        _showMessage('Промпт скопирован.');
        _recordEvent('Manual prompt copied');
    }
  }

  Future<void> _runOpenAiCompatibleProvider(
    String prompt,
    _OpenAiCompatibleProviderConfig config,
  ) async {
    final settings = AppSettingsScope.of(context);
    final model = settings
        .providerModel(config.settingsProviderId, fallback: config.defaultModel)
        .trim();
    final configuredBaseUrl = settings.providerBaseUrl(
      config.settingsProviderId,
      fallback: config.defaultBaseUrl,
    );
    final baseUrl =
        configuredBaseUrl.trim().isEmpty &&
            config.settingsProviderId == 'omniroute'
        ? ''
        : _openAiCompatibleBaseUrl(
            configuredBaseUrl,
            fallback: config.defaultBaseUrl,
          );
    final apiKey = settings.providerApiKey(config.settingsProviderId).trim();
    final now = DateTime.now();
    final job = ExecutionJob(
      id: 'text-${config.settingsProviderId}-${now.microsecondsSinceEpoch}',
      workspace: ExecutionJobWorkspace.text,
      providerId: config.settingsProviderId,
      providerName: config.providerName,
      capability: 'textChat',
      inputPrompt: prompt,
      composedPrompt: prompt,
      status: apiKey.isEmpty || baseUrl.isEmpty
          ? ExecutionJobStatus.requiresApiKey
          : ExecutionJobStatus.running,
      executionMode: ExecutionJobMode.api,
      createdAt: now,
      updatedAt: now,
      errorMessage: apiKey.isEmpty
          ? config.missingApiKeySnack
          : baseUrl.isEmpty
          ? (config.missingBaseUrlMessage ?? 'Укажите Base URL.')
          : null,
      metadata: {
        'model': model.isEmpty ? config.defaultModel : model,
        'baseUrl': baseUrl,
        'settingsProviderId': config.settingsProviderId,
      },
    );
    ExecutionQueue.instance.add(job);

    if (apiKey.isEmpty || baseUrl.isEmpty) {
      _recordTextExecutionJob(job);
      final message = apiKey.isEmpty
          ? config.missingApiKeyMessage
          : config.missingBaseUrlMessage ?? 'Укажите Base URL.';
      _addAssistant(message);
      _showMessage(apiKey.isEmpty ? config.missingApiKeySnack : message);
      _recordEvent('${config.providerName} configuration missing');
      return;
    }

    setState(() => _running = true);
    _addAssistant('${config.providerName} отвечает...');
    _recordEvent('${config.providerName} request running');

    final result = await const OpenAiCompatibleTextService().completeChat(
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model.isEmpty ? config.defaultModel : model,
      messages: [
        const OpenAiChatMessage(
          role: 'system',
          content:
              'You are FLUTEN Text Brain. Answer clearly and help with creative production tasks. Do not claim image/video/audio generation.',
        ),
        OpenAiChatMessage(role: 'user', content: prompt),
      ],
      temperature: 0.7,
      maxTokens: 900,
      timeout: const Duration(seconds: 45),
      providerName: config.providerName,
    );
    if (!mounted) return;
    setState(() => _running = false);

    if (result.success && (result.content?.trim().isNotEmpty ?? false)) {
      final completed = ExecutionQueue.instance.update(
        job.copyWith(
          status: ExecutionJobStatus.completed,
          updatedAt: DateTime.now(),
          metadata: {
            ...job.metadata,
            if (result.responseId != null) 'responseId': result.responseId!,
            if (result.usage != null) ...result.usage!,
          },
        ),
      );
      _recordTextExecutionJob(completed, resultText: result.content);
      _addAssistant(result.content!);
      await FlutenRuntimeScope.read(context).addAsset(
        type: 'text',
        title: '${config.providerName} text response',
        description: result.content,
        sourceProvider: config.providerName,
        prompt: prompt,
        providerId: config.settingsProviderId,
        providerName: config.providerName,
        sourceWorkspace: 'text',
        notes: 'Model: ${completed.metadata['model']}',
        status: 'completed',
      );
      if (!mounted) return;
      _showMessage('Ответ получен через ${config.providerName}.');
      _recordEvent('${config.providerName} response received');
      return;
    }

    final error = result.error ?? '${config.providerName} request failed.';
    final failed = ExecutionQueue.instance.update(
      job.copyWith(
        status: ExecutionJobStatus.failed,
        updatedAt: DateTime.now(),
        errorMessage: error,
      ),
    );
    _recordTextExecutionJob(failed);
    _addAssistant('Ошибка ${config.providerName}: $error');
    _showMessage('Ошибка ${config.providerName}: $error');
    _recordEvent('${config.providerName} request failed');
  }

  Future<void> _runOllama(String prompt) async {
    final settings = AppSettingsScope.of(context);
    if (!settings.isLocalProviderEnabled('ollama')) {
      _addAssistant(
        'Ollama не включена в настройках запуска. Включите локальный провайдер Ollama или выберите Browser route.',
      );
      _recordEvent('Ollama unavailable');
      return;
    }
    if (settings.ollamaModel.trim().isEmpty) {
      _addAssistant('Выберите модель Ollama в настройках запуска.');
      _recordEvent('Ollama model missing');
      return;
    }
    setState(() => _running = true);
    _recordEvent('Ollama message sent');
    final result = await const OllamaExecutionService().generate(
      endpoint: settings.localEndpoint(
        'ollama',
        fallback: settings.ollamaBaseUrl,
      ),
      model: settings.ollamaModel,
      prompt: prompt,
    );
    if (!mounted) return;
    setState(() => _running = false);
    if (result.success && (result.response?.isNotEmpty ?? false)) {
      _addAssistant(result.response!);
      _recordEvent('Ollama response received');
      return;
    }
    _addAssistant(
      'Локальная модель не отвечает. Запустите Ollama или выберите Browser mode.',
    );
    _recordEvent('Ollama unavailable');
  }

  void _recordTextExecutionJob(ExecutionJob job, {String? resultText}) {
    unawaited(
      FlutenRuntimeScope.read(context).addGenerationJob(
        workspaceType: job.workspace.name,
        providerId: job.providerId,
        routeType: job.executionMode.name,
        prompt: job.inputPrompt,
        status: job.status.name,
        resultLabel: job.status == ExecutionJobStatus.completed
            ? '${job.providerName} text response'
            : '${job.providerName}: ${job.status.label}',
        resultUrl: null,
      ),
    );
    if (resultText != null && resultText.trim().isNotEmpty) {
      unawaited(
        FlutenRuntimeScope.read(context).addEvent(
          type: 'text',
          title: '${job.providerName} text result saved',
          detail: _previewText(resultText, 120),
        ),
      );
    }
  }

  String _openAiCompatibleBaseUrl(String value, {required String fallback}) {
    final raw = value.trim().isEmpty ? fallback : value.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null) return fallback;
    final host = uri.host.toLowerCase();
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (host == 'openrouter.ai' && (path.isEmpty || path == '/')) {
      return 'https://openrouter.ai/api/v1';
    }
    return raw.replaceFirst(RegExp(r'/+$'), '');
  }

  String _previewText(String value, int maxLength) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength)}...';
  }

  Future<void> _prepareInlineHandoff(String prompt) async {
    final tool = _browserToolForProvider(_provider);
    if (tool == null) {
      await Clipboard.setData(ClipboardData(text: prompt));
      if (!mounted) return;
      _addAssistant(
        'Browser handoff подготовлен, но сервис не найден. Промпт скопирован.',
      );
      _showMessage('Промпт скопирован.');
      return;
    }
    final runtime = FlutenRuntimeScope.read(context);
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    setState(() {
      _handoff = _BrowserHandoff(tool: tool, prompt: prompt);
      _showInlineWebViewPlaceholder = false;
      _messages.add(
        _ChatMessage(
          role: _MessageRole.assistant,
          text: prompt,
          kind: _MessageKind.browserHandoff,
          handoff: _handoff,
        ),
      );
    });
    unawaited(
      runtime.addGenerationJob(
        workspaceType: 'browser',
        providerId: tool.id,
        routeType: 'browser',
        prompt: prompt,
        status: 'prepared',
        resultLabel: 'Browser handoff prepared',
        resultUrl: tool.url,
      ),
    );
    _addAssistant(
      'Browser handoff готов для ${tool.name}. API-ответ не имитируется: откройте сервис и вставьте промпт вручную.',
    );
    _showMessage('Промпт скопирован. Handoff panel обновлена.');
  }

  Future<void> _buildImagePrompt() async {
    final builderSource = getPromptBuilderSource();
    if (builderSource == null) {
      _requestPromptBuilderSource();
      return;
    }
    _recordEvent('Prompt source selected: ${builderSource.label}');
    if (_provider.mode == TextRouteMode.browser) {
      await _preparePromptBuilderHandoff(
        source: builderSource.text,
        target: _PromptDraftTarget.image,
      );
      return;
    }
    final prompt = await _buildPromptWithBestAvailableRoute(
      source: builderSource.text,
      target: _PromptDraftTarget.image,
    );
    if (!mounted) return;
    _addPromptDraft(prompt, _PromptDraftTarget.image, builderSource.label);
    unawaited(FlutenRuntimeScope.read(context).setActivePromptDraft(prompt));
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    _recordEvent('Image prompt generated');
    _showMessage('Image Prompt собран и скопирован.');
  }

  Future<void> _buildVideoPrompt() async {
    final builderSource = getPromptBuilderSource();
    if (builderSource == null) {
      _requestPromptBuilderSource();
      return;
    }
    _recordEvent('Prompt source selected: ${builderSource.label}');
    if (_provider.mode == TextRouteMode.browser) {
      await _preparePromptBuilderHandoff(
        source: builderSource.text,
        target: _PromptDraftTarget.video,
      );
      return;
    }
    final prompt = await _buildPromptWithBestAvailableRoute(
      source: builderSource.text,
      target: _PromptDraftTarget.video,
    );
    if (!mounted) return;
    _addPromptDraft(prompt, _PromptDraftTarget.video, builderSource.label);
    unawaited(FlutenRuntimeScope.read(context).setActivePromptDraft(prompt));
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    _recordEvent('Video prompt generated');
    _showMessage('Video Prompt собран и скопирован.');
  }

  Future<String> _buildPromptWithBestAvailableRoute({
    required String source,
    required _PromptDraftTarget target,
  }) async {
    final fallback = target == _PromptDraftTarget.image
        ? _buildLocalImagePrompt(source)
        : _buildLocalVideoPrompt(source);
    if (_provider.mode != TextRouteMode.localOllama) {
      _recordEvent('Fallback template used');
      _addAssistant(
        'Собрано локальным шаблоном. Для более сильной сборки включите Ollama.',
      );
      return fallback;
    }
    final settings = AppSettingsScope.of(context);
    final instruction = target == _PromptDraftTarget.image
        ? _imagePromptBuilderInstruction(source)
        : _videoPromptBuilderInstruction(source);

    setState(() => _running = true);
    final result = await const OllamaPromptBrainService().improve(
      settings: settings,
      workspace: ExecutionJobWorkspace.text,
      source: source,
      instruction: instruction,
      fallback: fallback,
      capability: target == _PromptDraftTarget.image
          ? 'promptBuilder.image'
          : 'promptBuilder.video',
    );
    if (!mounted) return fallback;
    setState(() => _running = false);
    if (result.usedOllama) {
      _recordEvent('Ollama prompt builder used');
      _addAssistant('Prompt улучшен через Ollama');
    } else {
      _recordEvent('Fallback template used');
      _addAssistant(result.message);
    }
    return result.text.trim();
  }

  Future<void> _preparePromptBuilderHandoff({
    required String source,
    required _PromptDraftTarget target,
  }) async {
    final tool = _browserToolForProvider(_provider);
    if (tool == null) {
      _showMessage('Сервис для browser handoff не найден.');
      return;
    }
    final instruction = target == _PromptDraftTarget.image
        ? _imagePromptBuilderInstruction(source)
        : _videoPromptBuilderInstruction(source);
    await Clipboard.setData(ClipboardData(text: instruction));
    if (!mounted) return;
    setState(() {
      _handoff = _BrowserHandoff(tool: tool, prompt: instruction);
      _showInlineWebViewPlaceholder = false;
      _messages.add(
        _ChatMessage(
          role: _MessageRole.assistant,
          text: instruction,
          kind: _MessageKind.browserHandoff,
          handoff: _handoff,
        ),
      );
    });
    _recordEvent(
      target == _PromptDraftTarget.image
          ? 'Image prompt builder browser handoff prepared'
          : 'Video prompt builder browser handoff prepared',
    );
    _showMessage('Browser handoff подготовлен. Промпт скопирован.');
  }

  String _imagePromptBuilderInstruction(String source) {
    return '''
You are FLUTEN Visual Engine. Build a production-ready image generation prompt from this user idea:
$source

Return a structured prompt with:
- subject
- environment
- visual style
- composition
- lighting
- mood
- camera/framing
- quality/detail
- optional negative prompt
- final clean prompt

Do not invent a different idea. Make the result specific, cinematic, and directly usable in an image model.
''';
  }

  String _videoPromptBuilderInstruction(String source) {
    return '''
You are FLUTEN Director Engine. Build a cinematic video generation prompt from this user idea:
$source

Return a structured prompt with:
- scene
- action
- camera movement
- shot duration
- pacing
- lighting
- mood
- continuity
- final gesture / ending beat
- final clean prompt

Use these principles:
- camera movement only with dramatic reason
- blocking stronger than prompting
- depth stronger than chaos
- emotional rhythm controls attention
- final gesture redefines the scene

Do not invent a different idea. Make the result specific and directly usable in a video model.
''';
  }

  String _buildLocalImagePrompt(String source) {
    return '''
Image production prompt
Subject: $source
Environment: cinematic urban or story-relevant space with readable foreground, midground, and background
Visual style: cinematic AI creative studio, premium production look, grounded detail
Composition: clear focal subject, strong silhouette, layered depth, no visual clutter
Lighting: controlled cinematic light, soft contrast, practical highlights, motivated shadows
Mood: atmospheric, polished, emotionally clear
Camera / framing: intentional frame, subject readable, lens-like perspective, stable composition
Quality / detail: high detail, clean edges, coherent anatomy, production-ready image
Negative prompt: low quality, blurry, distorted anatomy, unreadable text, artifacts, random objects
Final clean prompt: $source, cinematic production still, layered depth, motivated lighting, clear subject, premium detail, coherent composition
''';
  }

  String _buildLocalVideoPrompt(String source) {
    return '''
Video production prompt
Scene: $source
Action: one clear action beat with readable blocking and a motivated change in the scene
Camera movement: deliberate cinematic move only if it reveals emotion, space, or story
Shot duration: 5-8 seconds, opening frame, middle movement, final hold
Pacing: calm setup, controlled movement, clear ending beat
Lighting: coherent cinematic light, motivated shadows, readable subject separation
Mood: cinematic, emotionally focused, atmospheric without chaos
Continuity: keep subject, style, lens, environment, wardrobe, and lighting consistent
Final gesture / ending beat: a small action or reveal that redefines the moment
Final clean prompt: $source, cinematic short video shot, strong blocking, layered depth, motivated camera movement, emotional rhythm, coherent continuity, final gesture
''';
  }

  Future<void> _copyCurrentText() async {
    final text = _currentText();
    if (text.trim().isEmpty) {
      _showMessage('Нет текста для копирования.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text.trim()));
    if (!mounted) return;
    _showMessage('Скопировано.');
  }

  Future<void> _copyHandoffPrompt() async {
    final handoff = _handoff;
    if (handoff == null) return;
    await Clipboard.setData(ClipboardData(text: handoff.prompt));
    if (!mounted) return;
    _showMessage('Промпт скопирован.');
  }

  Future<void> _copyText(String text) async {
    if (text.trim().isEmpty) {
      _showMessage('Нет текста для копирования.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text.trim()));
    if (!mounted) return;
    _showMessage('Скопировано.');
    _recordEvent('Prompt copied');
  }

  Future<void> _openHandoffExternalFor(_BrowserHandoff handoff) async {
    _handoff = handoff;
    await _openHandoffExternal();
    _recordEvent('External browser opened: ${handoff.tool.name}');
  }

  void _openHandoffInsideFor(_BrowserHandoff handoff) {
    _handoff = handoff;
    _openHandoffInside();
    _recordEvent('Internal WebView placeholder shown: ${handoff.tool.name}');
  }

  void _saveManualHandoffFor(_BrowserHandoff handoff) {
    _handoff = handoff;
    _saveManualHandoff();
    _recordEvent('Manual result note saved: ${handoff.tool.name}');
  }

  Future<void> _openHandoffInBrowserHub(_BrowserHandoff handoff) async {
    _handoff = handoff;
    await _openInBrowserHub();
  }

  Future<void> _openHandoffExternal() async {
    final handoff = _handoff;
    if (handoff == null) return;
    unawaited(
      FlutenRuntimeScope.read(
        context,
      ).setActiveProvider(handoff.tool.id, route: 'browser'),
    );
    final opened = await launchUrl(
      Uri.parse(handoff.tool.url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (opened) {
      _showMessage('${handoff.tool.name} открыт во внешнем браузере.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: handoff.tool.url));
    if (!mounted) return;
    _showMessage('Не удалось открыть сайт. Ссылка скопирована.');
  }

  void _openHandoffInside() {
    setState(() => _showInlineWebViewPlaceholder = true);
    _showMessage(
      'Встроенный браузер будет доступен после подключения desktop WebView runtime.',
    );
  }

  void _saveManualHandoff() {
    final handoff = _handoff;
    if (handoff != null) {
      unawaited(
        FlutenRuntimeScope.read(context).addAsset(
          type: 'manual',
          title: '${handoff.tool.name} manual result',
          description: handoff.prompt,
          sourceProvider: handoff.tool.id,
          url: handoff.tool.url,
        ),
      );
    }
    _showMessage('Результат можно сохранить вручную после генерации.');
  }

  Future<void> _sendCurrentToImageStudio() async {
    await _sendTextToImageStudio(_currentText());
  }

  Future<void> _sendCurrentToVideoStudio() async {
    await _sendTextToVideoStudio(_currentText());
  }

  Future<void> _sendTextToImageStudio(String text) async {
    await _sendTextToStudio(
      text: text,
      destination: AppDestination.images,
      studioName: 'Image Studio',
      eventName: 'AI Chat image prompt sent to Image Studio',
      setDraft: AppSettingsScope.of(context).setImagePromptDraft,
      sentMessage: 'Промпт отправлен в Image Studio',
    );
  }

  Future<void> _sendTextToVideoStudio(String text) async {
    await _sendTextToStudio(
      text: text,
      destination: AppDestination.video,
      studioName: 'Video Studio',
      eventName: 'AI Chat video prompt sent to Video Studio',
      setDraft: AppSettingsScope.of(context).setVideoPromptDraft,
      sentMessage: 'Промпт отправлен в Video Studio',
    );
  }

  Future<void> _sendTextToStudio({
    required String text,
    required AppDestination destination,
    required String studioName,
    required String eventName,
    required ValueChanged<String> setDraft,
    required String sentMessage,
  }) async {
    if (text.trim().isEmpty) {
      _showMessage('Сначала подготовьте промпт.');
      return;
    }
    setDraft(text.trim());
    unawaited(
      FlutenRuntimeScope.read(context).setActivePromptDraft(text.trim()),
    );
    unawaited(Clipboard.setData(ClipboardData(text: text.trim())));

    _showMessage(sentMessage);
    unawaited(
      FlutenRuntimeScope.read(
        context,
      ).addEvent(type: 'handoff', title: eventName, detail: studioName),
    );
    _recordEvent(eventName);
    widget.onNavigate(destination);
  }

  Future<void> _openInBrowserHub() async {
    final text = _handoff?.prompt ?? _currentText();
    if (text.trim().isEmpty) {
      _showMessage('Сначала введите или выберите текст.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text.trim()));
    if (!mounted) return;
    final settings = AppSettingsScope.of(context);
    final tool = _handoff?.tool ?? _browserToolForProvider(_provider);
    settings.setBrowserHandoff(prompt: text.trim(), toolId: tool?.id);
    unawaited(
      FlutenRuntimeScope.read(context).addGenerationJob(
        workspaceType: 'browser',
        providerId: tool?.id,
        routeType: 'browser',
        prompt: text.trim(),
        status: 'prepared',
        resultLabel: 'Browser Hub handoff',
        resultUrl: tool?.url,
      ),
    );
    _showMessage('Промпт скопирован. Открываю Browser Hub.');
    widget.onNavigate(AppDestination.browserHub);
  }

  void _addPromptDraft(
    String text,
    _PromptDraftTarget target,
    String sourceLabel,
  ) {
    setState(() {
      _messages.add(
        _ChatMessage(
          role: _MessageRole.assistant,
          text: text,
          kind: _MessageKind.promptDraft,
          draftTarget: target,
          sourceLabel: sourceLabel,
        ),
      );
    });
    _persistSession();
  }

  void _recordEvent(String label) {
    setState(() {
      _events.insert(0, _SessionEvent(label: label, createdAt: DateTime.now()));
      if (_events.length > 12) _events.removeLast();
    });
    _persistSession();
    unawaited(
      FlutenRuntimeScope.read(context).addEvent(type: 'text', title: label),
    );
  }

  void _showAttachmentPlaceholder() {
    _showMessage('Файлы будут подключены позже.');
  }

  void _addAssistant(String text) {
    final displayText = _normalizeUiMessage(text);
    setState(() {
      _messages.add(
        _ChatMessage(role: _MessageRole.assistant, text: displayText),
      );
    });
    _persistSession();
  }

  String _currentText() {
    final input = _input.text.trim();
    if (input.isNotEmpty) return input;
    for (final message in _messages.reversed) {
      if (message.role == _MessageRole.user && message.text.trim().isNotEmpty) {
        return message.text;
      }
    }
    for (final message in _messages.reversed) {
      if (message.kind == _MessageKind.promptDraft &&
          message.text.trim().isNotEmpty) {
        return message.text;
      }
    }
    return '';
  }

  _PromptBuilderSource? getPromptBuilderSource() {
    final input = _input.text.trim();
    if (_isValidPromptBuilderSource(input)) {
      return _PromptBuilderSource(text: input, label: 'Источник: текущий ввод');
    }
    for (final message in _messages.reversed) {
      final text = message.text.trim();
      if (message.role == _MessageRole.user &&
          _isValidPromptBuilderSource(text)) {
        return _PromptBuilderSource(
          text: text,
          label: 'Источник: последнее сообщение пользователя',
        );
      }
    }
    for (final message in _messages.reversed) {
      final text = message.text.trim();
      if (message.kind == _MessageKind.promptDraft &&
          message.draftTarget != null &&
          _isValidPromptBuilderSource(text)) {
        return _PromptBuilderSource(
          text: text,
          label: 'Источник: выбранный draft',
        );
      }
    }
    return null;
  }

  bool _isValidPromptBuilderSource(String value) {
    final text = value.trim();
    if (text.isEmpty) return false;
    final normalized = text.toLowerCase();
    const blocked = [
      'browser handoff',
      'api placeholder',
      'manual mode',
      'ollama unavailable',
      'runtime',
      'placeholder',
      'опиши идею',
      'промпт получен',
      'сервис выбран',
      'prompt copied',
    ];
    return !blocked.any(normalized.contains);
  }

  void _requestPromptBuilderSource() {
    const message =
        'Опиши идею, сцену или задачу, и я соберу production prompt.';
    _addAssistant(message);
    _showMessage(message);
  }

  BrowserAiTool? _browserToolForProvider(TextAiProvider provider) {
    final id = provider.browserToolId;
    if (id == null) return null;
    for (final tool in browserAiTools) {
      if (tool.id == id) return tool;
    }
    return null;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_normalizeUiMessage(text))));
  }

  String _normalizeUiMessage(String text) {
    if (text.contains('production prompt') && text.contains('Оп')) {
      return 'Опиши идею, сцену или задачу, и я соберу production prompt.';
    }
    return text;
  }
}

class _BrowserHandoff {
  const _BrowserHandoff({required this.tool, required this.prompt});

  final BrowserAiTool tool;
  final String prompt;
}

enum _MessageRole { user, assistant }

enum _MessageKind { plain, promptDraft, browserHandoff }

enum _PromptDraftTarget { image, video }

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.text,
    this.kind = _MessageKind.plain,
    this.handoff,
    this.draftTarget,
    this.sourceLabel,
  });

  final _MessageRole role;
  final String text;
  final _MessageKind kind;
  final _BrowserHandoff? handoff;
  final _PromptDraftTarget? draftTarget;
  final String? sourceLabel;
}

class _SessionEvent {
  const _SessionEvent({required this.label, required this.createdAt});

  final String label;
  final DateTime createdAt;
}

class _PromptBuilderSource {
  const _PromptBuilderSource({required this.text, required this.label});

  final String text;
  final String label;
}

class _Header extends StatelessWidget {
  const _Header({required this.provider, required this.settings});

  final TextAiProvider provider;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TEXT BRAIN',
                style: TextStyle(
                  color: Color(0xFFC8FFF4),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI Чат и Prompt Builder',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Сценарии, структуры роликов, production prompts и подготовка текста для Image / Video / Browser Hub.',
                style: TextStyle(color: Color(0xFFA7B1C1), height: 1.4),
              ),
            ],
          ),
        ),
        _StatusCard(provider: provider, settings: settings),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.provider, required this.settings});

  final TextAiProvider provider;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final settingsProviderId = _settingsProviderIdForTextProvider(provider);
    final modelLabel = settingsProviderId == null
        ? null
        : settings.providerModel(
            settingsProviderId,
            fallback: _defaultModelForTextProvider(provider),
          );
    return Container(
      width: 340,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xA6080B10),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            provider.mode == TextRouteMode.localOllama
                ? '${provider.mode.label} · ${settings.ollamaModel}'
                : settingsProviderId != null
                ? '${provider.name} · $modelLabel'
                : provider.mode.label,
            style: const TextStyle(color: Color(0xFF67E8F9)),
          ),
          const SizedBox(height: 6),
          Text(
            provider.mode.description,
            style: const TextStyle(color: Color(0xFF9AA6B8), height: 1.35),
          ),
          if (provider.mode == TextRouteMode.localOllama) ...[
            const SizedBox(height: 8),
            const Text(
              'Локальная модель видит только отправленный текст. Контекст приложения будет подключён позже.',
              style: TextStyle(color: Color(0xFFFFB86B), height: 1.35),
            ),
          ],
          if (settingsProviderId != null) ...[
            const SizedBox(height: 8),
            Text(
              settings.hasProviderApiKey(settingsProviderId)
                  ? 'API-ключ ${provider.name} настроен. Реальный text execution включён.'
                  : 'Нужен API-ключ ${provider.name} в Настройки запуска.',
              style: const TextStyle(color: Color(0xFFFFB86B), height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.messages,
    required this.onCopy,
    required this.onOpenExternal,
    required this.onOpenInside,
    required this.onOpenHub,
    required this.onSaveManual,
    required this.onSendImage,
    required this.onSendVideo,
  });

  final List<_ChatMessage> messages;
  final ValueChanged<String> onCopy;
  final ValueChanged<_BrowserHandoff> onOpenExternal;
  final ValueChanged<_BrowserHandoff> onOpenInside;
  final ValueChanged<_BrowserHandoff> onOpenHub;
  final ValueChanged<_BrowserHandoff> onSaveManual;
  final ValueChanged<String> onSendImage;
  final ValueChanged<String> onSendVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xBF05070B),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: messages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final message = messages[index];
          if (message.kind == _MessageKind.browserHandoff &&
              message.handoff != null) {
            return _HandoffMessageCard(
              handoff: message.handoff!,
              onCopy: () => onCopy(message.handoff!.prompt),
              onOpenExternal: () => onOpenExternal(message.handoff!),
              onOpenInside: () => onOpenInside(message.handoff!),
              onOpenHub: () => onOpenHub(message.handoff!),
              onSaveManual: () => onSaveManual(message.handoff!),
            );
          }
          if (message.kind == _MessageKind.promptDraft) {
            return _PromptDraftCard(
              message: message,
              onCopy: () => onCopy(message.text),
              onSendImage: () => onSendImage(message.text),
              onSendVideo: () => onSendVideo(message.text),
            );
          }
          return _MessageBubble(message: message);
        },
      ),
    );
  }
}

class _HandoffMessageCard extends StatelessWidget {
  const _HandoffMessageCard({
    required this.handoff,
    required this.onCopy,
    required this.onOpenExternal,
    required this.onOpenInside,
    required this.onOpenHub,
    required this.onSaveManual,
  });

  final _BrowserHandoff handoff;
  final VoidCallback onCopy;
  final VoidCallback onOpenExternal;
  final VoidCallback onOpenInside;
  final VoidCallback onOpenHub;
  final VoidCallback onSaveManual;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x990B0F16),
          border: Border.all(color: const Color(0x33C8FFF4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Browser handoff: ${handoff.tool.name}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              handoff.tool.url,
              style: const TextStyle(color: Color(0xFF67E8F9), fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'API-ответ не имитируется. Скопируйте промпт, откройте сервис и вставьте вручную.',
              style: TextStyle(color: Color(0xFFA7B1C1), height: 1.35),
            ),
            const SizedBox(height: 8),
            SelectableText(
              handoff.prompt,
              style: const TextStyle(color: Color(0xFFE8EEF8), height: 1.35),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                FilledButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать промпт'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenExternal,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Открыть во внешнем браузере'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenInside,
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Открыть внутри STUDIO'),
                ),
                OutlinedButton.icon(
                  onPressed: onSaveManual,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Сохранить результат вручную'),
                ),
                TextButton.icon(
                  onPressed: onOpenHub,
                  icon: const Icon(Icons.public_rounded),
                  label: const Text('Открыть в Browser Hub'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptDraftCard extends StatelessWidget {
  const _PromptDraftCard({
    required this.message,
    required this.onCopy,
    required this.onSendImage,
    required this.onSendVideo,
  });

  final _ChatMessage message;
  final VoidCallback onCopy;
  final VoidCallback onSendImage;
  final VoidCallback onSendVideo;

  @override
  Widget build(BuildContext context) {
    final isImage = message.draftTarget == _PromptDraftTarget.image;
    final sourceLabel = _readableSourceLabel(message.sourceLabel);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x990B0F16),
          border: Border.all(color: const Color(0x24FFFFFF)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isImage ? 'Image Prompt' : 'Video Prompt',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (sourceLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                sourceLabel,
                style: const TextStyle(
                  color: Color(0xFF8B97A8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SelectableText(
              message.text,
              style: const TextStyle(color: Color(0xFFE8EEF8), height: 1.45),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                FilledButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать'),
                ),
                OutlinedButton.icon(
                  onPressed: onSendImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Отправить в Image Studio'),
                ),
                OutlinedButton.icon(
                  onPressed: onSendVideo,
                  icon: const Icon(Icons.movie_creation_outlined),
                  label: const Text('Отправить в Video Studio'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String? _readableSourceLabel(String? value) {
  if (value == null) return null;
  if (value.contains('draft')) {
    return 'Источник: выбранный draft';
  }
  if (value.contains('вв')) {
    return 'Источник: текущий ввод';
  }
  if (value.contains('пос')) {
    return 'Источник: последнее сообщение пользователя';
  }
  return value;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.role == _MessageRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: user ? const Color(0xB812343B) : const Color(0x990B0F16),
          border: Border.all(
            color: user ? const Color(0x6638BDF8) : const Color(0x24FFFFFF),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          message.text,
          style: const TextStyle(color: Color(0xFFE8EEF8), height: 1.45),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.providerId,
    required this.onProviderChanged,
    required this.onImagePrompt,
    required this.onVideoPrompt,
    required this.onCopy,
    required this.onBrowserHub,
    required this.onSendImage,
    required this.onSendVideo,
    required this.events,
  });

  final String providerId;
  final ValueChanged<String> onProviderChanged;
  final VoidCallback onImagePrompt;
  final VoidCallback onVideoPrompt;
  final VoidCallback onCopy;
  final VoidCallback onBrowserHub;
  final VoidCallback onSendImage;
  final VoidCallback onSendVideo;
  final List<_SessionEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xA6080B10),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        children: [
          const Text(
            'Провайдер текста',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: providerId,
            isExpanded: true,
            dropdownColor: const Color(0xFF0B0F16),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.hub_outlined),
            ),
            items: [
              for (final provider in textAiProviders)
                DropdownMenuItem(
                  value: provider.id,
                  child: Text(
                    '${provider.name} · ${provider.mode.label}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) onProviderChanged(value);
            },
          ),
          const SizedBox(height: 16),
          const _AttachmentNotice(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onImagePrompt,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Собрать Image Prompt'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onVideoPrompt,
            icon: const Icon(Icons.movie_creation_outlined),
            label: const Text('Собрать Video Prompt'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Скопировать'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onBrowserHub,
            icon: const Icon(Icons.public_rounded),
            label: const Text('Открыть в Browser Hub'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onSendImage,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Отправить в Image Studio'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onSendVideo,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Отправить в Video Studio'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Session events',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const Text(
              'Событий пока нет.',
              style: TextStyle(color: Color(0xFF8B97A8)),
            )
          else
            for (final event in events.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  event.label,
                  style: const TextStyle(
                    color: Color(0xFFA7B1C1),
                    fontSize: 12,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _InlineHandoffPanel extends StatelessWidget {
  const _InlineHandoffPanel({
    required this.handoff,
    required this.showWebViewPlaceholder,
    required this.onCopy,
    required this.onOpenExternal,
    required this.onOpenInside,
    required this.onSaveManual,
    required this.onOpenHub,
  });

  final _BrowserHandoff handoff;
  final bool showWebViewPlaceholder;
  final VoidCallback onCopy;
  final VoidCallback onOpenExternal;
  final VoidCallback onOpenInside;
  final VoidCallback onSaveManual;
  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC080B10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListView(
        children: [
          Text(
            handoff.tool.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            handoff.tool.url,
            style: const TextStyle(
              color: Color(0xFF67E8F9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              showWebViewPlaceholder
                  ? 'Встроенный браузер будет доступен после подключения desktop WebView runtime.'
                  : 'Handoff готов. API-ответ не имитируется: скопируйте промпт, откройте сервис и вставьте вручную.',
              style: const TextStyle(color: Color(0xFFA7B1C1), height: 1.35),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Подготовленный промпт',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              handoff.prompt,
              style: const TextStyle(color: Color(0xFFE8EEF8), height: 1.35),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Скопировать промпт'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpenExternal,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Открыть во внешнем браузере'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpenInside,
            icon: const Icon(Icons.open_in_browser_rounded),
            label: const Text('Открыть внутри STUDIO'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onSaveManual,
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Сохранить результат вручную'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onOpenHub,
            icon: const Icon(Icons.public_rounded),
            label: const Text('Открыть в Browser Hub'),
          ),
        ],
      ),
    );
  }
}

class _AttachmentNotice extends StatelessWidget {
  const _AttachmentNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.attach_file_rounded, color: Color(0xFF8B97A8)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Файлы будут подключены позже.',
              style: TextStyle(color: Color(0xFF9AA6B8), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.running,
    required this.provider,
    required this.onSend,
    required this.onAttach,
    required this.onImage,
    required this.onVideo,
  });

  final TextEditingController controller;
  final bool running;
  final TextAiProvider provider;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onImage;
  final VoidCallback onVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xB80B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText:
                  'Напишите задачу, идею, сценарий, структуру ролика или сырой промпт...',
              border: InputBorder.none,
            ),
            onSubmitted: (_) => onSend(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: running ? null : onSend,
                icon: running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  provider.mode == TextRouteMode.browser
                      ? 'Подготовить handoff'
                      : 'Отправить',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAttach,
                icon: const Icon(Icons.attach_file_rounded),
                label: const Text('Файлы: скоро'),
              ),
              OutlinedButton.icon(
                onPressed: onImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Image Prompt'),
              ),
              OutlinedButton.icon(
                onPressed: onVideo,
                icon: const Icon(Icons.movie_creation_outlined),
                label: const Text('Video Prompt'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
