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
  String? subtipoImovel;
  List checklist;
  List fotos;
  double? origemLat;
  double? origemLng;
  double? distanciaKm;
  String? idExterno;
  String? protocoloExterno;

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
    this.subtipoImovel,
    List? checklist,
    List? fotos,
    this.origemLat,
    this.origemLng,
    this.distanciaKm,
    this.idExterno,
    this.protocoloExterno,
  }) : checklist = checklist ?? [],
       fotos = fotos ?? [];
}
