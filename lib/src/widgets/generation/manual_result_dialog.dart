import 'package:flutter/material.dart';

import '../../models/manual_result_asset.dart';
import '../../services/manual_result_service.dart';

Future<ManualResultSaveRequest?> showManualResultDialog({
  required BuildContext context,
  required ManualResultType initialType,
  required String sourceWorkspace,
  required String prompt,
  String? providerId,
  String? providerName,
  String? externalUrl,
  String? linkedExecutionJobId,
}) {
  return showDialog<ManualResultSaveRequest>(
    context: context,
    builder: (context) => _ManualResultDialog(
      initialType: initialType,
      sourceWorkspace: sourceWorkspace,
      prompt: prompt,
      providerId: providerId,
      providerName: providerName,
      externalUrl: externalUrl,
      linkedExecutionJobId: linkedExecutionJobId,
    ),
  );
}

class _ManualResultDialog extends StatefulWidget {
  const _ManualResultDialog({
    required this.initialType,
    required this.sourceWorkspace,
    required this.prompt,
    this.providerId,
    this.providerName,
    this.externalUrl,
    this.linkedExecutionJobId,
  });

  final ManualResultType initialType;
  final String sourceWorkspace;
  final String prompt;
  final String? providerId;
  final String? providerName;
  final String? externalUrl;
  final String? linkedExecutionJobId;

  @override
  State<_ManualResultDialog> createState() => _ManualResultDialogState();
}

class _ManualResultDialogState extends State<_ManualResultDialog> {
  late ManualResultType _type = widget.initialType;
  ManualResultStatus _status = ManualResultStatus.completedManual;
  late final TextEditingController _titleController;
  late final TextEditingController _filePathController;
  late final TextEditingController _urlController;
  final _notesController = TextEditingController();
  bool _showPathWarning = false;

  @override
  void initState() {
    super.initState();
    final provider = widget.providerName?.trim();
    _titleController = TextEditingController(
      text: provider == null || provider.isEmpty
          ? '${widget.initialType.label} manual result'
          : '$provider manual result',
    );
    _filePathController = TextEditingController();
    _urlController = TextEditingController(text: widget.externalUrl ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _filePathController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt.trim();
    return AlertDialog(
      title: const Text('Сохранить результат вручную'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ManualResultType>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Тип результата'),
                      items: [
                        for (final type in ManualResultType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _type = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<ManualResultStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Статус'),
                      items: [
                        for (final status in ManualResultStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Название результата'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.providerName ?? widget.providerId ?? 'Manual',
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Провайдер'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Внешний URL',
                  helperText: 'Можно оставить пустым, если результата пока нет по ссылке.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _filePathController,
                decoration: const InputDecoration(
                  labelText: 'Локальный путь к файлу',
                  helperText: 'FLUTEN не создаёт файл и не удаляет его. Это только запись пути.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Заметки'),
              ),
              if (_showPathWarning) ...[
                const SizedBox(height: 8),
                const Text(
                  'Проверь ссылку или путь к файлу.',
                  style: TextStyle(color: Color(0xFFFFB86B)),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Prompt preview',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 150),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x14000000),
                  border: Border.all(color: const Color(0x22000000)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    prompt.isEmpty ? 'Prompt не указан.' : prompt,
                    style: const TextStyle(height: 1.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавь название результата.')),
      );
      return;
    }

    final url = _urlController.text.trim();
    final filePath = _filePathController.text.trim();
    final hasSuspiciousPath = url.contains(' ') || filePath.contains('://');
    if (hasSuspiciousPath && !_showPathWarning) {
      setState(() => _showPathWarning = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Проверь ссылку или путь к файлу.')),
      );
      return;
    }

    Navigator.of(context).pop(
      ManualResultSaveRequest(
        type: _type,
        title: title,
        sourceWorkspace: widget.sourceWorkspace,
        prompt: widget.prompt.trim(),
        status: _status,
        providerId: widget.providerId,
        providerName: widget.providerName,
        filePath: filePath,
        externalUrl: url,
        notes: _notesController.text.trim(),
        linkedExecutionJobId: widget.linkedExecutionJobId,
      ),
    );
  }
}
