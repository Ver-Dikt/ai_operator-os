import 'package:flutter/material.dart';

import '../../ai_operator_app.dart';
import '../../models/fluten_runtime.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/current_session_strip.dart';
import '../../widgets/responsive_page.dart';

class RenderHistoryScreen extends StatelessWidget {
  const RenderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = FlutenRuntimeScope.of(context);
    final jobs = runtime.getRecentJobs(limit: 8);
    final assets = runtime.getAssets(limit: 8);
    final events = runtime.getRecentEvents(limit: 8);
    final hasRuntimeItems =
        jobs.isNotEmpty || assets.isNotEmpty || events.isNotEmpty;

    return ResponsivePage(
      title: 'История рендеров',
      subtitle:
          'Единая будущая лента изображений, видео, pending jobs и внешних запусков.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CurrentSessionStrip(),
          const SizedBox(height: 12),
          OsCard(
            child: hasRuntimeItems
                ? _RuntimeHistory(jobs: jobs, assets: assets, events: events)
                : const _FallbackHistory(),
          ),
        ],
      ),
    );
  }
}

class _RuntimeHistory extends StatelessWidget {
  const _RuntimeHistory({
    required this.jobs,
    required this.assets,
    required this.events,
  });

  final List<FlutenGenerationJob> jobs;
  final List<FlutenAsset> assets;
  final List<FlutenSessionEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final job in jobs) ...[
          _HistoryRow(
            job.resultLabel ?? job.prompt,
            '${job.workspaceType} · ${job.routeType} · ${job.status}',
          ),
          const Divider(),
        ],
        for (final asset in assets) ...[
          _HistoryRow(
            asset.title,
            '${asset.type} · ${asset.sourceProvider ?? 'local'}',
          ),
          const Divider(),
        ],
        for (final event in events) ...[
          _HistoryRow(
            event.title,
            '${event.type} · ${event.detail ?? 'session event'}',
          ),
          const Divider(),
        ],
      ],
    );
  }
}

class _FallbackHistory extends StatelessWidget {
  const _FallbackHistory();

  @override
  Widget build(BuildContext context) {
    return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryRow(
              'Кадр для teaser campaign',
              'Изображение · mock · готово',
            ),
            Divider(),
            _HistoryRow(
              'Вертикальный opener 9:16',
              'Видео · browser route · черновик',
            ),
            Divider(),
            _HistoryRow(
              'Product hero shot',
              'Режиссёрский preset · ожидает запуска',
            ),
          ],
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
