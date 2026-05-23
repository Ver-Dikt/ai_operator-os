import 'package:flutter/material.dart';

import '../../models/generation/generation_job.dart';
import '../../models/generation/generation_provider.dart';

class RenderHistoryRail extends StatelessWidget {
  const RenderHistoryRail({
    super.key,
    required this.jobs,
    required this.selectedJobId,
    required this.onSelect,
  });

  final List<GenerationJob> jobs;
  final String? selectedJobId;
  final ValueChanged<GenerationJob> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: const Color(0x8C070A0F),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Text(
              'История',
              style: TextStyle(
                color: Color(0xFF8B97A8),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (jobs.isEmpty)
            const Expanded(child: _EmptyHistory())
          else
            Expanded(
              child: ListView.separated(
                itemCount: jobs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return _HistoryTile(
                    job: job,
                    selected: job.id == selectedJobId,
                    onTap: () => onSelect(job),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.job,
    required this.selected,
    required this.onTap,
  });

  final GenerationJob job;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final video = switch (job.capability) {
      GenerationCapability.textToImage ||
      GenerationCapability.imageToImage => false,
      GenerationCapability.textToVideo ||
      GenerationCapability.imageToVideo ||
      GenerationCapability.videoToVideo => true,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected ? const Color(0x18C8FFF4) : const Color(0x8010151D),
          border: Border.all(
            color: selected ? const Color(0x80C8FFF4) : const Color(0x22FFFFFF),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: LinearGradient(
                  colors: video
                      ? const [Color(0xFF2A182C), Color(0xFF102A2A)]
                      : const [Color(0xFF102A2A), Color(0xFF2C1D16)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                video ? Icons.play_arrow_rounded : Icons.image_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8EEF8),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.capability.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7D8798),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Рендеров пока нет',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF6F7A8D), fontWeight: FontWeight.w800),
      ),
    );
  }
}
