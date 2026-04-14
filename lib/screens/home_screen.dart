import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../branding/brand_provider.dart';
import '../models/home_location_snapshot.dart';
import '../models/job.dart';
import '../services/app_navigation_coordinator.dart';
import '../services/home_bootstrap_service.dart';
import '../services/home_location_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../services/inspection_menu_service.dart';
import '../services/inspection_start_inspection_use_case.dart';
import '../services/inspection_sync_queue_service.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/jobs_section.dart';
import '../widgets/home/proposals_section.dart';
import 'agenda_screen.dart';
import 'completed_inspections_screen.dart';

class HomeScreen extends StatefulWidget {
  final InspectionFlowCoordinator flowCoordinator;
  final AppNavigationCoordinator? appNavigationCoordinator;

  const HomeScreen({
    super.key,
    this.flowCoordinator = const DefaultInspectionFlowCoordinator(),
    this.appNavigationCoordinator,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final HomeLocationService _homeLocationService = const HomeLocationService();
  final HomeBootstrapService _homeBootstrapService =
      const HomeBootstrapService();
  final InspectionSyncQueueService _syncQueueService =
      const InspectionSyncQueueService();
  final InspectionMenuService _inspectionMenuService =
      InspectionMenuService.instance;
  final InspectionStartInspectionUseCase _startInspectionUseCase =
      InspectionStartInspectionUseCase.instance;
  final ImagePicker _imagePicker = ImagePicker();

  bool _bootstrapped = false;
  bool _authDrivenJobsBootstrapQueued = false;
  bool _refreshingLocation = false;
  int _currentTabIndex = 0;
  HomeLocationSnapshot _locationSnapshot = HomeLocationSnapshot.initial();

  AppNavigationCoordinator get _appNavigationCoordinator =>
      widget.appNavigationCoordinator ??
      DefaultAppNavigationCoordinator(
        inspectionFlowCoordinator: widget.flowCoordinator,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bootstrapped) return;
      _bootstrapped = true;
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final appState = context.read<AppState>();
    await _inspectionMenuService.reload();
    final flushResult = await _syncQueueService.flush();
    _applySyncedReferences(appState, flushResult);
    if (!mounted) return;

    final bootstrap = _homeBootstrapService.evaluate(
      hasJobs: appState.jobs.isNotEmpty,
      isLoadingJobs: appState.isLoadingJobs,
    );

    if (bootstrap.shouldLoadJobs) {
      await appState.carregarJobs();
    }

    if (bootstrap.shouldRefreshLocation) {
      await _refreshLocation();
    }
  }

  Future<void> _manualRefresh() async {
    final appState = context.read<AppState>();
    await _inspectionMenuService.reload();
    final flushResult = await _syncQueueService.flush();
    _applySyncedReferences(appState, flushResult);
    if (!mounted) return;

    await appState.carregarJobs();
    await _refreshLocation();
  }

  void _applySyncedReferences(
    AppState appState,
    InspectionSyncQueueFlushResult flushResult,
  ) {
    for (final reference in flushResult.syncedReferences) {
      appState.marcarJobSincronizado(
        jobId: reference.jobId,
        idExterno: reference.externalId,
        protocoloExterno: reference.protocolId ?? reference.processNumber,
      );
    }
  }

  Future<void> _refreshLocation() async {
    if (!mounted || _refreshingLocation) return;
    _refreshingLocation = true;

    setState(() {
      _locationSnapshot = _locationSnapshot.copyWith(
        loading: true,
        clearErrorMessage: true,
      );
    });

    try {
      final updatedSnapshot = await _homeLocationService.refresh(
        current: _locationSnapshot,
        readCurrentLocation: () async {
          final position = await LocationService().getCurrentLocation();
          return HomeLocationPoint(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        },
        writeLocation: (latitude, longitude) {
          context.read<AppState>().atualizarUltimaLocalizacao(
            latitude,
            longitude,
          );
        },
      );

      if (!mounted) return;

      setState(() {
        _locationSnapshot = updatedSnapshot;
      });
    } finally {
      _refreshingLocation = false;
    }
  }

  Future<void> _handleNavigateToJob({
    required double? latitude,
    required double? longitude,
    required String address,
  }) async {
    final mapService = MapService();

    if (latitude != null && longitude != null) {
      await mapService.abrirWaze(latitude, longitude);
      return;
    }

    await mapService.abrirBuscaPorEndereco(address);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _currentTabIndex == 0) {
      _inspectionMenuService.reload();
      _refreshLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleStartInspection({
    required AppState appState,
    required Job job,
  }) async {
    await _startInspectionUseCase.execute(
      context,
      appState: appState,
      job: job,
      flowCoordinator: widget.flowCoordinator,
    );
  }

  void _openNotifications() {
    _appNavigationCoordinator.openNotifications(context);
  }

  Future<void> _captureUserPhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1280,
    );

    if (photo == null || !mounted) return;

    await context.read<AppState>().updateUserPhoto(photo.path);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto de perfil atualizada.')),
    );
  }

