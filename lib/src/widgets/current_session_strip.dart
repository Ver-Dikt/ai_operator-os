import 'package:flutter/material.dart';

import '../ai_operator_app.dart';

class CurrentSessionStrip extends StatelessWidget {
  const CurrentSessionStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = FlutenRuntimeScope.of(context);
    final project = runtime.getCurrentProject();
    final session = runtime.getCurrentSession();
    final events = runtime.getRecentEvents(limit: 1);
    final lastEvent = events.isEmpty ? null : events.first;
    final draft = session.activePromptDraft?.trim();
    final status = lastEvent?.title ?? (draft == null ? 'Runtime ready' : 'Draft ready');

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
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Pill(icon: Icons.folder_rounded, text: project.name),
          _Pill(icon: Icons.radio_button_checked_rounded, text: session.name),
          _Pill(
            icon: Icons.dashboard_customize_rounded,
            text: session.activeWorkspace,
          ),
          if (session.activeProviderId != null)
            _Pill(
              icon: Icons.hub_outlined,
              text: session.activeRoute == null
                  ? session.activeProviderId!
                  : '${session.activeProviderId} / ${session.activeRoute}',
            ),
          _Pill(icon: Icons.bolt_rounded, text: status),
          if (draft != null && draft.isNotEmpty)
            _Pill(icon: Icons.notes_rounded, text: 'draft saved'),
        ],
      ),
    );
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
