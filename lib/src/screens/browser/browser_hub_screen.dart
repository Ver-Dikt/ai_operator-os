import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ai_operator_app.dart';
import '../../data/seed_browser_ai_tools.dart';
import '../../models/browser_ai_tool.dart';
import '../../widgets/current_session_strip.dart';

class BrowserHubScreen extends StatefulWidget {
  const BrowserHubScreen({super.key});

  @override
  State<BrowserHubScreen> createState() => _BrowserHubScreenState();
}

class _BrowserHubScreenState extends State<BrowserHubScreen> {
  final _promptController = TextEditingController(
    text:
        'Собери кинематографичную идею для короткого vertical video: герой, локация, свет, движение камеры, настроение, 3 варианта хука.',
  );
  final _searchController = TextEditingController();

  BrowserAiCategory? _category;
  late BrowserAiTool _selectedTool;
  bool _handoffLoaded = false;
  bool _showInternalPlaceholder = false;
  bool _runtimeWorkspaceOpened = false;
  String _statusText =
      'Сервис выбран. Можно открыть сайт во внешнем браузере или подготовить prompt handoff.';

  @override
  void initState() {
    super.initState();
    _selectedTool = browserAiTools.first;
  }

  @override
  void dispose() {
    _promptController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_runtimeWorkspaceOpened) {
      _runtimeWorkspaceOpened = true;
      unawaited(
        FlutenRuntimeScope.read(context).updateCurrentWorkspace('browser'),
      );
    }
    if (_handoffLoaded) return;
    _handoffLoaded = true;
    final settings = AppSettingsScope.of(context);
    final prompt = settings.pendingBrowserPrompt;
    if (prompt == null || prompt.trim().isEmpty) return;
    final toolId = settings.pendingBrowserToolId;
    final tool = _toolById(toolId);
    setState(() {
      _promptController.text = prompt;
      if (tool != null) _selectedTool = tool;
      _showInternalPlaceholder = false;
      _statusText =
          'Промпт получен из AI Чата. Можно открыть сайт во внешнем браузере или подготовить prompt handoff.';
    });
    unawaited(FlutenRuntimeScope.read(context).setActivePromptDraft(prompt));
    if (tool != null) {
      unawaited(
        FlutenRuntimeScope.read(context).setActiveProvider(
          tool.id,
          route: 'browser',
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) settings.clearBrowserHandoff();
    });
  }

  BrowserAiTool? _toolById(String? id) {
    if (id == null) return null;
    for (final tool in browserAiTools) {
      if (tool.id == id) return tool;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [Color(0xFF101821), Color(0xFF050609)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          final toolsPanel = _ToolsPanel(
            selectedTool: _selectedTool,
            category: _category,
            searchController: _searchController,
            onCategoryChanged: (value) => setState(() => _category = value),
            onToolSelected: _selectTool,
            onCopyPrompt: _copyPrompt,
          );
          final workspace = _BrowserWorkspace(
            tool: _selectedTool,
            statusText: _statusText,
            showInternalPlaceholder: _showInternalPlaceholder,
            promptController: _promptController,
            onCopyPrompt: _copyPrompt,
            onOpenExternal: () => _openExternal(_selectedTool),
            onOpenInside: _openInside,
            onPreparePaste: _preparePaste,
            onSaveManualResult: _saveManualResult,
          );

          if (compact) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
              children: [
                const _HubHeader(),
                const SizedBox(height: 12),
                const CurrentSessionStrip(),
                const SizedBox(height: 12),
                SizedBox(height: 560, child: workspace),
                const SizedBox(height: 12),
                SizedBox(height: 720, child: toolsPanel),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HubHeader(),
                const SizedBox(height: 14),
                const CurrentSessionStrip(),
                const SizedBox(height: 14),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 366, child: toolsPanel),
                      const SizedBox(width: 12),
                      Expanded(child: workspace),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectTool(BrowserAiTool tool) {
    setState(() {
      _selectedTool = tool;
      _showInternalPlaceholder = false;
      _statusText =
          'Сервис выбран. Можно открыть сайт во внешнем браузере или подготовить prompt handoff.';
    });
    unawaited(
      FlutenRuntimeScope.read(context).setActiveProvider(
        tool.id,
        route: 'browser',
      ),
    );
    _showMessage('${tool.name}: сервис выбран.');
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(ClipboardData(text: _promptController.text.trim()));
    if (!mounted) return;
    _showMessage('Промпт скопирован в буфер.');
  }

  Future<void> _preparePaste() async {
    await Clipboard.setData(ClipboardData(text: _promptController.text.trim()));
    if (!mounted) return;
    _showMessage('Промпт скопирован. Вставьте его в открытом сервисе вручную.');
  }

  Future<void> _openExternal(BrowserAiTool tool) async {
    final opened = await launchUrl(
      Uri.parse(tool.url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (opened) {
      unawaited(
        FlutenRuntimeScope.read(context).addEvent(
          type: 'browser',
          title: 'External site opened',
          detail: tool.name,
        ),
      );
      setState(() => _statusText = '${tool.name} открыт во внешнем браузере.');
      _showMessage('${tool.name} открыт во внешнем браузере.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: tool.url));
    if (!mounted) return;
    _showMessage('Не удалось открыть сайт. Ссылка скопирована.');
  }

  void _openInside() {
    final message = kIsWeb
        ? 'В web-версии встроенный браузер ограничен. Используйте desktop-версию STUDIO или откройте сайт во внешнем браузере.'
        : 'Встроенный браузер будет доступен в desktop-версии после подключения WebView runtime.';
    setState(() {
      _showInternalPlaceholder = true;
      _statusText = message;
    });
    _showMessage(message);
  }

  void _saveManualResult() {
    unawaited(
      FlutenRuntimeScope.read(context).addAsset(
        type: 'manual',
        title: '${_selectedTool.name} manual result',
        description: _promptController.text.trim(),
        sourceProvider: _selectedTool.id,
        url: _selectedTool.url,
      ),
    );
    _showMessage('Результат можно сохранить вручную после генерации.');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    final title = const Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Браузер нейронок',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Командный центр для внешних AI-сайтов: текст, ресерч, картинки, видео, промпты и creative tools.',
            style: TextStyle(color: Color(0xFFA7B1C1), height: 1.35),
          ),
        ],
      ),
    );
    final leading = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F7F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.public_rounded, color: Colors.black),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xA6070A0F),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [leading, const SizedBox(width: 14), title]),
                const SizedBox(height: 12),
                const _DesktopBadge(),
              ],
            )
          : Row(
              children: [
                leading,
                const SizedBox(width: 14),
                title,
                const SizedBox(width: 14),
                const _DesktopBadge(),
              ],
            ),
    );
  }
}

