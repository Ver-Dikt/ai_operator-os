import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ai_operator_app.dart';
import '../../data/seed_browser_ai_tools.dart';
import '../../models/browser_ai_tool.dart';
import '../../services/ollama_execution_service.dart';
import '../../state/app_settings.dart';

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

class TextWorkspaceScreen extends StatefulWidget {
  const TextWorkspaceScreen({super.key, required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  State<TextWorkspaceScreen> createState() => _TextWorkspaceScreenState();
}

class _TextWorkspaceScreenState extends State<TextWorkspaceScreen> {
  final _input = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      role: _MessageRole.assistant,
      text:
          'Здесь можно собрать сценарий, промпт, структуру ролика или production prompt.',
    ),
  ];

  String _providerId = textAiProviders.first.id;
  bool _running = false;
  _BrowserHandoff? _handoff;
  bool _showInlineWebViewPlaceholder = false;

  TextAiProvider get _provider =>
      textAiProviders.firstWhere((item) => item.id == _providerId);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
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
                  Expanded(
                    child: compact
                        ? Column(
                            children: [
                              Expanded(child: _ChatPanel(messages: _messages)),
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
                                  onImagePrompt: _buildImagePrompt,
                                  onVideoPrompt: _buildVideoPrompt,
                                  onCopy: _copyCurrentText,
                                  onBrowserHub: _openInBrowserHub,
                                ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _ChatPanel(messages: _messages)),
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
                                        onImagePrompt: _buildImagePrompt,
                                        onVideoPrompt: _buildVideoPrompt,
                                        onCopy: _copyCurrentText,
                                        onBrowserHub: _openInBrowserHub,
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
                    onImage: _buildImagePrompt,
                    onVideo: _buildVideoPrompt,
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
  }

  Future<void> _send() async {
    final prompt = _input.text.trim();
    if (prompt.isEmpty || _running) return;
    setState(() {
      _messages.add(_ChatMessage(role: _MessageRole.user, text: prompt));
      _input.clear();
    });

    switch (_provider.mode) {
      case TextRouteMode.localOllama:
        await _runOllama(prompt);
      case TextRouteMode.browser:
        await _prepareInlineHandoff(prompt);
      case TextRouteMode.apiPlaceholder:
        _addAssistant(
          '${_provider.name}: API placeholder. Облачный API пока не подключен. Используйте Browser mode или Local Ollama.',
        );
      case TextRouteMode.manual:
        await Clipboard.setData(ClipboardData(text: prompt));
        _addAssistant('Manual mode: промпт скопирован в буфер.');
        _showMessage('Промпт скопирован.');
    }
  }

  Future<void> _runOllama(String prompt) async {
    final settings = AppSettingsScope.of(context);
    setState(() => _running = true);
    final result = await const OllamaExecutionService().generate(
      endpoint: settings.ollamaBaseUrl,
      model: settings.ollamaModel,
      prompt: prompt,
    );
    if (!mounted) return;
    setState(() => _running = false);
    if (result.success && (result.response?.isNotEmpty ?? false)) {
      _addAssistant(result.response!);
      return;
    }
    _addAssistant(
      'Локальная модель не отвечает. Запустите Ollama или выберите Browser mode.',
    );
  }

  Future<void> _prepareInlineHandoff(String prompt) async {
    final tool = _browserToolForProvider(_provider);
    if (tool == null) {
      await Clipboard.setData(ClipboardData(text: prompt));
      _addAssistant(
        'Browser handoff подготовлен, но сервис не найден. Промпт скопирован.',
      );
      _showMessage('Промпт скопирован.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: prompt));
    setState(() {
      _handoff = _BrowserHandoff(tool: tool, prompt: prompt);
      _showInlineWebViewPlaceholder = false;
    });
    _addAssistant(
      'Browser handoff готов для ${tool.name}. API-ответ не имитируется: откройте сервис и вставьте промпт вручную.',
    );
    _showMessage('Промпт скопирован. Handoff panel обновлена.');
  }

  void _buildImagePrompt() {
    final source = _currentText();
    if (source.trim().isEmpty) {
      _showMessage('Сначала введите текст для промпта.');
      return;
    }
    final prompt =
        'Image production prompt:\n$source\n\nVisual direction: cinematic composition, clear subject, controlled lighting, detailed environment, production-ready style, aspect ratio 16:9.';
    _addAssistant(prompt);
    Clipboard.setData(ClipboardData(text: prompt));
    _showMessage('Image Prompt собран и скопирован.');
  }

  void _buildVideoPrompt() {
    final source = _currentText();
    if (source.trim().isEmpty) {
      _showMessage('Сначала введите текст для промпта.');
      return;
    }
    final prompt =
        'Video production prompt:\n$source\n\nStructure: opening frame, subject action, camera movement, pacing, lighting, final gesture. Add duration, aspect ratio, start frame and end frame before generation.';
    _addAssistant(prompt);
    Clipboard.setData(ClipboardData(text: prompt));
    _showMessage('Video Prompt собран и скопирован.');
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

  Future<void> _openHandoffExternal() async {
    final handoff = _handoff;
    if (handoff == null) return;
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
    _showMessage('Результат можно сохранить вручную после генерации.');
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
    _showMessage('Промпт скопирован. Открываю Browser Hub.');
    widget.onNavigate(AppDestination.browserHub);
  }

  void _showAttachmentPlaceholder() {
    _showMessage('Файлы будут подключены позже.');
  }

  void _addAssistant(String text) {
    setState(() {
      _messages.add(_ChatMessage(role: _MessageRole.assistant, text: text));
    });
  }

  String _currentText() {
    final input = _input.text.trim();
    if (input.isNotEmpty) return input;
    for (final message in _messages.reversed) {
      if (message.text.trim().isNotEmpty) return message.text;
    }
    return '';
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _BrowserHandoff {
  const _BrowserHandoff({required this.tool, required this.prompt});

  final BrowserAiTool tool;
  final String prompt;
}

enum _MessageRole { user, assistant }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});

  final _MessageRole role;
  final String text;
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
        ],
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({required this.messages});

  final List<_ChatMessage> messages;

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
        itemBuilder: (context, index) =>
            _MessageBubble(message: messages[index]),
      ),
    );
  }
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
  });

  final String providerId;
  final ValueChanged<String> onProviderChanged;
  final VoidCallback onImagePrompt;
  final VoidCallback onVideoPrompt;
  final VoidCallback onCopy;
  final VoidCallback onBrowserHub;

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
