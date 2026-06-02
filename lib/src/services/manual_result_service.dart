import 'package:flutter/widgets.dart';

import '../ai_operator_app.dart';
import '../models/execution_job.dart';
import '../models/fluten_runtime.dart';
import '../models/manual_result_asset.dart';
import 'execution_queue.dart';

class ManualResultSaveRequest {
  const ManualResultSaveRequest({
    required this.type,
    required this.title,
    required this.sourceWorkspace,
    required this.prompt,
    required this.status,
    this.providerId,
    this.providerName,
    this.filePath,
    this.externalUrl,
    this.notes,
    this.linkedExecutionJobId,
  });

  final ManualResultType type;
  final String title;
  final String sourceWorkspace;
  final String prompt;
  final ManualResultStatus status;
  final String? providerId;
  final String? providerName;
  final String? filePath;
  final String? externalUrl;
  final String? notes;
  final String? linkedExecutionJobId;
}

class ManualResultService {
  const ManualResultService();

  Future<FlutenAsset> save(BuildContext context, ManualResultSaveRequest request) async {
    final runtime = FlutenRuntimeScope.read(context);
    final asset = await runtime.addAsset(
      type: request.type.name,
      title: request.title,
      jobId: request.linkedExecutionJobId,
      description: request.prompt,
      sourceProvider: request.providerName ?? request.providerId,
      url: _blankToNull(request.externalUrl),
      localPath: _blankToNull(request.filePath),
      prompt: request.prompt,
      providerId: request.providerId,
      providerName: request.providerName,
      sourceWorkspace: request.sourceWorkspace,
      notes: _blankToNull(request.notes),
      status: request.status.name,
    );

    final jobId = request.linkedExecutionJobId;
    if (jobId != null && jobId.isNotEmpty) {
      final job = ExecutionQueue.instance.byId(jobId);
      if (job != null) {
        final resultAssets = <String>{...job.resultAssets, asset.id}.toList();
        ExecutionQueue.instance.update(
          job.copyWith(
            status: ExecutionJobStatus.completedManual,
            updatedAt: DateTime.now(),
            resultAssets: resultAssets,
            metadata: {
              ...job.metadata,
              'manualResultAssetId': asset.id,
              'manualResultTitle': asset.title,
            },
          ),
        );
      }
    }

    await runtime.addEvent(
      type: request.sourceWorkspace,
      title: 'Manual result saved',
      detail: '${request.title} / ${request.type.label}',
    );
    return asset;
  }

  String? _blankToNull(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }
}
