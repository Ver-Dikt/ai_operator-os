import 'package:flutter/material.dart';

class DocumentaryHero extends StatelessWidget {
  const DocumentaryHero({
    super.key,
    required this.toolsCount,
    required this.favoriteCount,
    required this.onOpenCatalog,
  });

  final int toolsCount;
  final int favoriteCount;
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16202E), Color(0xFF101620)],
        ),
        border: Border.all(color: const Color(0xFF263244)),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _HeroCopy(onOpenCatalog: onOpenCatalog)),
                const SizedBox(width: 18),
                SizedBox(
                  width: 360,
                  child: _BentoStats(
                    toolsCount: toolsCount,
                    favoriteCount: favoriteCount,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCopy(onOpenCatalog: onOpenCatalog),
                const SizedBox(height: 16),
                _BentoStats(
                  toolsCount: toolsCount,
                  favoriteCount: favoriteCount,
                ),
              ],
            ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onOpenCatalog});

  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF132A2A),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF275B55)),
          ),
          child: const Text(
            'AI tool stack manager',
            style: TextStyle(
              color: Color(0xFF9CF5E2),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Собери свой AI-стек без хаоса во вкладках',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: const Color(0xFFF8FBFF),
            fontWeight: FontWeight.w900,
            height: 1.04,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: const Text(
            'Каталог помогает быстро выбрать сервис под задачу: видео, изображения, LLM, локальные модели, звук и автоматизация. Фильтры оставляют только нужное, избранное собирает рабочий набор.',
            style: TextStyle(
              color: Color(0xFFA7B1C1),
              height: 1.48,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onOpenCatalog,
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Перейти в каталог'),
            ),
            OutlinedButton.icon(
              onPressed: onOpenCatalog,
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Подобрать инструменты'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoStats extends StatelessWidget {
  const _BentoStats({required this.toolsCount, required this.favoriteCount});

  final int toolsCount;
  final int favoriteCount;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _BentoTile(
          label: 'Инструменты',
          value: '$toolsCount',
          icon: Icons.auto_awesome_rounded,
        ),
        _BentoTile(
          label: 'Избранное',
          value: '$favoriteCount',
          icon: Icons.star_rounded,
        ),
        const _BentoTile(
          label: 'Preview',
          value: 'Live',
          icon: Icons.sensors_rounded,
        ),
        const _BentoTile(
          label: 'Stack',
          value: 'Web',
          icon: Icons.layers_rounded,
        ),
      ],
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F151F),
        border: Border.all(color: const Color(0xFF263244)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: const Color(0xFF6BE4C9), size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8B97A8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
