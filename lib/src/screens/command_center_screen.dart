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
              const _Eyebrow('РўРІРѕСЂС‡РµСЃРєР°СЏ СЃС‚СѓРґРёСЏ РіРµРЅРµСЂР°С†РёРё'),
              const SizedBox(height: 14),
              Text(
                'РћС‚РєСЂС‹С‚Р°СЏ AI-СЃС‚СѓРґРёСЏ',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Р“РµРЅРµСЂРёСЂСѓР№ РёР·РѕР±СЂР°Р¶РµРЅРёСЏ, РІРёРґРµРѕ Рё РєРёРЅРµРјР°С‚РѕРіСЂР°С„РёС‡РЅС‹Рµ СЃС†РµРЅС‹ РёР· РѕРґРЅРѕРіРѕ РїРѕРЅСЏС‚РЅРѕРіРѕ СЂР°Р±РѕС‡РµРіРѕ РїСЂРѕСЃС‚СЂР°РЅСЃС‚РІР°: РїСЂРѕРјРїС‚, СЂРµС„РµСЂРµРЅСЃС‹, РјРѕРґРµР»СЊ, РёСЃС‚РѕСЂРёСЏ Рё СЂРµР·СѓР»СЊС‚Р°С‚.',
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
                    label: const Text('РћС‚РєСЂС‹С‚СЊ Image Studio'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onNavigate(AppDestination.video),
                    icon: const Icon(Icons.movie_creation_outlined),
                    label: const Text('РћС‚РєСЂС‹С‚СЊ Video Studio'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onNavigate(AppDestination.browserHub),
                    icon: const Icon(Icons.public_rounded),
                    label: const Text('Р‘СЂР°СѓР·РµСЂ РЅРµР№СЂРѕРЅРѕРє'),
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
                        'РќРµРѕРЅРѕРІР°СЏ СѓР»РёС†Р° РїРѕРґ РґРѕР¶РґРµРј, РјРµРґР»РµРЅРЅС‹Р№ dolly-in, РєРёРЅРµРјР°С‚РѕРіСЂР°С„РёС‡РЅС‹Р№ С‚СѓРјР°РЅ',
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
        'AI Chat',
        'Persistent text workspace for ideas, prompt drafts and studio handoffs.',
        Icons.chat_bubble_outline_rounded,
        AppDestination.textWorkspace,
        const Color(0xFF67E8F9),
      ),
      _StudioCardData(
        'Image Studio',
        'Direct visual prompt composer, image controls and provider handoff.',
        Icons.image_outlined,
        AppDestination.images,
        const Color(0xFF22D3EE),
      ),
      _StudioCardData(
        'Video Studio',
        'Cinematic prompt composer, shot plan and video provider handoff.',
        Icons.movie_creation_outlined,
        AppDestination.video,
        const Color(0xFFFFB86B),
      ),
      _StudioCardData(
        'Audio Studio',
        'Music, voice and sound design prompts for external audio services.',
        Icons.graphic_eq_rounded,
        AppDestination.audio,
        const Color(0xFF9FE870),
      ),
      _StudioCardData(
        'Cinema / Director',
        'Director plan, shot logic, camera language and Video Studio handoff.',
        Icons.video_camera_back_outlined,
        AppDestination.director,
        const Color(0xFFFF6B8A),
      ),
      _StudioCardData(
        'Browser Hub',
        'Filtered AI tools: open site, copy prompt, prepare manual handoff.',
        Icons.public_rounded,
        AppDestination.browserHub,
        const Color(0xFF67E8F9),
      ),
      _StudioCardData(
        'History / Assets',
        'Prepared prompts, provider handoffs, plans and manually saved results.',
        Icons.history_rounded,
        AppDestination.renderHistory,
        const Color(0xFFC8FFF4),
      ),
      _StudioCardData(
        'Providers',
        'Registered API, browser, local and manual routes. Execution is not connected yet.',
        Icons.hub_outlined,
        AppDestination.providers,
        const Color(0xFF9FE870),
      ),
      _StudioCardData(
        'Workflows',
        'Repeatable pipelines will be connected after real execution.',
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
            childAspectRatio: columns == 1 ? 2.7 : 1.45,
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
    this.accent,
    {this.enabled = true}
  );

  final String title;
  final String description;
  final IconData icon;
  final AppDestination destination;
  final Color accent;
  final bool enabled;
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
                Icon(data.icon, color: data.enabled ? data.accent : Colors.white38, size: 28),
                const Spacer(),
                if (!data.enabled)
                  const Chip(
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
          _StepPill('РџСЂРѕРјРїС‚'),
          _StepPill('Р РµС„РµСЂРµРЅСЃ'),
          _StepPill('РњРѕРґРµР»СЊ'),
          _StepPill('Р“РµРЅРµСЂР°С†РёСЏ'),
          _StepPill('РСЃС‚РѕСЂРёСЏ'),
          _StepPill('Р­РєСЃРїРѕСЂС‚'),
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
