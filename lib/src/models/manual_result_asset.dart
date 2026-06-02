enum ManualResultType { image, video, audio, text, other }

enum ManualResultStatus { completedManual, draft, needsReview }

extension ManualResultTypeLabel on ManualResultType {
  String get label {
    return switch (this) {
      ManualResultType.image => 'Image',
      ManualResultType.video => 'Video',
      ManualResultType.audio => 'Audio',
      ManualResultType.text => 'Text',
      ManualResultType.other => 'Other',
    };
  }
}

extension ManualResultStatusLabel on ManualResultStatus {
  String get label {
    return switch (this) {
      ManualResultStatus.completedManual => 'Completed manual',
      ManualResultStatus.draft => 'Draft',
      ManualResultStatus.needsReview => 'Needs review',
    };
  }
}

class ManualResultAsset {
  const ManualResultAsset({
    required this.id,
    required this.type,
    required this.title,
    required this.sourceWorkspace,
    required this.prompt,
    required this.createdAt,
    required this.status,
    this.providerId,
    this.providerName,
    this.filePath,
    this.externalUrl,
    this.notes,
    this.thumbnailPlaceholder,
    this.linkedExecutionJobId,
  });

  final String id;
  final ManualResultType type;
  final String title;
  final String sourceWorkspace;
  final String? providerId;
  final String? providerName;
  final String prompt;
  final String? filePath;
  final String? externalUrl;
  final String? notes;
  final DateTime createdAt;
  final ManualResultStatus status;
  final String? thumbnailPlaceholder;
  final String? linkedExecutionJobId;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'sourceWorkspace': sourceWorkspace,
      'providerId': providerId,
      'providerName': providerName,
      'prompt': prompt,
      'filePath': filePath,
      'externalUrl': externalUrl,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'thumbnailPlaceholder': thumbnailPlaceholder,
      'linkedExecutionJobId': linkedExecutionJobId,
    };
  }

  factory ManualResultAsset.fromJson(Map<String, Object?> json) {
    return ManualResultAsset(
      id: json['id'] as String? ?? '',
      type: _enumByName(
        ManualResultType.values,
        json['type'] as String?,
        ManualResultType.other,
      ),
      title: json['title'] as String? ?? 'Manual result',
      sourceWorkspace: json['sourceWorkspace'] as String? ?? 'manual',
      providerId: json['providerId'] as String?,
      providerName: json['providerName'] as String?,
      prompt: json['prompt'] as String? ?? '',
      filePath: json['filePath'] as String?,
      externalUrl: json['externalUrl'] as String?,
      notes: json['notes'] as String?,
      createdAt: _date(json['createdAt']),
      status: _enumByName(
        ManualResultStatus.values,
        json['status'] as String?,
        ManualResultStatus.completedManual,
      ),
      thumbnailPlaceholder: json['thumbnailPlaceholder'] as String?,
      linkedExecutionJobId: json['linkedExecutionJobId'] as String?,
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

DateTime _date(Object? value) {
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
