import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/generation/generation_provider.dart';

class BrowserWorkspacePanel extends StatefulWidget {
  const BrowserWorkspacePanel({
    super.key,
    required this.provider,
    required this.mode,
    required this.prompt,
    required this.onSaveManualResult,
  });

  final GenerationProvider provider;
  final GenerationProviderType mode;
  final String prompt;
  final VoidCallback onSaveManualResult;

  @override
  State<BrowserWorkspacePanel> createState() => _BrowserWorkspacePanelState();
}

class _BrowserWorkspacePanelState extends State<BrowserWorkspacePanel> {
  bool _showInternalPlaceholder = false;
  String _statusText =
      'Провайдер выбран. Можно открыть сайт во внешнем браузере или подготовить prompt handoff.';

  @override
  void didUpdateWidget(covariant BrowserWorkspacePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.id != widget.provider.id ||
        oldWidget.mode != widget.mode) {
      _showInternalPlaceholder = false;
      _statusText =
          'Провайдер выбран. Можно открыть сайт во внешнем браузере или подготовить prompt handoff.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final browserMode = widget.mode == GenerationProviderType.browser;
    final url = widget.provider.launchUrl;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 430),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF070A0F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                browserMode
                    ? Icons.open_in_browser_rounded
                    : Icons.open_in_new_rounded,
                color: const Color(0xFF22D3EE),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mode.workflowLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      widget.provider.name,
                      style: const TextStyle(color: Color(0xFF8B97A8)),
                    ),
                  ],
                ),
              ),
              Chip(label: Text(widget.provider.statusLabel)),
            ],
          ),
          const SizedBox(height: 10),
          if (url != null)
            SelectableText(
              url,
              style: const TextStyle(
                color: Color(0xFF67E8F9),
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 12),
          _StatusPanel(text: _statusText, isWarning: kIsWeb),
          const SizedBox(height: 14),
          Text(
            widget.mode.description,
            style: const TextStyle(color: Color(0xFFA7B1C1), height: 1.4),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F16),
                border: Border.all(color: const Color(0x22FFFFFF)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _BrowserGridPainter()),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              browserMode
                                  ? Icons.web_asset_rounded
                                  : Icons.link_rounded,
                              color: const Color(0xFF566175),
                              size: 64,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _showInternalPlaceholder
                                  ? 'Встроенный браузер STUDIO'
                                  : widget.provider.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFE8EEF8),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showInternalPlaceholder
                                  ? 'Встроенный браузер будет доступен в desktop-версии после подключения WebView runtime.\n${url ?? 'URL провайдера не задан'}'
                                  : 'Сайт провайдера можно открыть отдельно, а промпт скопировать и вставить вручную.\n${url ?? 'URL провайдера не задан'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF8B97A8),
                                height: 1.4,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _openSite,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть сайт'),
              ),
              OutlinedButton.icon(
                onPressed: _openInside,
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Открыть внутри STUDIO'),
              ),
              OutlinedButton.icon(
                onPressed: _copyPrompt,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать промпт'),
              ),
              OutlinedButton.icon(
                onPressed: _preparePaste,
                icon: const Icon(Icons.input_rounded),
                label: const Text('Подготовить вставку'),
              ),
              OutlinedButton.icon(
                onPressed: _saveManualResult,
                icon: const Icon(Icons.history_rounded),
                label: const Text('Сохранить результат вручную'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(ClipboardData(text: widget.prompt.trim()));
    if (!mounted) return;
    _showMessage('Промпт скопирован.');
  }

  Future<void> _preparePaste() async {
    await Clipboard.setData(ClipboardData(text: widget.prompt.trim()));
    if (!mounted) return;
    _showMessage('Промпт скопирован. Вставьте его в открытом сервисе вручную.');
  }

  Future<void> _openSite() async {
    final url = widget.provider.launchUrl;
    if (url == null) {
      _showMessage('URL провайдера не задан.');
      return;
    }
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (opened) {
      setState(
        () =>
            _statusText = '${widget.provider.name} открыт во внешнем браузере.',
      );
      _showMessage('${widget.provider.name} открыт во внешнем браузере.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
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
    widget.onSaveManualResult();
    _showMessage('Результат можно сохранить вручную после генерации.');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.text, required this.isWarning});

  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F16),
        border: Border.all(color: const Color(0x22FFFFFF)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            color: isWarning
                ? const Color(0xFFFFB86B)
                : const Color(0xFF22D3EE),
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

class _BrowserGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x1022D3EE)
      ..strokeWidth = 1;
    for (var i = 0; i < 12; i++) {
      final x = size.width * i / 11;
      canvas.drawLine(Offset(x, 0), Offset(x + 24, size.height), line);
    }
    final glow = Paint()
      ..color = const Color(0x1822D3EE)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.28), 90, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
