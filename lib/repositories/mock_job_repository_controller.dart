import '../models/job_status.dart';

abstract class MockJobRepositoryController {
  Future<void> applyMockPlan({
    required int activeCount,
    required int completedCount,
    bool append,
  });

  Future<void> resetDefaultJobs();

  Future<void> updateJobStatus({
    required String jobId,
    required JobStatus status,
  });
}
