import 'package:flutter/material.dart';

import '../../models/generation/generation_provider.dart';
import '../../services/generation/generation_provider_registry.dart';

class ProvidersScreen extends StatelessWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = const GenerationProviderRegistry().all();
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.1,
          colors: [Color(0xFF13202C), Color(0xFF05070B)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Header(),
                        const SizedBox(height: 18),
                        _ProviderSummary(providers: providers),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 1040
                                ? 3
                                : constraints.maxWidth >= 700
                                ? 2
                                : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: columns == 1
                                        ? 2.15
                                        : 1.35,
                                  ),
                              itemCount: providers.length,
                              itemBuilder: (context, index) =>
                                  _ProviderCard(provider: providers[index]),
                            );
                          },
                        ),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'МАРШРУТЫ МОДЕЛЕЙ',
          style: TextStyle(
            color: Color(0xFF22D3EE),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Провайдеры и модели',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Управляй маршрутами генерации для Image Studio и Video Studio: API, браузер, локальный runtime и внешние рабочие области.',
          style: TextStyle(color: Color(0xFFA7B1C1), height: 1.4),
        ),
      ],
    );
  }
}

class _ProviderSummary extends StatelessWidget {
  const _ProviderSummary({required this.providers});

  final List<GenerationProvider> providers;

  @override
  Widget build(BuildContext context) {
    final api = providers
        .where((p) => p.type == GenerationProviderType.api)
        .length;
    final local = providers
        .where((p) => p.type == GenerationProviderType.local)
        .length;
    final browser = providers
        .where((p) => p.type == GenerationProviderType.browser)
        .length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryTile('Маршруты', '${providers.length}', Icons.hub_outlined),
        _SummaryTile('API', '$api', Icons.api_rounded),
        _SummaryTile('Локально', '$local', Icons.dns_outlined),
        _SummaryTile('Браузер', '$browser', Icons.open_in_browser_rounded),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC0B0F16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF22D3EE)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(label, style: const TextStyle(color: Color(0xFF8B97A8))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});

  final GenerationProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x1722D3EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconFor(provider.type),
                  color: const Color(0xFF22D3EE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      provider.type.label,
                      style: const TextStyle(color: Color(0xFF8B97A8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            provider.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFA7B1C1), height: 1.35),
          ),
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(label: Text(provider.statusLabel)),
              for (final capability in provider.capabilities)
                Chip(label: Text(capability.label)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(GenerationProviderType type) {
    return switch (type) {
      GenerationProviderType.api => Icons.api_rounded,
      GenerationProviderType.browser => Icons.open_in_browser_rounded,
      GenerationProviderType.local => Icons.dns_outlined,
      GenerationProviderType.externalLink => Icons.open_in_new_rounded,
    };
  }
}
