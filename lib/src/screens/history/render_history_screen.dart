import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ai_operator_app.dart';
import '../../models/execution_job.dart';
import '../../models/fluten_runtime.dart';
import '../../services/execution_queue.dart';
import '../../services/fluten_runtime_store.dart';
import '../../state/app_settings.dart';
import '../../widgets/cards/os_card.dart';
import '../../widgets/current_session_strip.dart';
import '../../widgets/responsive_page.dart';

enum _HistoryFilter { all, image, video, audio, director, provider, manual }

extension _HistoryFilterLabel on _HistoryFilter {
  String get label {
    return switch (this) {
      _HistoryFilter.all => 'All',
      _HistoryFilter.image => 'Image',
      _HistoryFilter.video => 'Video',
      _HistoryFilter.audio => 'Audio',
      _HistoryFilter.director => 'Director',
      _HistoryFilter.provider => 'Provider handoff',
      _HistoryFilter.manual => 'Manual',
    };
  }
}

class RenderHistoryScreen extends StatefulWidget {
  const RenderHistoryScreen({super.key});

  @override
  State<RenderHistoryScreen> createState() => _RenderHistoryScreenState();
}

class _RenderHistoryScreenState extends State<RenderHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final runtime = FlutenRuntimeScope.of(context);
    final entries = _buildEntries(runtime);
    final visible = entries.where(_matchesFilter).toList(growable: false);

    return ResponsivePage(
      title: 'History / Assets',
      subtitle:
          'Local session timeline for prompts, provider handoffs, plans and manually saved results. No fake renders.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CurrentSessionStrip(),
          const SizedBox(height: 12),
          _FilterBar(
            selected: _filter,
            onChanged: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 12),
          OsCard(
            child: visible.isEmpty
                ? const _EmptyHistory()
                : _HistoryList(entries: visible),
          ),
        ],
      ),
    );
  }

  List<_HistoryEntry> _buildEntries(FlutenRuntimeStore runtime) {
    final entries = <_HistoryEntry>[];
    final runtimeJobs = runtime.getRecentJobs(limit: 80);

    for (final job in ExecutionQueue.instance.listJobs()) {
      final alreadyRecorded = runtimeJobs.any(
        (stored) =>
            stored.providerId == job.providerId &&
            stored.routeType == job.executionMode.name &&
            stored.status == job.status.name &&
            stored.prompt == job.composedPrompt,
      );
      if (!alreadyRecorded) entries.add(_entryForExecutionJob(job));
    }

    for (final job in runtimeJobs) {
      entries.add(
        _HistoryEntry(
          id: job.id,
          type: _typeForJob(job),
          workspace: job.workspaceType,
          title: job.resultLabel ?? _titleForJob(job),
          preview: job.prompt,
          provider: job.providerId,
          prompt: job.prompt,
          url: job.resultUrl,
          createdAt: job.updatedAt,
        ),
      );
    }

    for (final asset in runtime.getAssets(limit: 80)) {
      entries.add(
        _HistoryEntry(
          id: asset.id,
          type: _typeForAsset(asset),
          workspace: _workspaceForAsset(asset),
          title: asset.title,
          preview: asset.description ?? asset.url ?? asset.localPath ?? '',
          provider: asset.sourceProvider,
          prompt: asset.description,
          url: asset.url,
          createdAt: asset.createdAt,
        ),
      );
    }

    for (final event in runtime.getRecentEvents(limit: 120)) {
      final entry = _entryForEvent(event);
      if (entry != null) entries.add(entry);
    }

    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  _HistoryEntry _entryForExecutionJob(ExecutionJob job) {
    return _HistoryEntry(
      id: job.id,
      type: _typeForExecutionJob(job),
      workspace: job.workspace.name,
      title: '${job.providerName}: ${job.status.label}',
      preview: job.errorMessage ?? job.composedPrompt,
      provider: job.providerName,
      prompt: job.composedPrompt,
      url: job.metadata['url'],
      createdAt: job.updatedAt,
    );
  }

  _HistoryEntryType _typeForExecutionJob(ExecutionJob job) {
    return switch (job.status) {
      ExecutionJobStatus.manualOnly ||
      ExecutionJobStatus.prepared ||
      ExecutionJobStatus.requiresApiKey ||
      ExecutionJobStatus.localUnavailable ||
      ExecutionJobStatus.needsWorkflow ||
      ExecutionJobStatus.needsExecutionImplementation ||
      ExecutionJobStatus.failed => _HistoryEntryType.providerHandoff,
      ExecutionJobStatus.completed => _HistoryEntryType.manualResult,
      _ => _HistoryEntryType.promptDraft,
    };
  }

  _HistoryEntryType _typeForJob(FlutenGenerationJob job) {
    if (job.status == 'manual' || job.status == 'saved') {
      return _HistoryEntryType.manualResult;
    }
    if (job.routeType == 'browser' ||
        job.routeType == 'external' ||
        job.status == 'requiresApiKey' ||
        job.status == 'localUnavailable' ||
        job.status == 'needsWorkflow' ||
        job.status == 'needsExecutionImplementation' ||
        job.status == 'manualOnly' ||
        job.status == 'failed') {
      return _HistoryEntryType.providerHandoff;
    }
    return _HistoryEntryType.promptDraft;
  }

  String _titleForJob(FlutenGenerationJob job) {
    final workspace = _readableWorkspace(job.workspaceType);
    return '$workspace prompt prepared';
  }

  _HistoryEntryType _typeForAsset(FlutenAsset asset) {
    if (asset.type == 'manual') return _HistoryEntryType.manualResult;
    if (asset.type == 'prompt' || asset.type == 'text') {
      return _HistoryEntryType.promptDraft;
    }
    return _HistoryEntryType.manualResult;
  }

  String _workspaceForAsset(FlutenAsset asset) {
    final type = asset.type.toLowerCase();
    if (type == 'image' || type == 'video' || type == 'audio') return type;
    if ((asset.sourceProvider ?? '').toLowerCase().contains('director')) {
      return 'director';
    }
    return 'manual';
  }

  _HistoryEntry? _entryForEvent(FlutenSessionEvent event) {
    final title = event.title.toLowerCase();
    final type = event.type.toLowerCase();
    final detail = event.detail ?? '';

    if (type == 'workspace' || title.contains('workspace opened')) return null;
    if (title.contains('active prompt draft updated')) return null;
    if (title.contains('active provider updated')) return null;

    final meaningful = title.contains('prompt') ||
        title.contains('provider') ||
        title.contains('director') ||
        title.contains('shot plan') ||
        title.contains('manual') ||
        type == 'audio' ||
        type == 'image' ||
        type == 'video' ||
        type == 'director' ||
        type == 'browser';
    if (!meaningful) return null;

    final entryType = title.contains('director')
        ? _HistoryEntryType.directorPlan
        : title.contains('shot plan')
            ? _HistoryEntryType.shotPlan
            : title.contains('provider') || type == 'browser'
                ? _HistoryEntryType.providerHandoff
                : title.contains('manual')
                    ? _HistoryEntryType.manualResult
                    : _HistoryEntryType.sessionEvent;

    return _HistoryEntry(
      id: event.id,
      type: entryType,
      workspace: _workspaceForEvent(type, title),
      title: event.title,
      preview: detail,
      prompt: detail,
      createdAt: event.createdAt,
    );
  }

  String _workspaceForEvent(String type, String title) {
    if (type == 'image' || title.contains('image')) return 'image';
    if (type == 'video' || title.contains('video')) return 'video';
    if (type == 'audio' || title.contains('audio')) return 'audio';
    if (type == 'director' || title.contains('director')) return 'director';
    if (type == 'browser' || title.contains('provider')) return 'provider';
    return type;
  }

  bool _matchesFilter(_HistoryEntry entry) {
    return switch (_filter) {
      _HistoryFilter.all => true,
      _HistoryFilter.image => entry.workspace == 'image',
      _HistoryFilter.video => entry.workspace == 'video',
      _HistoryFilter.audio => entry.workspace == 'audio',
      _HistoryFilter.director => entry.workspace == 'director' ||
          entry.type == _HistoryEntryType.directorPlan,
      _HistoryFilter.provider =>
        entry.type == _HistoryEntryType.providerHandoff ||
            entry.workspace == 'provider',
      _HistoryFilter.manual => entry.type == _HistoryEntryType.manualResult,
    };
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in _HistoryFilter.values)
          ChoiceChip(
            label: Text(item.label),
            selected: selected == item,
            onSelected: (_) => onChanged(item),
          ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries});

  final List<_HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) => _HistoryTile(entry: entries[index]),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(entry.createdAt);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: const Color(0x1FC8FFF4),
        child: Icon(_iconFor(entry), color: const Color(0xFFC8FFF4)),
      ),
      title: Text(entry.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MiniPill(entry.type.label),
                _MiniPill(_readableWorkspace(entry.workspace)),
                if (entry.provider != null) _MiniPill(entry.provider!),
                _MiniPill(time),
              ],
            ),
            if (entry.preview.trim().isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                _preview(entry.preview),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            _HistoryActions(entry: entry),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(_HistoryEntry entry) {
    return switch (entry.workspace) {
      'image' => Icons.image_outlined,
      'video' => Icons.movie_creation_outlined,
      'audio' => Icons.graphic_eq_rounded,
      'director' => Icons.movie_filter_rounded,
      _ => switch (entry.type) {
          _HistoryEntryType.providerHandoff => Icons.open_in_new_rounded,
          _HistoryEntryType.manualResult => Icons.save_alt_rounded,
          _HistoryEntryType.shotPlan => Icons.view_timeline_rounded,
          _HistoryEntryType.directorPlan => Icons.movie_filter_rounded,
          _ => Icons.history_rounded,
        },
    };
  }
}

