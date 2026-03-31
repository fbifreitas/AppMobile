import 'package:flutter/foundation.dart';

import '../models/agenda_item.dart';
import '../models/app_message.dart';
import '../models/inspection_recovery_draft.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../repositories/job_repository.dart';
import '../repositories/mock_job_repository_controller.dart';
import '../repositories/preferences_repository.dart';
import '../services/inspection_radius_service.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  AppState(
    this.repository, [
    PreferencesRepository? preferencesRepository,
    LocationService? locationService,
  ]) : preferencesRepository =
           preferencesRepository ?? const SharedPreferencesRepository(),
       locationService = locationService ?? const LocationService() {
    _loadPreferences();
    _initMockData();
  }

  static const _devModeKey = 'developer_mode_enabled';
  static const _devToolsUnlockedKey = 'developer_tools_unlocked';
  static const _allowFarStartKey = 'developer_allow_far_start';
  static const _inspectionRecoveryKey = 'inspection_recovery_draft';
  static const _userPhotoKey = 'user_photo_path';

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
  String usuarioNomeCompleto = 'Fabio Freitas';

  DateTime? ultimoCheckin;

  bool permitirIniciarLonge = false;
  bool developerModeEnabled = false;
  bool developerToolsUnlocked = false;

  bool isLoadingJobs = false;
  String? jobsLoadError;

  InspectionRecoveryDraft? inspectionRecoveryDraft;

  // BL-035
  String? userPhotoPath;

  // BL-030
  List<AppMessage> mensagens = [];

  // BL-029
  List<AgendaItem> agendaItems = [];

  Future<void> _loadPreferences() async {
    // BL-010: resources are always blocked in release.
    if (!kReleaseMode) {
      developerModeEnabled =
          await preferencesRepository.getBool(_devModeKey) ?? false;
      developerToolsUnlocked =
          await preferencesRepository.getBool(_devToolsUnlockedKey) ?? false;
    }
    permitirIniciarLonge =
        await preferencesRepository.getBool(_allowFarStartKey) ?? false;

    userPhotoPath = await preferencesRepository.getString(_userPhotoKey);

    final recoveryJson = await preferencesRepository.getString(
      _inspectionRecoveryKey,
    );
    if (recoveryJson != null && recoveryJson.isNotEmpty) {
      try {
        inspectionRecoveryDraft = InspectionRecoveryDraft.fromJson(
          recoveryJson,
        );
      } catch (_) {
        inspectionRecoveryDraft = null;
      }
    }

    notifyListeners();
  }

  bool get devAccessAllowed =>
      developerModeEnabled && developerToolsUnlocked && !kReleaseMode;

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
          'Nao foi possivel carregar as vistorias no momento. Tente novamente.';
    } finally {
      isLoadingJobs = false;
      notifyListeners();
    }
  }

  String get primeiroNome {
    final nome = usuarioNomeCompleto.trim();
    if (nome.isEmpty) return 'Usuario';
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

  void atualizarReferenciasExternasJobAtual({
    String? idExterno,
    String? protocoloExterno,
  }) {
    final currentJob = jobAtual;
    if (currentJob == null) return;

    final normalizedExternalId = idExterno?.trim();
    final normalizedProtocol = protocoloExterno?.trim();

    if (normalizedExternalId != null && normalizedExternalId.isNotEmpty) {
      currentJob.idExterno = normalizedExternalId;
    }
    if (normalizedProtocol != null && normalizedProtocol.isNotEmpty) {
      currentJob.protocoloExterno = normalizedProtocol;
    }

    notifyListeners();
  }

  void adicionarJob(Job job) {
    jobs = List.of(jobs)..add(job);
    notifyListeners();
  }

  Future<void> finalizarJob() async {
    final currentJob = jobAtual;
    if (currentJob != null && repository is MockJobRepositoryController) {
      await (repository as MockJobRepositoryController).updateJobStatus(
        jobId: currentJob.id,
        status: JobStatus.finalizado,
      );
    }
    currentJob?.status = JobStatus.finalizado;
    await clearInspectionRecovery();
    jobAtual = null;
    notifyListeners();
  }

  bool get supportsMockJobControl => repository is MockJobRepositoryController;

  Future<void> resetMockJobsToDefault() async {
    if (repository is! MockJobRepositoryController) return;
    await (repository as MockJobRepositoryController).resetDefaultJobs();
    await carregarJobs();
  }

  Future<void> generateMockJobs({
    required int activeCount,
    required int completedCount,
    bool append = false,
  }) async {
    if (repository is! MockJobRepositoryController) return;

    if ((activeCount + completedCount) <= 0) {
      throw ArgumentError('Minimo de uma vistoria mock e obrigatorio.');
    }

    await (repository as MockJobRepositoryController).applyMockPlan(
      activeCount: activeCount,
      completedCount: completedCount,
      append: append,
    );
    await carregarJobs();
  }

  Future<void> setPermitirIniciarLonge(bool value) async {
    permitirIniciarLonge = value;
    notifyListeners();
    await _saveAllowFarStart(value);
  }

  Future<void> setDeveloperModeEnabled(bool value) async {
    if (kReleaseMode) return;
    developerModeEnabled = value;
    notifyListeners();
    await _saveDeveloperMode(value);
  }

  Future<bool> unlockDeveloperTools() async {
    if (kReleaseMode) return false;
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

  Future<void> updateUserPhoto(String path) async {
    final normalized = path.trim();
    userPhotoPath = normalized.isEmpty ? null : normalized;
    if (userPhotoPath == null) {
      await preferencesRepository.remove(_userPhotoKey);
    } else {
      await preferencesRepository.setString(_userPhotoKey, userPhotoPath!);
    }
    notifyListeners();
  }

  int get mensagensNaoLidas => mensagens.where((m) => !m.lida).length;

  void marcarMensagemLida(String id) {
    final index = mensagens.indexWhere((m) => m.id == id);
    if (index == -1) return;
    mensagens[index].lida = true;
    notifyListeners();
  }

  void marcarTodasLidas() {
    for (final m in mensagens) {
      m.lida = true;
    }
    notifyListeners();
  }

  void adicionarMensagem(AppMessage mensagem) {
    mensagens = [mensagem, ...mensagens];
    notifyListeners();
  }

  void setMockMensagens(List<AppMessage> items) {
    mensagens = List<AppMessage>.from(items);
    notifyListeners();
  }

  List<AgendaItem> itemsParaDia(DateTime day) {
    return agendaItems
        .where(
          (item) =>
              item.data.year == day.year &&
              item.data.month == day.month &&
              item.data.day == day.day,
        )
        .toList();
  }

  void adicionarAgendaItem(AgendaItem item) {
    agendaItems = [...agendaItems, item];
    notifyListeners();
  }

  void setMockAgendaItems(List<AgendaItem> items) {
    agendaItems = List<AgendaItem>.from(items);
    notifyListeners();
  }

  void setEnderecoBase(String value) {
    final endereco = value.trim();
    if (endereco.isEmpty) return;
    enderecoBase = endereco;
    notifyListeners();
  }

  void setResidencia({required double? lat, required double? lng}) {
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
        .resolve(tipoImovel: job.tipoImovel, subtipoImovel: job.subtipoImovel)
        .radiusMeters;
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

    final distance = locationService.calcularDistancia(
      lat1: currentLatitude,
      lon1: currentLongitude,
      lat2: job.latitude!,
      lon2: job.longitude!,
    );
    return inspectionRadiusService.isWithinRadius(
      distanceMeters: distance,
      tipoImovel: job.tipoImovel,
      subtipoImovel: job.subtipoImovel,
    );
  }

  bool shouldShowDevStart({
    required Job job,
    required double? currentLatitude,
    required double? currentLongitude,
  }) {
    if (!permitirIniciarLonge || !developerModeEnabled) return false;
    if (hasRecoverableInspectionForJob(job.id)) return false;
    return !canStartInspection(
      job: job,
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
    );
  }

  bool hasRecoverableInspectionForJob(String jobId) {
    return inspectionRecoveryDraft?.jobId == jobId;
  }

  String recoveryStageLabelForJob(String jobId) {
    if (!hasRecoverableInspectionForJob(jobId)) return '';
    return inspectionRecoveryDraft?.stageLabel ?? 'Etapa nao informada';
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

    inspectionRecoveryDraft = (inspectionRecoveryDraft ??
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
    Map<String, String>? niveis,
  }) async {
    final currentJob = jobAtual;
    if (currentJob == null) return;

    final nextStep1 = {
      ...step1Payload,
      'clientePresente': clientePresente,
      'tipoImovel': tipoImovel,
      'subtipoImovel': subtipoImovel,
      'porOndeComecar': porOndeComecar,
      if (niveis != null) 'niveis': Map<String, String>.from(niveis),
    };

    await setInspectionRecoveryStage(
      stageKey: 'checkin_step1',
      stageLabel: 'Check-in etapa 1',
      routeName: '/checkin',
      payload: {...inspectionRecoveryPayload, 'step1': nextStep1},
    );
  }

  Future<void> persistStep2Draft(
    Map<String, dynamic> step2Map, {
    Map<String, dynamic>? step2ConfigMap,
  }) async {
    final currentJob = jobAtual;
    if (currentJob == null) return;

    final draft = inspectionRecoveryDraft;
    final nextPayload = <String, dynamic>{
      ...inspectionRecoveryPayload,
      'step2': Map<String, dynamic>.from(step2Map),
    };

    final persistedStep2Config =
        step2ConfigMap ??
        (inspectionRecoveryPayload['step2Config'] is Map
            ? Map<String, dynamic>.from(
              (inspectionRecoveryPayload['step2Config'] as Map).map(
                (key, value) => MapEntry('$key', value),
              ),
            )
            : null);

    if (persistedStep2Config != null && persistedStep2Config.isNotEmpty) {
      nextPayload['step2Config'] = persistedStep2Config;
    }

    await setInspectionRecoveryStage(
      stageKey: draft?.stageKey ?? 'checkin_step2',
      stageLabel: draft?.stageLabel ?? 'Check-in etapa 2',
      routeName: draft?.routeName ?? '/checkin_step2',
      payload: nextPayload,
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

  Future<void> resetSessionAfterLogout() async {
    jobAtual = null;
    ultimaLatitude = null;
    ultimaLongitude = null;
    await clearInspectionRecovery();
  }

  void prioritizeRecoveryJob() {
    final draft = inspectionRecoveryDraft;
    if (draft == null) return;

    final index = jobs.indexWhere((job) => job.id == draft.jobId);
    if (index <= 0) return;

    final job = jobs.removeAt(index);
    jobs.insert(0, job);
  }

  void _initMockData() {
    final now = DateTime.now();

    mensagens = [
      AppMessage(
        id: 'msg-001',
        titulo: 'Vistoria confirmada',
        corpo:
            'Sua vistoria do dia ${now.day}/${now.month} foi confirmada pelo solicitante.',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      AppMessage(
        id: 'msg-002',
        titulo: 'Nova proposta disponivel',
        corpo: 'Voce tem uma nova proposta de vistoria aguardando aceite.',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      AppMessage(
        id: 'msg-003',
        titulo: 'Atualizacao do sistema',
        corpo: 'O aplicativo foi atualizado com novas funcionalidades.',
        timestamp: now.subtract(const Duration(days: 1)),
        lida: true,
      ),
    ];

    agendaItems = [
      AgendaItem(
        id: 'agenda-001',
        data: DateTime(now.year, now.month, now.day + 1, 9, 0),
        titulo: 'Vistoria Residencial SP-001',
        endereco: 'Av. Paulista, 1000, Sao Paulo',
        jobId: 'job-001',
      ),
      AgendaItem(
        id: 'agenda-002',
        data: DateTime(now.year, now.month, now.day + 3, 14, 30),
        titulo: 'Vistoria Casa RIO-002',
        endereco: 'Rua das Flores, 200, Rio de Janeiro',
        jobId: 'job-002',
      ),
      AgendaItem(
        id: 'agenda-003',
        data: DateTime(now.year, now.month, now.day + 7, 10, 0),
        titulo: 'Vistoria Comercial SP-003',
        endereco: 'Rua Augusta, 500, Sao Paulo',
        status: AgendaItemStatus.confirmado,
      ),
      AgendaItem(
        id: 'agenda-004',
        data: DateTime(now.year, now.month, now.day, 15, 0),
        titulo: 'Vistoria Hoje - Apto 102',
        endereco: 'Rua Bela Vista, 300, Sao Paulo',
        status: AgendaItemStatus.confirmado,
      ),
    ];
  }
}
