import 'job_status.dart';

class Job {
  String id;
  String titulo;
  String endereco;
  double? latitude;
  double? longitude;

  JobStatus status;

  String nomeCliente;
  String? telefoneCliente;

  bool clientePresente;
  String? tipoImovel;

  List<String> checklist;
  List<String> fotos;

  double? origemLat;
  double? origemLng;
  double? distanciaKm;

  Job({
    required this.id,
    required this.titulo,
    required this.endereco,
    this.latitude,
    this.longitude,
    this.status = JobStatus.novo,
    this.nomeCliente = '',
    this.telefoneCliente,
    this.clientePresente = true,
    this.tipoImovel,
    List<String>? checklist,
    List<String>? fotos,
    this.origemLat,
    this.origemLng,
    this.distanciaKm,
  })  : checklist = checklist ?? [],
        fotos = fotos ?? [];
}