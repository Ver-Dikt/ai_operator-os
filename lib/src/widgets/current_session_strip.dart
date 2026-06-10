import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai_operator_app.dart';
import '../state/app_settings.dart';

class CurrentSessionStrip extends StatelessWidget {
  const CurrentSessionStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = FlutenRuntimeScope.of(context);
    final project = runtime.getCurrentProject();
    final session = runtime.getCurrentSession();
    final events = runtime.getRecentEvents(limit: 1);
    final assets = runtime.getAssets(limit: 1);
    final lastEvent = events.isEmpty ? null : events.first;
    final lastAsset = assets.isEmpty ? null : assets.first;
    final draft = session.activePromptDraft?.trim();
    final status =
        lastEvent?.title ?? (draft == null ? 'Runtime ready' : 'Draft ready');
    final provider = session.activeProviderId == null
        ? null
        : session.activeRoute == null
        ? session.activeProviderId!
        : '${session.activeProviderId} / ${session.activeRoute}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x99080B10),
        border: Border.all(color: const Color(0x22FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Pill(icon: Icons.folder_rounded, text: project.name),
          _Pill(
            icon: Icons.radio_button_checked_rounded,
            text: 'Текущая сессия',
          ),
          _Pill(
            icon: Icons.dashboard_customize_rounded,
            text: _workspaceLabel(session.activeWorkspace),
          ),
          if (provider != null) _Pill(icon: Icons.hub_outlined, text: provider),
          _Pill(icon: Icons.bolt_rounded, text: status),
          if (lastAsset != null && (lastAsset.status ?? '').isNotEmpty)
            _Pill(
              icon: Icons.save_alt_rounded,
              text:
                  '${lastAsset.title} / ${lastAsset.type} / ${lastAsset.providerName ?? lastAsset.sourceProvider ?? 'Manual'}',
            ),
          if (draft != null && draft.isNotEmpty)
            _Pill(icon: Icons.notes_rounded, text: 'active prompt'),
          _SessionAction(
            icon: Icons.keyboard_return_rounded,
            label: 'Вернуться',
            onTap: () => _returnToWorkspace(context, session.activeWorkspace),
          ),
          _SessionAction(
            icon: Icons.copy_rounded,
            label: 'Скопировать active prompt',
            onTap: draft == null || draft.isEmpty
                ? null
                : () => _copyDraft(context, draft),
          ),
          _SessionAction(
            icon: Icons.cleaning_services_rounded,
            label: 'Очистить текущую сессию',
            danger: true,
            onTap: () => _confirmClear(context),
          ),
        ],
      ),
    );
  }

  static String _workspaceLabel(String value) {
    return switch (value.toLowerCase()) {
      'text' => 'AI Chat',
      'image' => 'Image Studio',
      'video' => 'Video Studio',
      'audio' => 'Audio Studio',
      'browser' => 'Browser Hub',
      'director' => 'Director',
      _ => value,
    };
  }

  static void _returnToWorkspace(BuildContext context, String workspace) {
    final destination = switch (workspace.toLowerCase()) {
      'image' => AppDestination.images,
      'video' => AppDestination.video,
      'audio' => AppDestination.audio,
      'browser' => AppDestination.browserHub,
      'director' => AppDestination.director,
      _ => AppDestination.textWorkspace,
    };
    Navigator.of(context).pushNamed(destination.routePath);
  }

  static Future<void> _copyDraft(BuildContext context, String draft) async {
    await Clipboard.setData(ClipboardData(text: draft));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Active prompt скопирован.')));
  }

  static Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить текущую сессию?'),
        content: const Text(
          'Будут очищены текущие prompts, события, jobs и assets этой локальной сессии. Файлы проекта и код не удаляются.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await FlutenRuntimeScope.read(context).clearCurrentSession();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Текущая сессия очищена.')));
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFC8FFF4), size: 14),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFDCE7F5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionAction extends StatelessWidget {
  const _SessionAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFFB4A8) : const Color(0xFFC8FFF4);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x12FFFFFF),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
