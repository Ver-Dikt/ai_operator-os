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
                        _CurrentMvpPanel(onNavigate: onNavigate),
                        const SizedBox(height: 18),
                        _StudioGrid(onNavigate: onNavigate),
                        const SizedBox(height: 18),
                        _MvpWorkflowGuide(onNavigate: onNavigate),
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
          Widget actionButton({
            required IconData icon,
            required String label,
            required VoidCallback onPressed,
            required bool primary,
          }) {
            final buttonLabel = Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
            final button = primary
                ? FilledButton.icon(
                    onPressed: onPressed,
                    icon: Icon(icon),
                    label: buttonLabel,
                  )
                : OutlinedButton.icon(
                    onPressed: onPressed,
                    icon: Icon(icon),
                    label: buttonLabel,
                  );
            return compact
                ? SizedBox(width: constraints.maxWidth, child: button)
                : button;
          }

          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('FLUTEN MVP'),
              const SizedBox(height: 14),
              Text(
                'AI Operator OS - рабочий MVP',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Сейчас FLUTEN помогает пройти честный ручной production flow: собрать prompt в AI Chat, открыть нужный сервис, сохранить результат в History / Assets.',
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
                  actionButton(
                    onPressed: () => onNavigate(AppDestination.textWorkspace),
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'AI Chat',
                    primary: true,
                  ),
                  actionButton(
                    onPressed: () => onNavigate(AppDestination.settings),
                    icon: Icons.tune_rounded,
                    label: 'Execution Settings',
                    primary: false,
                  ),
                  actionButton(
                    onPressed: () => onNavigate(AppDestination.browserHub),
                    icon: Icons.public_rounded,
                    label: 'Browser Hub',
                    primary: false,
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
                        'Идея -> prompt -> внешний сервис -> ручное сохранение',
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

class _CurrentMvpPanel extends StatelessWidget {
  const _CurrentMvpPanel({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _MvpItem(
        'AI Chat',
        'OpenRouter / OmniRoute real text execution',
        Icons.chat_bubble_outline_rounded,
        'Требует настройки',
      ),
      _MvpItem(
        'Execution Settings',
        'API keys, Base URL, model/profile and health checks',
        Icons.tune_rounded,
        'Ready now',
      ),
      _MvpItem(
        'Browser Hub',
        'External tools, copy/open handoff and manual route',
        Icons.public_rounded,
        'Через сайт / вручную',
      ),
      _MvpItem(
        'Image / Video / Audio',
        'Prompt preparation plus manual result saving',
        Icons.auto_awesome_rounded,
        'Через сайт / вручную',
      ),
      _MvpItem(
        'History / Assets',
        'Saved outputs, prepared prompts and manual results',
        Icons.history_rounded,
        'Ready now',
      ),
      _MvpItem(
        'Local runtimes',
        'Ollama, ComfyUI and ACE-Step health-check foundation',
        Icons.cable_rounded,
        'Экспериментально',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xCC080B10),
        border: Border.all(color: const Color(0x22FFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Eyebrow('Current MVP'),
                    SizedBox(height: 6),
                    Text(
                      'Что уже можно использовать',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.renderHistory),
                icon: const Icon(Icons.history_rounded),
                label: const Text('History'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: _MvpStatusTile(item: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MvpItem {
  const _MvpItem(this.title, this.description, this.icon, this.status);

  final String title;
  final String description;
  final IconData icon;
  final String status;
}

class _MvpStatusTile extends StatelessWidget {
  const _MvpStatusTile({required this.item});

  final _MvpItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: const Color(0xFF67E8F9), size: 20),
              const Spacer(),
              _StatusPill(item.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9AA6B8), height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        border: Border.all(color: const Color(0x22FFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD9E6F7),
          fontSize: 10,
          fontWeight: FontWeight.w800,
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
        'AI Chat',
        'Real OpenRouter / OmniRoute text execution when configured.',
        Icons.chat_bubble_outline_rounded,
        AppDestination.textWorkspace,
        const Color(0xFF67E8F9),
        status: 'Требует настройки',
      ),
      _StudioCardData(
        'Image Studio',
        'Prompt prep, browser/manual provider handoff and manual saving.',
        Icons.image_outlined,
        AppDestination.images,
        const Color(0xFF22D3EE),
        status: 'Через сайт / вручную',
      ),
      _StudioCardData(
        'Video Studio',
        'Shot prompt prep, external tool handoff and manual result saving.',
        Icons.movie_creation_outlined,
        AppDestination.video,
        const Color(0xFFFFB86B),
        status: 'Через сайт / вручную',
      ),
      _StudioCardData(
        'Audio Studio',
        'Music, voice and sound prompts for external audio services.',
        Icons.graphic_eq_rounded,
        AppDestination.audio,
        const Color(0xFF9FE870),
        status: 'Через сайт / вручную',
      ),
      _StudioCardData(
        'Cinema / Director',
        'Director plan, shot logic and Video Studio handoff.',
        Icons.video_camera_back_outlined,
        AppDestination.director,
        const Color(0xFFFF6B8A),
        status: 'Экспериментально',
      ),
      _StudioCardData(
        'Browser Hub',
        'External tools discovery, copy prompt and manual handoff.',
        Icons.public_rounded,
        AppDestination.browserHub,
        const Color(0xFF67E8F9),
        status: 'Через сайт / вручную',
      ),
      _StudioCardData(
        'History / Assets',
        'Prepared prompts, provider handoffs, plans and saved results.',
        Icons.history_rounded,
        AppDestination.renderHistory,
        const Color(0xFFC8FFF4),
      ),
      _StudioCardData(
        'Providers',
        'Registry for API, browser, local and manual routes.',
        Icons.hub_outlined,
        AppDestination.providers,
        const Color(0xFF9FE870),
        status: 'Справочник',
      ),
      _StudioCardData(
        'Workflows',
        'Repeatable pipelines will be connected after MVP stabilization.',
        Icons.schema_outlined,
        AppDestination.workflows,
        const Color(0xFF8B5CF6),
        enabled: false,
      ),
      _StudioCardData(
        'Marketing',
        'Content Factory packs are planned; this section is not configured yet.',
        Icons.campaign_outlined,
        AppDestination.contentFactory,
        const Color(0xFFFFD166),
        enabled: false,
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
            childAspectRatio: columns == 1 ? 1.75 : 1.45,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => _StudioCard(
            data: cards[index],
            onTap: cards[index].enabled
                ? () => onNavigate(cards[index].destination)
                : null,
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
    this.accent, {
    this.enabled = true,
    this.status = 'Ready now',
  });

  final String title;
  final String description;
  final IconData icon;
  final AppDestination destination;
  final Color accent;
  final bool enabled;
  final String status;
}

class _StudioCard extends StatelessWidget {
  const _StudioCard({required this.data, required this.onTap});

  final _StudioCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.enabled ? onTap : null,
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
            Row(
              children: [
                Icon(
                  data.icon,
                  color: data.enabled ? data.accent : Colors.white38,
                  size: 28,
                ),
                const Spacer(),
                data.enabled
                    ? _StatusPill(data.status)
                    : const Chip(
                        label: Text('Скоро'),
                        visualDensity: VisualDensity.compact,
                      ),
              ],
            ),
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

class _MvpWorkflowGuide extends StatelessWidget {
  const _MvpWorkflowGuide({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x990B0F16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Guided workflow'),
          const SizedBox(height: 8),
          const Text(
            'Быстрый сценарий: идея -> промпт -> результат -> история',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final children = const [
                _GuideStep(
                  '1',
                  'AI Chat',
                  'Соберите или улучшите prompt через OpenRouter / OmniRoute.',
                ),
                _GuideStep(
                  '2',
                  'Studio',
                  'Отправьте prompt в Image, Video или Audio Studio.',
                ),
                _GuideStep(
                  '3',
                  'Browser Hub',
                  'Откройте внешний сервис и вставьте prompt вручную.',
                ),
                _GuideStep(
                  '4',
                  'Save',
                  'Сохраните готовый результат в History / Assets.',
                ),
                _GuideStep(
                  '5',
                  'Reuse',
                  'Вернитесь к сохранённому результату позже.',
                ),
              ];
              if (compact) {
                return Column(
                  children: [
                    for (final child in children)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: child,
                      ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final child in children)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: child,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => onNavigate(AppDestination.textWorkspace),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Open AI Chat'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.images),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Image Studio'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.video),
                icon: const Icon(Icons.movie_creation_outlined),
                label: const Text('Video Studio'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.browserHub),
                icon: const Icon(Icons.public_rounded),
                label: const Text('Browser Hub'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(AppDestination.renderHistory),
                icon: const Icon(Icons.history_rounded),
                label: const Text('History'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep(this.number, this.title, this.description);

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x66070A0F),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF67E8F9),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9AA6B8), height: 1.3),
          ),
        ],
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
          _Eyebrow('MVP flow'),
          _StepPill('Идея'),
          _StepPill('Prompt'),
          _StepPill('Browser / manual'),
          _StepPill('Сохранить'),
          _StepPill('History'),
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
