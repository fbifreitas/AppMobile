import 'job_status.dart';
import 'smart_execution_plan.dart';

class Job {
  String id;
  String titulo;
  String endereco;
  double? latitude;
  double? longitude;
  DateTime? deadlineAt;
  DateTime? createdAt;
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
  SmartExecutionPlan? smartExecutionPlan;

  Job({
    required this.id,
    required this.titulo,
    required this.endereco,
    this.latitude,
    this.longitude,
    this.deadlineAt,
    this.createdAt,
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
    this.smartExecutionPlan,
  }) : checklist = checklist ?? [],
       fotos = fotos ?? [];

  String get title => titulo;
  set title(String value) => titulo = value;

  String get address => endereco;
  set address(String value) => endereco = value;

  String get customerName => nomeCliente;
  set customerName(String value) => nomeCliente = value;

  String? get customerPhone => telefoneCliente;
  set customerPhone(String? value) => telefoneCliente = value;

  bool get contactPresent => clientePresente;
  set contactPresent(bool value) => clientePresente = value;

  String? get assetType => tipoImovel;
  set assetType(String? value) => tipoImovel = value;

  String? get assetSubtype => subtipoImovel;
  set assetSubtype(String? value) => subtipoImovel = value;

  String? get externalId => idExterno;
  set externalId(String? value) => idExterno = value;

  String? get externalProtocol => protocoloExterno;
  set externalProtocol(String? value) => protocoloExterno = value;
}
