import 'package:appmobile/repositories/fake_job_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default jobs carry consistent apartment geodata for JOB 2', () async {
    final repository = FakeJobRepository();

    final jobs = await repository.getJobs();
    final job2 = jobs.firstWhere((job) => job.id == '2');

    expect(job2.endereco, 'Av. Alvaro Ramos, 760 Apto 102');
    expect(job2.tipoImovel, 'Urbano');
    expect(job2.subtipoImovel, 'Apartamento');
    expect(job2.latitude, closeTo(-23.5440650, 0.000001));
    expect(job2.longitude, closeTo(-46.5864270, 0.000001));
  });
}
