import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../repositories/job_repository.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository);

  final JobRepository repository;

  List<Job> jobs = [];
  Job? jobAtual;

  double? ultimaLatitude;
  double? ultimaLongitude;

  double? residenciaLat;
  double? residenciaLng;

  DateTime? ultimoCheckin;

  bool permitirIniciarLonge = true;

  Future<void> carregarJobs() async {
    jobs = await repository.getJobs();
    notifyListeners();
  }

  void selecionarJob(Job job) {
    jobAtual = job;
    notifyListeners();
  }

  void iniciarJob(Job job) {
    jobAtual = job;
    notifyListeners();
  }

  void aceitarJob(String jobId) {
    final index = jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return;

    jobs[index].status = JobStatus.aceito;
    notifyListeners();
  }

  void recusarJob() {
    jobAtual?.status = JobStatus.recusado;
    notifyListeners();
  }

  void fazerCheckin({required bool clientePresente, String? tipoImovel}) {
    if (jobAtual == null) return;

    jobAtual!.clientePresente = clientePresente;
    jobAtual!.tipoImovel = tipoImovel;
    jobAtual!.status = JobStatus.emAndamento;
    ultimoCheckin = DateTime.now();

    notifyListeners();
  }

  void salvarChecklist(List<String> itens) {
    jobAtual?.checklist = itens;
    notifyListeners();
  }

  void adicionarFoto(String path) {
    jobAtual?.fotos.add(path);
    notifyListeners();
  }

  void finalizarJob() {
    jobAtual?.status = JobStatus.finalizado;
    notifyListeners();
  }

  bool isPrimeiraVistoriaDoDia() {
    if (ultimoCheckin == null) return true;

    final agora = DateTime.now();
    return agora.day != ultimoCheckin!.day ||
        agora.month != ultimoCheckin!.month ||
        agora.year != ultimoCheckin!.year;
  }

  bool podeIniciarVistoria(double distanciaMetros) {
    if (permitirIniciarLonge) return true;
    return distanciaMetros <= 100;
  }

  double calcularKmDeslocamento({
    required double atualLat,
    required double atualLng,
  }) {
    if (jobAtual == null ||
        jobAtual!.latitude == null ||
        jobAtual!.longitude == null) {
      return 0;
    }

    final destinoLat = jobAtual!.latitude!;
    final destinoLng = jobAtual!.longitude!;
    final locationService = LocationService();

    if (ultimaLatitude != null && ultimaLongitude != null) {
      return locationService.calcularDistancia(
        lat1: ultimaLatitude!,
        lon1: ultimaLongitude!,
        lat2: destinoLat,
        lon2: destinoLng,
      );
    }

    if (isPrimeiraVistoriaDoDia() &&
        residenciaLat != null &&
        residenciaLng != null) {
      return locationService.calcularDistancia(
        lat1: residenciaLat!,
        lon1: residenciaLng!,
        lat2: destinoLat,
        lon2: destinoLng,
      );
    }

    final distanciaAtual = locationService.calcularDistancia(
      lat1: atualLat,
      lon1: atualLng,
      lat2: destinoLat,
      lon2: destinoLng,
    );

    double? distanciaResidencia;

    if (residenciaLat != null && residenciaLng != null) {
      distanciaResidencia = locationService.calcularDistancia(
        lat1: residenciaLat!,
        lon1: residenciaLng!,
        lat2: destinoLat,
        lon2: destinoLng,
      );
    }

    if (distanciaResidencia != null) {
      return distanciaAtual < distanciaResidencia
          ? distanciaAtual
          : distanciaResidencia;
    }

    return distanciaAtual;
  }

  void registrarDeslocamento({
    required double atualLat,
    required double atualLng,
  }) {
    if (jobAtual == null) return;

    final distancia = calcularKmDeslocamento(
      atualLat: atualLat,
      atualLng: atualLng,
    );

    jobAtual!.origemLat = atualLat;
    jobAtual!.origemLng = atualLng;
    jobAtual!.distanciaKm = distancia / 1000;

    notifyListeners();
  }

  void atualizarUltimaLocalizacao(double lat, double lng) {
    ultimaLatitude = lat;
    ultimaLongitude = lng;
    notifyListeners();
  }
}