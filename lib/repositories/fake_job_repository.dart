import '../models/job.dart';
import '../models/job_status.dart';
import 'mock_job_repository_controller.dart';
import 'job_repository.dart';

class FakeJobRepository implements JobRepository, MockJobRepositoryController {
  FakeJobRepository() : _jobs = _buildDefaultJobs();

  List<Job> _jobs;
  int _generatedJobCounter = 1000;

  @override
  Future<List<Job>> getJobs() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return _jobs
        .map(
          (job) => Job(
            id: job.id,
            titulo: job.titulo,
            endereco: job.endereco,
            latitude: job.latitude,
            longitude: job.longitude,
            status: job.status,
            nomeCliente: job.nomeCliente,
            telefoneCliente: job.telefoneCliente,
            clientePresente: job.clientePresente,
            tipoImovel: job.tipoImovel,
            subtipoImovel: job.subtipoImovel,
            checklist: List.from(job.checklist),
            fotos: List.from(job.fotos),
            origemLat: job.origemLat,
            origemLng: job.origemLng,
            distanciaKm: job.distanciaKm,
            idExterno: job.idExterno,
            protocoloExterno: job.protocoloExterno,
          ),
        )
        .toList();
  }

  @override
  Future<void> resetDefaultJobs() async {
    _jobs = _buildDefaultJobs();
  }

  @override
  Future<void> applyMockPlan({
    required int activeCount,
    required int completedCount,
    bool append = false,
  }) async {
    final generated = <Job>[
      ...List.generate(
        activeCount,
        (index) => _createGeneratedJob(index: index, completed: false),
      ),
      ...List.generate(
        completedCount,
        (index) => _createGeneratedJob(index: index, completed: true),
      ),
    ];

    if (append) {
      _jobs.addAll(generated);
      return;
    }

    _jobs = generated;
  }

  @override
  Future<void> updateJobStatus({
    required String jobId,
    required JobStatus status,
  }) async {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    _jobs[index].status = status;
  }

  Job _createGeneratedJob({required int index, required bool completed}) {
    _generatedJobCounter += 1;
    final seq = _generatedJobCounter;
    return Job(
      id: '$seq',
      titulo:
          completed
              ? 'Vistoria concluida #$seq'
              : 'Vistoria em andamento #$seq',
      endereco: 'Rua de Teste, ${120 + index} - Ambiente Mock',
      latitude: -23.55 + (index * 0.001),
      longitude: -46.63 - (index * 0.001),
      nomeCliente:
          completed ? 'Cliente concluido #$seq' : 'Cliente ativo #$seq',
      telefoneCliente: '1199000${(seq % 10000).toString().padLeft(4, '0')}',
      tipoImovel: 'Urbano',
      subtipoImovel: 'Apartamento',
      status: completed ? JobStatus.finalizado : JobStatus.emAndamento,
    );
  }

  static List<Job> _buildDefaultJobs() {
    return [
      Job(
        id: '1',
        titulo: 'Casa em Condomínio - Res. Tamboré',
        endereco: 'Al. dos Pássaros, 100',
        latitude: -23.5505,
        longitude: -46.6333,
        nomeCliente: 'Ricardo (Prop.)',
        telefoneCliente: '11999999999',
        tipoImovel: 'Urbano',
        subtipoImovel: 'Casa',
      ),
      Job(
        id: '2',
        titulo: 'Apartamento - Condominio Spazio Belem',
        endereco: 'Av. Alvaro Ramos, 760 Apto 102',
        latitude: -23.5440650,
        longitude: -46.5864270,
        nomeCliente: 'Fabio Freitas (Prop.)',
        telefoneCliente: '11988888888',
        tipoImovel: 'Urbano',
        subtipoImovel: 'Apartamento',
      ),
    ];
  }
}
