import 'package:flutter/foundation.dart';

import '../models/execution_job.dart';

class ExecutionQueue extends ChangeNotifier {
  ExecutionQueue._();

  static final ExecutionQueue instance = ExecutionQueue._();

  final List<ExecutionJob> _jobs = <ExecutionJob>[];

  List<ExecutionJob> listJobs({
    ExecutionJobWorkspace? workspace,
    ExecutionJobStatus? status,
  }) {
    return _jobs.where((job) {
      if (workspace != null && job.workspace != workspace) return false;
      if (status != null && job.status != status) return false;
      return true;
    }).toList(growable: false);
  }

  ExecutionJob add(ExecutionJob job) {
    _jobs.insert(0, job);
    _trim();
    notifyListeners();
    return job;
  }

  ExecutionJob update(ExecutionJob job) {
    final index = _jobs.indexWhere((item) => item.id == job.id);
    if (index == -1) {
      return add(job);
    }
    _jobs[index] = job;
    _sort();
    notifyListeners();
    return job;
  }

  ExecutionJob? cancel(String id) {
    final index = _jobs.indexWhere((job) => job.id == id);
    if (index == -1) return null;
    final cancelled = _jobs[index].copyWith(
      status: ExecutionJobStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    _jobs[index] = cancelled;
    _sort();
    notifyListeners();
    return cancelled;
  }

  ExecutionJob? byId(String id) {
    for (final job in _jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  void _sort() {
    _jobs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _trim() {
    if (_jobs.length > 120) _jobs.removeRange(120, _jobs.length);
  }
}
