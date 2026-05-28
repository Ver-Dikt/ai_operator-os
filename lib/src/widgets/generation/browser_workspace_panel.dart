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
      'Провайдер выбран. Скопируйте production prompt, откройте сервис и вставьте вручную.';

  @override
  void didUpdateWidget(covariant BrowserWorkspacePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.id != widget.provider.id ||
        oldWidget.mode != widget.mode) {
      _showInternalPlaceholder = false;
      _statusText =
          'Провайдер выбран. Скопируйте production prompt, откройте сервис и вставьте вручную.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final browserMode = widget.mode == GenerationProviderType.browser;
    final url = widget.provider.launchUrl;
    final productionPrompt = widget.prompt.trim().isEmpty
        ? 'Production prompt пока пуст. Введите промпт в нижней панели.'
        : widget.prompt.trim();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 430),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xE6070A0F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x24FFFFFF)),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
          const SizedBox(height: 10),
          _StatusPanel(text: _statusText, isWarning: kIsWeb),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final preview = _PromptPreview(
                  providerName: widget.provider.name,
                  url: url,
                  prompt: productionPrompt,
                  showInternalPlaceholder: _showInternalPlaceholder,
                );
                if (compact) {
                  return ListView(
                    children: [
                      SizedBox(height: 320, child: preview),
                      const SizedBox(height: 10),
                      const _Checklist(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: preview),
                    const SizedBox(width: 10),
                    const SizedBox(width: 236, child: _Checklist()),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              FilledButton.icon(
                onPressed: _copyPrompt,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать промпт'),
              ),
              OutlinedButton.icon(
                onPressed: _openSite,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Открыть сервис'),
              ),
              OutlinedButton.icon(
                onPressed: _openInside,
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Встроенный браузер: скоро'),
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
        : 'Встроенный браузер пока не подключен. Сейчас используйте внешний сайт провайдера.';
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

class _PromptPreview extends StatelessWidget {
  const _PromptPreview({
    required this.providerName,
    required this.url,
    required this.prompt,
    required this.showInternalPlaceholder,
  });

  final String providerName;
  final String? url;
  final String prompt;
  final bool showInternalPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            showInternalPlaceholder
                ? Icons.web_asset_rounded
                : Icons.assignment_outlined,
            color: const Color(0xFF22D3EE),
          ),
          const SizedBox(height: 10),
          Text(
            showInternalPlaceholder
                ? 'Встроенный браузер STUDIO'
                : 'Browser handoff: $providerName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showInternalPlaceholder
                ? 'Встроенный браузер пока не подключен. Сейчас используйте внешний сайт провайдера.\n${url ?? 'URL провайдера не задан'}'
                : 'Production prompt виден ниже. Его можно скопировать, открыть сервис и вставить вручную.\n${url ?? 'URL провайдера не задан'}',
            style: const TextStyle(color: Color(0xFF9AA6B8), height: 1.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Production prompt',
            style: TextStyle(
              color: Color(0xFF67E8F9),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                prompt,
                style: const TextStyle(color: Color(0xFFE8EEF8), height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Шаги',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12),
          _Step('1', 'Скопируйте промпт'),
          _Step('2', 'Откройте сервис'),
          _Step('3', 'Вставьте вручную'),
          _Step('4', 'Сохраните результат'),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.label);

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFFE7F7F4),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE8EEF8),
                fontWeight: FontWeight.w700,
              ),
            ),
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
