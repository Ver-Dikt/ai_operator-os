import 'package:flutter/material.dart';

import '../../data/seed_free_credits.dart';
import '../../models/free_credit.dart';
import '../../services/url_service.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/chips/status_badge.dart';
import '../../widgets/responsive_page.dart';

class FreeCreditsScreen extends StatelessWidget {
  const FreeCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      title: 'Бесплатные инструменты / кредиты',
      subtitle:
          'Локальный список бесплатных планов, Local-вариантов, водяных знаков и требований карты.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 720
              ? 2
              : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: seedFreeCredits.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 300,
            ),
            itemBuilder: (context, index) =>
                _CreditCard(offer: seedFreeCredits[index]),
          );
        },
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.offer});

  final FreeCreditOffer offer;

  @override
  Widget build(BuildContext context) {
    return OsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.service,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(label: offer.freeType),
              if (offer.needsCard)
                const StatusBadge(
                  label: 'нужна карта',
                  color: Color(0xFFFFB86B),
                ),
              if (offer.watermark)
                const StatusBadge(
                  label: 'водяной знак',
                  color: Color(0xFFFF6B6B),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(offer.bestUse, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(
            offer.limitations,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF8B97A8)),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => const UrlService().open(offer.signupUrl),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Открыть'),
          ),
        ],
      ),
    );
  }
}
