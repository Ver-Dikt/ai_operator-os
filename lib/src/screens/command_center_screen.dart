import 'package:flutter/material.dart';

import '../state/app_settings.dart';

class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key, required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.1,
          colors: [Color(0xFF13232C), Color(0xFF05070B)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 28,
                compact ? 18 : 28,
                compact ? 16 : 28,
                compact ? 96 : 28,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroPanel(onNavigate: onNavigate),
                        const SizedBox(height: 18),
                        _StudioGrid(onNavigate: onNavigate),
                        const SizedBox(height: 18),
                        const _WorkflowStrip(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xD9080B10),
        border: Border.all(color: const Color(0x22FFFFFF)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 40,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('Творческая студия генерации'),
              const SizedBox(height: 14),
              Text(
                'Открытая AI-студия',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Генерируй изображения, видео и кинематографичные сцены из одного понятного рабочего пространства: промпт, референсы, модель, история и результат.',
                style: TextStyle(
                  color: Color(0xFFA7B1C1),
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => onNavigate(AppDestination.images),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Открыть Image Studio'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onNavigate(AppDestination.video),
                    icon: const Icon(Icons.movie_creation_outlined),
                    label: const Text('Открыть Video Studio'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onNavigate(AppDestination.browserHub),
                    icon: const Icon(Icons.public_rounded),
                    label: const Text('Браузер нейронок'),
                  ),
                ],
              ),
            ],
          );
          final preview = const _HeroPreview();
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 20), preview],
            );
          }
          return Row(
            children: [
              Expanded(flex: 5, child: text),
              const SizedBox(width: 28),
              Expanded(flex: 4, child: preview),
            ],
          );
        },
      ),
    );
  }
}

class _HeroPreview extends StatelessWidget {
  const _HeroPreview();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x22FFFFFF)),
          gradient: const LinearGradient(
            colors: [Color(0xFF121821), Color(0xFF05070B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _StagePainter())),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xCC090D13),
                  border: Border.all(color: const Color(0x22FFFFFF)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF22D3EE)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Неоновая улица под дождем, медленный dolly-in, кинематографичный туман',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFE8EEF8),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudioGrid extends StatelessWidget {
  const _StudioGrid({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StudioCardData(
        'Image Studio',
        'Промпт, референсы, формат, модель и история рендеров.',
        Icons.image_outlined,
        AppDestination.images,
        const Color(0xFF22D3EE),
      ),
      _StudioCardData(
        'Video Studio',
        'Text-to-video, image-to-video, движение камеры и длительность.',
        Icons.movie_creation_outlined,
        AppDestination.video,
        const Color(0xFFFFB86B),
      ),
      _StudioCardData(
        'Cinema Studio',
        'Язык кадра, камера, объектив, свет и режиссерские пресеты.',
        Icons.video_camera_back_outlined,
        AppDestination.director,
        const Color(0xFFFF6B8A),
      ),
      _StudioCardData(
        'Workflows',
        'Шаблоны production-пайплайнов и повторяемые генеративные процессы.',
        Icons.schema_outlined,
        AppDestination.workflows,
        const Color(0xFF8B5CF6),
      ),
      _StudioCardData(
        'Браузер нейронок',
        'Внешние AI-сайты, промпт-буфер, запуск в браузере и desktop WebView-зона.',
        Icons.public_rounded,
        AppDestination.browserHub,
        const Color(0xFF67E8F9),
      ),
      _StudioCardData(
        'Маркетинг',
        'Контент-модули, короткие видео, публикации и creative packs.',
        Icons.campaign_outlined,
        AppDestination.contentFactory,
        const Color(0xFFFFD166),
      ),
      _StudioCardData(
        'Модели и провайдеры',
        'API, браузерные, локальные и внешние маршруты генерации.',
        Icons.hub_outlined,
        AppDestination.providers,
        const Color(0xFF9FE870),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 4
            : constraints.maxWidth >= 720
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 2.7 : 1.45,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => _StudioCard(
            data: cards[index],
            onTap: () => onNavigate(cards[index].destination),
          ),
        );
      },
    );
  }
}

class _StudioCardData {
  const _StudioCardData(
    this.title,
    this.description,
    this.icon,
    this.destination,
    this.accent,
  );

  final String title;
  final String description;
  final IconData icon;
  final AppDestination destination;
  final Color accent;
}

class _StudioCard extends StatelessWidget {
  const _StudioCard({required this.data, required this.onTap});

  final _StudioCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xCC0B0F16),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: data.accent, size: 28),
            const Spacer(),
            Text(
              data.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8B97A8), height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowStrip extends StatelessWidget {
  const _WorkflowStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Eyebrow('Workflow'),
          _StepPill('Промпт'),
          _StepPill('Референс'),
          _StepPill('Модель'),
          _StepPill('Генерация'),
          _StepPill('История'),
          _StepPill('Экспорт'),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.check_rounded, size: 16),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF22D3EE),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _StagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cyan = Paint()
      ..color = const Color(0x3322D3EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final warm = Paint()
      ..color = const Color(0x33FFB86B)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.42),
        width: size.width * 0.72,
        height: size.height * 0.34,
      ),
      cyan,
    );
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.32), 36, warm);
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.18 + i * 0.095);
      canvas.drawLine(
        Offset(size.width * 0.12, y),
        Offset(size.width * 0.88, y),
        cyan,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
