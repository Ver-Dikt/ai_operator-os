import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ai_operator_app.dart';
import '../models/tool_item.dart';

class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.tool});

  final ToolItem tool;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isFavorite = settings.isFavorite(tool.id);
    final accessColor = _accessColor(tool.access);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF151B27), Color(0xFF10151F)],
            ),
            border: Border.all(color: const Color(0xFF263244)),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ToolMark(color: accessColor, label: tool.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: const Color(0xFFF8FBFF),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tool.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8B97A8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: isFavorite
                          ? 'Убрать из избранного'
                          : 'Добавить в избранное',
                      onPressed: () => settings.toggleFavorite(tool.id),
                      icon: Icon(
                        isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                      ),
                      color: isFavorite
                          ? const Color(0xFFFFB86B)
                          : const Color(0xFF8B97A8),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  tool.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC8D2E1),
                    height: 1.38,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoPanel(
                  label: 'Цена / доступ',
                  value: tool.priceNote,
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 8),
                _InfoPanel(
                  label: 'Лучше для',
                  value: tool.bestFor,
                  icon: Icons.near_me_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SignalMeter(
                        value: tool.signal,
                        color: accessColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _AccessBadge(access: tool.access, color: accessColor),
                  ],
                ),
                const Spacer(),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tool.tags
                      .take(3)
                      .map((tag) => _TagChip(label: tag))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _launch(tool.url),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Открыть'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Подробнее',
                      onPressed: () => _showDetails(context),
                      icon: const Icon(Icons.notes_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111722),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(tool.name),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tool.description,
                style: const TextStyle(height: 1.45, color: Color(0xFFC8D2E1)),
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Категория', value: tool.category),
              _DetailRow(label: 'Доступ', value: tool.access.label),
              _DetailRow(label: 'Цена', value: tool.priceNote),
              _DetailRow(label: 'Лучше для', value: tool.bestFor),
              _DetailRow(label: 'Signal', value: '${tool.signal}/100'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tool.tags.map((tag) => _TagChip(label: tag)).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _launch(tool.url);
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Открыть сайт'),
          ),
        ],
      ),
    );
  }
}

class _ToolMark extends StatelessWidget {
  const _ToolMark({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label.characters.first.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF0D131D),
        border: Border.all(color: const Color(0xFF202A3A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF8B97A8)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8B97A8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8EEF8),
                    fontSize: 13,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalMeter extends StatelessWidget {
  const _SignalMeter({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signal $value',
          style: const TextStyle(
            color: Color(0xFFA7B1C1),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 7,
            backgroundColor: const Color(0xFF202A3A),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AccessBadge extends StatelessWidget {
  const _AccessBadge({required this.access, required this.color});

  final ToolAccess access;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        access.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D131D),
        border: Border.all(color: const Color(0xFF263244)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFA7B1C1),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B97A8),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFFE8EEF8)),
            ),
          ),
        ],
      ),
    );
  }
}

Color _accessColor(ToolAccess access) {
  return switch (access) {
    ToolAccess.free => const Color(0xFF6BE4C9),
    ToolAccess.freemium => const Color(0xFF9FB7FF),
    ToolAccess.paid => const Color(0xFFFFB86B),
    ToolAccess.local => const Color(0xFFB894FF),
    ToolAccess.sensitive => const Color(0xFFFF6B8A),
  };
}