class _DesktopBadge extends StatelessWidget {
  const _DesktopBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1422D3EE),
        border: Border.all(color: const Color(0x4422D3EE)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        kIsWeb ? 'Web fallback' : 'Desktop WebView ready',
        style: const TextStyle(
          color: Color(0xFF67E8F9),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ToolsPanel extends StatelessWidget {
  const _ToolsPanel({
    required this.selectedTool,
    required this.category,
    required this.searchController,
    required this.onCategoryChanged,
    required this.onToolSelected,
    required this.onCopyPrompt,
  });

  final BrowserAiTool selectedTool;
  final BrowserAiCategory? category;
  final TextEditingController searchController;
  final ValueChanged<BrowserAiCategory?> onCategoryChanged;
  final ValueChanged<BrowserAiTool> onToolSelected;
  final VoidCallback onCopyPrompt;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final query = searchController.text;
        final visible = browserAiTools.where((tool) {
          final matchesCategory = category == null || tool.category == category;
          return matchesCategory && tool.matches(query);
        }).toList();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xA6080B10),
            border: Border.all(color: const Color(0x24FFFFFF)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI-сервисы',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: searchController,
                onChanged: (_) => setLocalState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Найти сервис или сценарий',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Все'),
                    selected: category == null,
                    onSelected: (_) => onCategoryChanged(null),
                  ),
                  for (final item in BrowserAiCategory.values)
                    ChoiceChip(
                      label: Text(item.label),
                      selected: category == item,
                      onSelected: (_) => onCategoryChanged(item),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tool = visible[index];
                    return _ToolCard(
                      tool: tool,
                      selected: tool.id == selectedTool.id,
                      onSelect: () => onToolSelected(tool),
                      onCopyPrompt: onCopyPrompt,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    required this.selected,
    required this.onSelect,
    required this.onCopyPrompt,
  });

  final BrowserAiTool tool;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onCopyPrompt;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? const Color(0xFFC8FFF4) : const Color(0x22FFFFFF);
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0x18C8FFF4) : const Color(0x990B0F16),
          border: Border.all(color: accent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(tool.category.icon, color: const Color(0xFFC8FFF4)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tool.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? const Color(0xFFC8FFF4) : Colors.white38,
                  size: 19,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tool.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF9AA6B8), height: 1.3),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MiniPill(tool.category.label),
                _MiniPill(tool.accessType.label),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSelect,
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Выбрать сервис'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Скопировать промпт',
                  onPressed: tool.promptRelevant ? onCopyPrompt : null,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowserWorkspace extends StatelessWidget {
  const _BrowserWorkspace({
    required this.tool,
    required this.statusText,
    required this.showInternalPlaceholder,
    required this.promptController,
    required this.onCopyPrompt,
    required this.onOpenExternal,
    required this.onOpenInside,
    required this.onPreparePaste,
    required this.onSaveManualResult,
  });

  final BrowserAiTool tool;
  final String statusText;
  final bool showInternalPlaceholder;
  final TextEditingController promptController;
  final VoidCallback onCopyPrompt;
  final VoidCallback onOpenExternal;
  final VoidCallback onOpenInside;
  final VoidCallback onPreparePaste;
  final VoidCallback onSaveManualResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xDD05070B),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tool.category.icon,
                color: const Color(0xFFC8FFF4),
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      tool.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF8B97A8)),
                    ),
                  ],
                ),
              ),
              _MiniPill(tool.category.label),
              const SizedBox(width: 8),
              _MiniPill(tool.accessType.label),
            ],
          ),
          const SizedBox(height: 14),
          _StatusPanel(text: statusText, isWarning: kIsWeb),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF080B10),
                border: Border.all(color: const Color(0x22FFFFFF)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _BrowserStagePainter()),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.web_asset_rounded,
                              color: Color(0xFF556174),
                              size: 72,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              showInternalPlaceholder
                                  ? 'Встроенный браузер STUDIO'
                                  : 'Рабочая область ${tool.name}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              showInternalPlaceholder
                                  ? 'Встроенный браузер будет доступен в desktop-версии после подключения WebView runtime.\n${tool.url}'
                                  : 'Сервис выбран. Можно открыть сайт во внешнем браузере или подготовить prompt handoff.\n${tool.url}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF9AA6B8),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: promptController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Промпт для выбранного AI-сервиса',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onOpenInside,
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Открыть внутри STUDIO'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenExternal,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть во внешнем браузере'),
              ),
              OutlinedButton.icon(
                onPressed: onCopyPrompt,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать промпт'),
              ),
              OutlinedButton.icon(
                onPressed: onPreparePaste,
                icon: const Icon(Icons.input_rounded),
                label: const Text('Подготовить вставку'),
              ),
              OutlinedButton.icon(
                onPressed: onSaveManualResult,
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Сохранить результат вручную'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.text, required this.isWarning});

  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            color: isWarning
                ? const Color(0xFFFFB86B)
                : const Color(0xFFC8FFF4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE8EEF8),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE8EEF8),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BrowserStagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x0F22D3EE)
      ..strokeWidth = 1;
    for (var i = 0; i < 14; i++) {
      final x = size.width * i / 13;
      canvas.drawLine(Offset(x, 0), Offset(x + 34, size.height), line);
    }
    final frame = Paint()
      ..color = const Color(0x2222D3EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.14,
          size.height * 0.18,
          size.width * 0.72,
          size.height * 0.54,
        ),
        const Radius.circular(20),
      ),
      frame,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
