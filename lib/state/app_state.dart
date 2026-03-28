import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/job.dart';
import '../models/job_status.dart';
import '../repositories/job_repository.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository) {
    _loadPreferences();
  }

  static const _devModeKey = 'developer_mode_enabled';
  static const _devToolsUnlockedKey = 'developer_tools_unlocked';
  static const _allowFarStartKey = 'developer_allow_far_start';

  final JobRepository repository;

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

  bool permitirIniciarLonge = true;
  bool developerModeEnabled = false;
  bool developerToolsUnlocked = false;

  bool isLoadingJobs = false;
  String? jobsLoadError;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    developerModeEnabled = prefs.getBool(_devModeKey) ?? false;
    developerToolsUnlocked = prefs.getBool(_devToolsUnlockedKey) ?? false;
    permitirIniciarLonge = prefs.getBool(_allowFarStartKey) ?? true;
    notifyListeners();
  }

  Future<void> _saveDeveloperMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devModeKey, value);
  }

  Future<void> _saveDeveloperToolsUnlocked(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devToolsUnlockedKey, value);
  }

  Future<void> _saveAllowFarStart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allowFarStartKey, value);
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

  void fazerCheckin({
    required bool clientePresente,
    String? tipoImovel,
  }) {
    if (jobAtual == null) return;
    jobAtual!.clientePresente = clientePresente;
    jobAtual!.tipoImovel = tipoImovel;
    jobAtual!.status = JobStatus.emAndamento;
    ultimoCheckin = DateTime.now();
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

  void finalizarJob() {
    jobAtual?.status = JobStatus.finalizado;
    notifyListeners();
  }

  bool podeIniciarVistoria(double distanciaMetros) {
    if (permitirIniciarLonge) return true;
    return distanciaMetros <= 100;
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

    return LocationService().calcularDistancia(
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
}
