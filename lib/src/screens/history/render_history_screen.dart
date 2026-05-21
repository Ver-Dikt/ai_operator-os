import 'package:flutter/material.dart';

import '../../widgets/cards/os_card.dart';
import '../../widgets/responsive_page.dart';

class RenderHistoryScreen extends StatelessWidget {
  const RenderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      title: 'История рендеров',
      subtitle: 'Единая будущая лента изображений, видео, pending jobs и внешних запусков.',
      child: OsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _HistoryRow('Кадр для teaser campaign', 'Изображение · mock · готово'),
            Divider(),
            _HistoryRow('Вертикальный opener 9:16', 'Видео · browser route · черновик'),
            Divider(),
            _HistoryRow('Product hero shot', 'Режиссёрский preset · ожидает запуска'),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.history_rounded),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
