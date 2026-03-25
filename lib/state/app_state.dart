import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {

  Job? jobAtual;

  /// 📍 CONTROLE DE LOCALIZAÇÃO
  double? ultimaLatitude;
  double? ultimaLongitude;

  double? residenciaLat;
  double? residenciaLng;

  bool permitirIniciarLonge = true; // 🔥 modo DEV

  bool podeIniciarVistoria(double distanciaMetros) {
  if (permitirIniciarLonge) return true;

  return distanciaMetros <= 100;
}

  /// 🔥 INICIAR JOB
  void iniciarJob(Job job) {
    jobAtual = job;
    notifyListeners();
  }

  /// ✅ ACEITAR JOB
  void aceitarJob() {
    jobAtual?.status = JobStatus.aceito;
    notifyListeners();
  }

  /// ❌ RECUSAR JOB
  void recusarJob() {
    jobAtual?.status = JobStatus.recusado;
    notifyListeners();
  }

  /// 📍 CHECK-IN
  void fazerCheckin({required bool clientePresente, String? tipoImovel}) {
    if (jobAtual == null) return;

    jobAtual!.clientePresente = clientePresente;
    jobAtual!.tipoImovel = tipoImovel;
    jobAtual!.status = JobStatus.emAndamento;

    notifyListeners();
  }

  /// 📋 CHECKLIST
  void salvarChecklist(List<String> itens) {
    jobAtual?.checklist = itens;
    notifyListeners();
  }

  /// 📷 FOTO
  void adicionarFoto(String path) {
    jobAtual?.fotos.add(path);
    notifyListeners();
  }

  /// 🏁 FINALIZAR
  void finalizarJob() {
    jobAtual?.status = JobStatus.finalizado;
    notifyListeners();
  }

  /// 🚀 🔥 CÁLCULO DE DESLOCAMENTO (REGRA CORRETA)
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

    /// 🔁 CENÁRIO 1: VEIO DE VISTORIA ANTERIOR
    if (ultimaLatitude != null && ultimaLongitude != null) {
      return locationService.calcularDistancia(
        lat1: ultimaLatitude!,
        lon1: ultimaLongitude!,
        lat2: destinoLat,
        lon2: destinoLng,
      );
    }

    /// 🧠 VERIFICA SE ESTÁ EM CASA
    bool estaEmCasa = false;

    if (residenciaLat != null && residenciaLng != null) {
      final distanciaCasa = locationService.calcularDistancia(
        lat1: atualLat,
        lon1: atualLng,
        lat2: residenciaLat!,
        lon2: residenciaLng!,
      );

      /// raio de tolerância (100m)
      if (distanciaCasa < 100) {
        estaEmCasa = true;
      }
    }

    /// 🔵 CENÁRIO 3: PRIMEIRA VISTORIA (EM CASA)
    if (estaEmCasa && residenciaLat != null && residenciaLng != null) {
      return locationService.calcularDistancia(
        lat1: residenciaLat!,
        lon1: residenciaLng!,
        lat2: destinoLat,
        lon2: destinoLng,
      );
    }

    /// 🟡 CENÁRIO 2: FORA (SEM VISTORIA)
    double distanciaAtual = locationService.calcularDistancia(
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

  /// 💾 REGISTRA DESLOCAMENTO NO JOB
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

  /// 🔁 ATUALIZA ÚLTIMA LOCALIZAÇÃO
  void atualizarUltimaLocalizacao(double lat, double lng) {
    ultimaLatitude = lat;
    ultimaLongitude = lng;
    notifyListeners();
  }
}