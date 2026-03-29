import 'package:flutter/material.dart';

import '../models/inspection_recovery_draft.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../repositories/job_repository.dart';
import '../repositories/preferences_repository.dart';
import '../services/inspection_radius_service.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  AppState(
    this.repository, [
    PreferencesRepository? preferencesRepository,
    LocationService? locationService,
  ])  : preferencesRepository =
            preferencesRepository ?? const SharedPreferencesRepository(),
        locationService = locationService ?? const LocationService() {
    _loadPreferences();
  }

  static const _devModeKey = 'developer_mode_enabled';
  static const _devToolsUnlockedKey = 'developer_tools_unlocked';
  static const _allowFarStartKey = 'developer_allow_far_start';
  static const _inspectionRecoveryKey = 'inspection_recovery_draft';

  final JobRepository repository;
  final PreferencesRepository preferencesRepository;
  final LocationService locationService;
  final InspectionRadiusService inspectionRadiusService =
      const InspectionRadiusService();

  List<Job> jobs = [];
  Job? jobAtual;

  double? ultimaLatitude;
  double? ultimaLongitude;

  double? residenciaLat = -23.5614;
  double? residenciaLng = -46.6559;

  String enderecoBase =
      'Apartamento - Condominio Spazio Belem, Av. Alvaro Ramos, 760 Apto 102, Fabio Freitas (Prop.)';
  String usuarioNomeCompleto = 'Fábio Freitas';

  DateTime? ultimoCheckin;

  bool permitirIniciarLonge = false;
  bool developerModeEnabled = false;
  bool developerToolsUnlocked = false;

  bool isLoadingJobs = false;
  String? jobsLoadError;

  InspectionRecoveryDraft? inspectionRecoveryDraft;

  Future<void> _loadPreferences() async {
    developerModeEnabled = await preferencesRepository.getBool(_devModeKey) ?? false;
    developerToolsUnlocked =
        await preferencesRepository.getBool(_devToolsUnlockedKey) ?? false;
    permitirIniciarLonge =
        await preferencesRepository.getBool(_allowFarStartKey) ?? false;

    final recoveryJson = await preferencesRepository.getString(
      _inspectionRecoveryKey,
    );
    if (recoveryJson != null && recoveryJson.isNotEmpty) {
      try {
        inspectionRecoveryDraft = InspectionRecoveryDraft.fromJson(recoveryJson);
      } catch (_) {
        inspectionRecoveryDraft = null;
      }
    }

    notifyListeners();
  }

  Future<void> _saveDeveloperMode(bool value) async {
    await preferencesRepository.setBool(_devModeKey, value);
  }

  Future<void> _saveDeveloperToolsUnlocked(bool value) async {
    await preferencesRepository.setBool(_devToolsUnlockedKey, value);
  }

  Future<void> _saveAllowFarStart(bool value) async {
    await preferencesRepository.setBool(_allowFarStartKey, value);
  }

  Future<void> _saveInspectionRecoveryDraft() async {
    if (inspectionRecoveryDraft == null) {
      await preferencesRepository.remove(_inspectionRecoveryKey);
      return;
    }
    await preferencesRepository.setString(
      _inspectionRecoveryKey,
      inspectionRecoveryDraft!.toJson(),
    );
  }

  Future<void> carregarJobs() async {
    if (isLoadingJobs) return;

    isLoadingJobs = true;
    jobsLoadError = null;
    notifyListeners();

    try {
      final result = await repository.getJobs().timeout(
            const Duration(seconds: 5),
          );
      jobs = List<Job>.from(result);
      prioritizeRecoveryJob();
    } catch (_) {
      jobs = [];
      jobsLoadError =
          'Não foi possível carregar as vistorias no momento. Tente novamente.';
    } finally {
      isLoadingJobs = false;
      notifyListeners();
    }
  }

  String get primeiroNome {
    final nome = usuarioNomeCompleto.trim();
    if (nome.isEmpty) return 'Usuário';
    return nome.split(RegExp(r'\s+')).first;
  }

  void setUsuarioNomeCompleto(String value) {
    final nome = value.trim();
    if (nome.isEmpty) return;
    usuarioNomeCompleto = nome;
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

  Future<void> fazerCheckin({
    required bool clientePresente,
    String? tipoImovel,
  }) async {
    if (jobAtual == null) return;
    jobAtual!.clientePresente = clientePresente;
    jobAtual!.tipoImovel = tipoImovel;
    jobAtual!.status = JobStatus.emAndamento;
    ultimoCheckin = DateTime.now();
    await setInspectionRecoveryStage(
      stageKey: 'checkin_step1',
      stageLabel: 'Check-in etapa 1',
      routeName: '/checkin',
      payload: {
        ...inspectionRecoveryPayload,
        'step1': {
          ...step1Payload,
          'clientePresente': clientePresente,
          'tipoImovel': tipoImovel,
        },
      },
    );
    notifyListeners();
  }

  void salvarChecklist(List itens) {
    jobAtual?.checklist = List<String>.from(
      itens.map((item) => item.toString()),
    );
    notifyListeners();
  }

  void adicionarFoto(String path) {
    jobAtual?.fotos.add(path);
    notifyListeners();
  }

  Future<void> finalizarJob() async {
    jobAtual?.status = JobStatus.finalizado;
    await clearInspectionRecovery();
    notifyListeners();
  }

  Future<void> setPermitirIniciarLonge(bool value) async {
    permitirIniciarLonge = value;
    notifyListeners();
    await _saveAllowFarStart(value);
  }

  Future<void> setDeveloperModeEnabled(bool value) async {
    developerModeEnabled = value;
    notifyListeners();
    await _saveDeveloperMode(value);
  }

  Future<bool> unlockDeveloperTools() async {
    developerToolsUnlocked = true;
    notifyListeners();
    await _saveDeveloperToolsUnlocked(true);
    return developerToolsUnlocked;
  }

  Future<void> lockDeveloperTools() async {
    developerToolsUnlocked = false;
    developerModeEnabled = false;
    notifyListeners();
    await _saveDeveloperToolsUnlocked(false);
    await _saveDeveloperMode(false);
  }

  void setEnderecoBase(String value) {
    final endereco = value.trim();
    if (endereco.isEmpty) return;
    enderecoBase = endereco;
    notifyListeners();
  }

  void setResidencia({
    required double? lat,
    required double? lng,
  }) {
    residenciaLat = lat;
    residenciaLng = lng;
    notifyListeners();
  }

  void atualizarUltimaLocalizacao(double lat, double lng) {
    ultimaLatitude = lat;
    ultimaLongitude = lng;
    notifyListeners();
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

    return locationService.calcularDistancia(
      lat1: atualLat,
      lon1: atualLng,
      lat2: jobAtual!.latitude!,
      lon2: jobAtual!.longitude!,
    );
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

  double resolveInspectionRadiusMeters(Job job) {
    return inspectionRadiusService
        .resolve(
          tipoImovel: job.tipoImovel,
          subtipoImovel: job.subtipoImovel,
        )
        .radiusMeters;
  }

  bool hasRecoverableInspectionForJob(String jobId) {
    return inspectionRecoveryDraft?.jobId == jobId;
  }

  String recoveryStageLabelForJob(String jobId) {
    if (!hasRecoverableInspectionForJob(jobId)) return '';
    return inspectionRecoveryDraft?.stageLabel ?? 'Etapa não informada';
  }

  Future<void> beginInspectionRecovery(Job job) async {
    selecionarJob(job);
    inspectionRecoveryDraft = InspectionRecoveryDraft.initial(jobId: job.id);
    await _saveInspectionRecoveryDraft();
    prioritizeRecoveryJob();
    notifyListeners();
  }

  Future<void> setInspectionRecoveryStage({
    required String stageKey,
    required String stageLabel,
    required String routeName,
    Map<String, dynamic> payload = const {},
  }) async {
    final currentJob = jobAtual;
    if (currentJob == null) return;

    inspectionRecoveryDraft =
        (inspectionRecoveryDraft ??
                InspectionRecoveryDraft.initial(jobId: currentJob.id))
            .copyWith(
      jobId: currentJob.id,
      stageKey: stageKey,
      stageLabel: stageLabel,
      routeName: routeName,
      updatedAtIso: DateTime.now().toIso8601String(),
      payload: payload,
    );

    await _saveInspectionRecoveryDraft();
    prioritizeRecoveryJob();
    notifyListeners();
  }

  Future<void> persistStep1Draft({
    bool? clientePresente,
    String? tipoImovel,
    String? subtipoImovel,
    String? porOndeComecar,
  }) async {
    final currentJob = jobAtual;
    if (currentJob == null) return;

    final nextStep1 = {
      ...step1Payload,
      'clientePresente': clientePresente,
      'tipoImovel': tipoImovel,
      'subtipoImovel': subtipoImovel,
      'porOndeComecar': porOndeComecar,
    };

    await setInspectionRecoveryStage(
      stageKey: 'checkin_step1',
      stageLabel: 'Check-in etapa 1',
      routeName: '/checkin',
      payload: {
        ...inspectionRecoveryPayload,
        'step1': nextStep1,
      },
    );
  }

  Future<void> persistStep2Draft(Map<String, dynamic> step2Map) async {
    final currentJob = jobAtual;
    if (currentJob == null) return;

    await setInspectionRecoveryStage(
      stageKey: 'checkin_step2',
      stageLabel: 'Check-in etapa 2',
      routeName: '/checkin_step2',
      payload: {
        ...inspectionRecoveryPayload,
        'step2': step2Map,
      },
    );
  }

  Map<String, dynamic> get inspectionRecoveryPayload =>
      Map<String, dynamic>.from(inspectionRecoveryDraft?.payload ?? const {});

  Map<String, dynamic> get step1Payload =>
      Map<String, dynamic>.from(inspectionRecoveryPayload['step1'] ?? const {});

  Map<String, dynamic> get step2Payload =>
      Map<String, dynamic>.from(inspectionRecoveryPayload['step2'] ?? const {});

  Future<void> clearInspectionRecovery() async {
    inspectionRecoveryDraft = null;
    await _saveInspectionRecoveryDraft();
    notifyListeners();
  }

  void prioritizeRecoveryJob() {
    final draft = inspectionRecoveryDraft;
    if (draft == null) return;

    final index = jobs.indexWhere((job) => job.id == draft.jobId);
    if (index <= 0) return;

    final job = jobs.removeAt(index);
    jobs.insert(0, job);
  }

  bool canStartInspection({
    required Job job,
    required double? currentLatitude,
    required double? currentLongitude,
  }) {
    if (hasRecoverableInspectionForJob(job.id)) {
      return true;
    }

    if (currentLatitude == null ||
        currentLongitude == null ||
        job.latitude == null ||
        job.longitude == null) {
      return false;
    }

    final distanceMeters = locationService.calcularDistancia(
      lat1: currentLatitude,
      lon1: currentLongitude,
      lat2: job.latitude!,
      lon2: job.longitude!,
    );

    return inspectionRadiusService.isWithinRadius(
      distanceMeters: distanceMeters,
      tipoImovel: job.tipoImovel,
      subtipoImovel: job.subtipoImovel,
    );
  }

  bool shouldShowDevStart({
    required Job job,
    required double? currentLatitude,
    required double? currentLongitude,
  }) {
    if (hasRecoverableInspectionForJob(job.id)) {
      return false;
    }

    if (!developerModeEnabled || !permitirIniciarLonge) {
      return false;
    }

    if (currentLatitude == null ||
        currentLongitude == null ||
        job.latitude == null ||
        job.longitude == null) {
      return true;
    }

    final distanceMeters = locationService.calcularDistancia(
      lat1: currentLatitude,
      lon1: currentLongitude,
      lat2: job.latitude!,
      lon2: job.longitude!,
    );

    return !inspectionRadiusService.isWithinRadius(
      distanceMeters: distanceMeters,
      tipoImovel: job.tipoImovel,
      subtipoImovel: job.subtipoImovel,
    );
  }
}