  void _openSettings() {
    _appNavigationCoordinator.openSettings(context);
  }

  void _openOperationalHub() {
    _appNavigationCoordinator.openOperationalHub(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final authState = context.watch<AuthState?>();
    if ((authState?.status == AppAuthStatus.active) &&
        (authState?.permissionsOnboardingCompleted ?? false) &&
        appState.jobs.isEmpty &&
        !appState.isLoadingJobs &&
        appState.jobsLoadError == null &&
        !_authDrivenJobsBootstrapQueued) {
      _authDrivenJobsBootstrapQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await context.read<AppState>().carregarJobs();
        _authDrivenJobsBootstrapQueued = false;
      });
    }
    final config = BrandProvider.configOf(context);
    final flags = config.featureFlags;
    final firstName = _resolveFirstName(
      authState?.userNome,
      appState.usuarioNomeCompleto,
    );

    final tabBodies = <Widget>[
      RefreshIndicator(
        onRefresh: _manualRefresh,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            HomeHeader(
              firstName: firstName,
              unreadMessages: appState.mensagensNaoLidas,
              photoPath: appState.userPhotoPath,
              onPhotoTap: _captureUserPhoto,
              onNotificationsTap: _openNotifications,
              onSettingsTap: _openSettings,
              onHubTap: _openOperationalHub,
              showHubButton: appState.developerModeEnabled,
              subtitle: config.copyText(
                'home_header_subtitle',
                defaultValue: 'Seu painel operacional de hoje',
              ),
            ),
            const SizedBox(height: 16),
            JobsSection(
              appState: appState,
              currentLatitude:
                  appState.ultimaLatitude ?? _locationSnapshot.latitude,
              currentLongitude:
                  appState.ultimaLongitude ?? _locationSnapshot.longitude,
              useDistanceMetrics: true,
              sectionTitle: config.copyText(
                'jobs_section_title',
                defaultValue: 'MEUS JOBS DE HOJE',
              ),
              geofenceRequired: flags.geofenceRequired,
              startLabel: config.copyTextOrNull('job_start_label'),
              resumeLabel: config.copyTextOrNull('job_resume_label'),
              startBlockedLabel: config.copyTextOrNull('job_start_blocked_label'),
              navigateLabel: config.copyTextOrNull('job_navigate_label'),
              withinRangeLabel: config.copyTextOrNull('job_within_range_label'),
              outOfRangeLabel: config.copyTextOrNull('job_out_of_range_label'),
              onNavigateToJob: ({
                required double? latitude,
                required double? longitude,
                required String address,
              }) {
                return _handleNavigateToJob(
                  latitude: latitude,
                  longitude: longitude,
                  address: address,
                );
              },
              onStartInspection: (job) async {
                await _handleStartInspection(appState: appState, job: job);
              },
            ),
            if (flags.proposalsBlockEnabled) ...[
              const SizedBox(height: 14),
              ProposalsSection(
                sectionTitle: config.copyText(
                  'proposals_section_title',
                  defaultValue: 'NOVAS PROPOSTAS',
                ),
                swipeRequired: flags.swipeRequired,
                financialSummaryEnabled: flags.financialSummaryEnabled,
              ),
            ],
          ],
        ),
      ),
      const CompletedInspectionsScreen(),
      const AgendaScreen(),
    ];

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: config.copyText('nav_home_label', defaultValue: 'Painel'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: config.copyText('nav_jobs_label', defaultValue: 'Vistorias'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: config.copyText('nav_agenda_label', defaultValue: 'Agenda'),
          ),
        ],
      ),
      body: SafeArea(child: tabBodies[_currentTabIndex]),
    );
  }

  String _resolveFirstName(String? sessionName, String fallbackName) {
    final normalizedSessionName = sessionName?.trim() ?? '';
    if (normalizedSessionName.isNotEmpty) {
      return normalizedSessionName.split(RegExp(r'\s+')).first;
    }
    return fallbackName.trim().isEmpty
        ? 'Usuario'
        : fallbackName.trim().split(RegExp(r'\s+')).first;
  }
}
