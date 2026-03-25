import '../models/job.dart';
import 'job_repository.dart';

class FakeJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      Job(
        id: '1',
        endereco: 'Al. dos Pássaros, 100',
        latitude: -23.5505,
        longitude: -46.6333,
      ),
      Job(
        id: '2',
        endereco: 'Av. Brasil, 500',
        latitude: -23.5614,
        longitude: -46.6559,
      ),
    ];
  }
}
