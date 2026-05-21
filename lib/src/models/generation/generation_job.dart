import 'generation_provider.dart';
import 'generation_request.dart';

enum GenerationJobStatus { queued, running, completed, failed, cancelled }

extension GenerationJobStatusLabel on GenerationJobStatus {
  String get label {
    return switch (this) {
      GenerationJobStatus.queued => 'В очереди',
      GenerationJobStatus.running => 'Рендеринг',
      GenerationJobStatus.completed => 'Готово',
      GenerationJobStatus.failed => 'Ошибка',
      GenerationJobStatus.cancelled => 'Отменено',
    };
  }
}

class GenerationJob {
  const GenerationJob({
    required this.id,
    required this.title,
    required this.request,
    required this.providerName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.progress = 0,
    this.previewUrl,
    this.outputUrl,
    this.errorMessage,
  });

  final String id;
  final String title;
  final GenerationRequest request;
  final String providerName;
  final GenerationJobStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double progress;
  final String? previewUrl;
  final String? outputUrl;
  final String? errorMessage;

  GenerationCapability get capability => request.capability;

  GenerationJob copyWith({
    String? title,
    GenerationJobStatus? status,
    DateTime? updatedAt,
    double? progress,
    String? previewUrl,
    String? outputUrl,
    String? errorMessage,
  }) {
    return GenerationJob(
      id: id,
      title: title ?? this.title,
      request: request,
      providerName: providerName,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progress: progress ?? this.progress,
      previewUrl: previewUrl ?? this.previewUrl,
      outputUrl: outputUrl ?? this.outputUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