class _HistoryActions extends StatelessWidget {
  const _HistoryActions({required this.entry});

  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final hasPrompt = (entry.prompt ?? '').trim().isNotEmpty;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showEntry(context),
          icon: const Icon(Icons.open_in_full_rounded, size: 16),
          label: const Text('Открыть'),
        ),
        if (hasPrompt)
          OutlinedButton.icon(
            onPressed: () => _copyPrompt(context),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Скопировать prompt'),
          ),
        if (hasPrompt && entry.workspace != 'image')
          OutlinedButton.icon(
            onPressed: () => _sendToImage(context),
            icon: const Icon(Icons.image_outlined, size: 16),
            label: const Text('Отправить в Image Studio'),
          ),
        if (hasPrompt && entry.workspace != 'video')
          OutlinedButton.icon(
            onPressed: () => _sendToVideo(context),
            icon: const Icon(Icons.movie_creation_outlined, size: 16),
            label: const Text('Отправить в Video Studio'),
          ),
        if (entry.url != null)
          OutlinedButton.icon(
            onPressed: () => _openUrl(context),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Открыть сайт'),
          ),
      ],
    );
  }

  void _showEntry(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.title),
        content: SingleChildScrollView(
          child: SelectableText(
            entry.prompt ?? entry.preview,
            style: const TextStyle(height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyPrompt(BuildContext context) async {
    final prompt = entry.prompt?.trim();
    if (prompt == null || prompt.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Prompt скопирован.')));
  }

  void _sendToImage(BuildContext context) {
    final prompt = entry.prompt?.trim();
    if (prompt == null || prompt.isEmpty) return;
    AppSettingsScope.of(context).setImagePromptDraft(prompt);
    Navigator.of(context).pushNamed(AppDestination.images.routePath);
  }

  void _sendToVideo(BuildContext context) {
    final prompt = entry.prompt?.trim();
    if (prompt == null || prompt.isEmpty) return;
    AppSettingsScope.of(context).setVideoPromptDraft(prompt);
    Navigator.of(context).pushNamed(AppDestination.video.routePath);
  }

  Future<void> _openUrl(BuildContext context) async {
    final url = entry.url;
    if (url == null || url.isEmpty) return;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Сайт открыт во внешнем браузере.'
              : 'Не удалось открыть сайт.',
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_rounded, size: 42, color: Color(0xFF7B8797)),
          SizedBox(height: 12),
          Text(
            'История пока пустая',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Здесь появятся подготовленные prompt, планы и результаты, сохранённые вручную. Реальная генерация будет подключена отдельным этапом.',
            style: TextStyle(color: Color(0xFF9AA6B8), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

enum _HistoryEntryType {
  promptDraft,
  providerHandoff,
  directorPlan,
  shotPlan,
  manualResult,
  sessionEvent,
}

extension _HistoryEntryTypeLabel on _HistoryEntryType {
  String get label {
    return switch (this) {
      _HistoryEntryType.promptDraft => 'Prompt Draft',
      _HistoryEntryType.providerHandoff => 'Provider Handoff',
      _HistoryEntryType.directorPlan => 'Director Plan',
      _HistoryEntryType.shotPlan => 'Shot Plan',
      _HistoryEntryType.manualResult => 'Manual Result',
      _HistoryEntryType.sessionEvent => 'Session Event',
    };
  }
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.id,
    required this.type,
    required this.workspace,
    required this.title,
    required this.preview,
    required this.createdAt,
    this.provider,
    this.prompt,
    this.url,
  });

  final String id;
  final _HistoryEntryType type;
  final String workspace;
  final String title;
  final String preview;
  final String? provider;
  final String? prompt;
  final String? url;
  final DateTime createdAt;
}

String _readableWorkspace(String value) {
  return switch (value.toLowerCase()) {
    'image' => 'Image',
    'video' => 'Video',
    'audio' => 'Audio',
    'director' => 'Director',
    'browser' || 'provider' => 'Provider',
    'manual' => 'Manual',
    'text' => 'AI Chat',
    _ => value,
  };
}

String _preview(String value) {
  final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean.length <= 180) return clean;
  return '${clean.substring(0, 180)}...';
}

String _formatTime(DateTime value) {
  final date =
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
