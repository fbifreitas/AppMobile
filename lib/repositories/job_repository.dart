import '../models/job.dart';

abstract class JobRepository {
  Future<List<Job>> getJobs();
}