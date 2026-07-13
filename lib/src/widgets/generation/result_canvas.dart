import 'package:flutter/material.dart';

import '../../models/generation/generation_job.dart';
import '../../models/generation/generation_provider.dart';
import 'result_media.dart';

class ResultCanvas extends StatelessWidget {
  const ResultCanvas({super.key, required this.job});

  final GenerationJob? job;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 430),
      decoration: BoxDecoration(
        color: const Color(0xE6070A0F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: job == null ? const _EmptyStage() : _GeneratedStage(job: job!),
      ),
    );
  }
}

class _GeneratedStage extends StatelessWidget {
  const _GeneratedStage({required this.job});

  final GenerationJob job;

  @override
  Widget build(BuildContext context) {
    final video = _isVideo(job.capability);
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _GeneratedPainter(video: video)),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _aspectFor(job.request.aspectRatio),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 780),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x2BFFFFFF)),
                          gradient: LinearGradient(
                            colors: video
                                ? const [Color(0xFF191322), Color(0xFF06151A)]
                                : const [Color(0xFF10242A), Color(0xFF1C1016)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x80000000),
                              blurRadius: 30,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _FramePainter(video: video),
                              ),
                            ),
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: ResultMedia(
                                  source: job.outputUrl ?? job.previewUrl,
                                  isVideo: video,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _ResultDetails(job: job),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isVideo(GenerationCapability capability) {
    return switch (capability) {
      GenerationCapability.textToImage ||
      GenerationCapability.imageToImage => false,
      GenerationCapability.textToVideo ||
      GenerationCapability.imageToVideo ||
      GenerationCapability.videoToVideo => true,
    };
  }

  double _aspectFor(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 16 / 9;
    final width = double.tryParse(parts.first) ?? 16;
    final height = double.tryParse(parts.last) ?? 9;
    return width / height;
  }
}

class _ResultDetails extends StatelessWidget {
  const _ResultDetails({required this.job});

  final GenerationJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xB8090D13),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  job.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${job.providerName} · ${job.status.label}',
                  style: const TextStyle(color: Color(0xFF8B97A8)),
                ),
              ],
            ),
          ),
          Chip(label: Text(job.capability.label)),
          Chip(label: Text(job.request.aspectRatio)),
          if (job.request.quality != null)
            Chip(label: Text(job.request.quality!)),
          if (job.request.durationSeconds != null)
            Chip(label: Text('${job.request.durationSeconds} sec')),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Повторить'),
          ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Экспорт'),
          ),
        ],
      ),
    );
  }
}

class _EmptyStage extends StatelessWidget {
  const _EmptyStage();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _GeneratedPainter(video: true)),
        ),
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.movie_filter_outlined,
                size: 56,
                color: Color(0xFF566175),
              ),
              SizedBox(height: 14),
              Text(
                'Результат появится здесь',
                style: TextStyle(
                  color: Color(0xFFE8EEF8),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Напиши промпт, выбери модель, добавь референсы и запусти генерацию.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF7D8798)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GeneratedPainter extends CustomPainter {
  const _GeneratedPainter({required this.video});

  final bool video;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x1422D3EE)
      ..strokeWidth = 1;
    for (var i = 0; i < 12; i++) {
      final y = size.height * i / 11;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 40), line);
    }
    final glow = Paint()
      ..color = (video ? const Color(0x22FFB86B) : const Color(0x2222D3EE))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.22), 92, glow);
  }

  @override
  bool shouldRepaint(covariant _GeneratedPainter oldDelegate) {
    return oldDelegate.video != video;
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({required this.video});

  final bool video;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = video ? const Color(0x33FFB86B) : const Color(0x3322D3EE)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.46),
        width: size.width * 0.68,
        height: size.height * 0.36,
      ),
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.35), 34, fill);
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) {
    return oldDelegate.video != video;
  }
}
