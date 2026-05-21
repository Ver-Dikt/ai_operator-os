import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/generation/generation_provider.dart';

class BrowserWorkspacePanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final browserMode = mode == GenerationProviderType.browser;
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
                      mode.workflowLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      provider.name,
                      style: const TextStyle(color: Color(0xFF8B97A8)),
                    ),
                  ],
                ),
              ),
              Chip(label: Text(provider.statusLabel)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            mode.description,
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
                      constraints: const BoxConstraints(maxWidth: 520),
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
                            browserMode
                                ? 'Здесь будет встроенный браузер / webview'
                                : 'Внешний сервис открывается отдельно',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFE8EEF8),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            browserMode
                                ? 'Сейчас режим показывает будущую browser automation-панель: промпт можно скопировать, сайт открыть, результат сохранить вручную.'
                                : 'STUDIO удерживает промпт и параметры рядом, чтобы после внешней генерации результат можно было вернуть в историю.',
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copyPrompt(context),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать промпт'),
              ),
              FilledButton.icon(
                onPressed: () => _openSite(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть сайт'),
              ),
              OutlinedButton.icon(
                onPressed: () => _mockInject(context),
                icon: const Icon(Icons.input_rounded),
                label: const Text('Вставить в браузер'),
              ),
              OutlinedButton.icon(
                onPressed: () => _mockTakeResult(context),
                icon: const Icon(Icons.download_done_rounded),
                label: const Text('Забрать результат вручную'),
              ),
              OutlinedButton.icon(
                onPressed: onSaveManualResult,
                icon: const Icon(Icons.history_rounded),
                label: const Text('Сохранить в историю'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyPrompt(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: prompt.trim()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Промпт скопирован')));
  }

  Future<void> _openSite(BuildContext context) async {
    final url = provider.launchUrl;
    if (url == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL провайдера не задан')));
      return;
    }
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось открыть сайт')));
    }
  }

  void _mockInject(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Вставка в браузер будет подключена на этапе automation'),
      ),
    );
  }

  void _mockTakeResult(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ручной импорт результата: добавь файл/URL на следующем этапе',
        ),
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
