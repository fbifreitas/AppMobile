import '../models/job.dart';
import 'job_repository.dart';

class FakeJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      Job(
        id: '1',
        titulo: 'Casa em Condomínio - Res. Tamboré',
        endereco: 'Al. dos Pássaros, 100',
        latitude: -23.5505,
        longitude: -46.6333,
        nomeCliente: 'Ricardo (Prop.)',
        telefoneCliente: '11999999999',
      ),
      Job(
        id: '2',
        titulo: 'Apartamento - Condominio Spazio Belem',
        endereco: 'Av. Alvaro Ramos, 760 Apto 102',
        latitude: -23.546747,
        longitude: -46.591367,
        nomeCliente: 'Fabio Freitas (Prop.)',
        telefoneCliente: '11988888888',
      ),
    ];
  }
}