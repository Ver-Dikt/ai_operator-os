import 'package:flutter/material.dart';

class ReferencePicker extends StatelessWidget {
  const ReferencePicker({
    super.key,
    required this.references,
    required this.onAddMock,
    required this.onClear,
    this.videoMode = false,
  });

  final List<String> references;
  final VoidCallback onAddMock;
  final VoidCallback onClear;
  final bool videoMode;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: videoMode
              ? 'Добавить медиа-референс'
              : 'Добавить изображение-референс',
          child: InkWell(
            onTap: onAddMock,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x8011161F),
                border: Border.all(color: const Color(0x24FFFFFF)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                videoMode
                    ? Icons.video_file_outlined
                    : Icons.add_photo_alternate_outlined,
                color: const Color(0xFFC8FFF4),
              ),
            ),
          ),
        ),
        for (final reference in references)
          _ReferenceChip(label: reference, videoMode: videoMode),
        if (references.isNotEmpty)
          IconButton(
            tooltip: 'Очистить референсы',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            color: const Color(0xFF8B97A8),
          ),
      ],
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({required this.label, required this.videoMode});

  final String label;
  final bool videoMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 8, right: 12),
      decoration: BoxDecoration(
        color: const Color(0x8011161F),
        border: Border.all(color: const Color(0x33C8FFF4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0x18C8FFF4),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              videoMode ? Icons.movie_creation_outlined : Icons.image_outlined,
              size: 16,
              color: const Color(0xFFC8FFF4),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE8EEF8),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
