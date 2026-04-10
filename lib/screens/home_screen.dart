import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../branding/brand_provider.dart';
import '../models/home_location_snapshot.dart';
import '../models/job.dart';
import '../models/overlay_camera_capture_result.dart';
import '../config/checkin_step2_config.dart';
import '../services/app_navigation_coordinator.dart';
import '../services/home_bootstrap_service.dart';
import '../services/home_location_service.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../services/inspection_sync_queue_service.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../state/app_state.dart';
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

  bool _bootstrapped = false;
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
      appState.atualizarReferenciasExternasJob(
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
    final isRecovery = appState.hasRecoverableInspectionForJob(job.id);
    final recoveryRoute = appState.inspectionRecoveryDraft?.routeName;

    appState.selecionarJob(job);
    if (!isRecovery) {
      await appState.beginInspectionRecovery(job);
    }

    if (!mounted) return;

    if (isRecovery) {
      if (recoveryRoute == '/inspection_review') {
        final reviewPayload = appState.inspectionRecoveryPayload['review'];
        final tipoImovel =
            (reviewPayload is Map<String, dynamic>)
                ? reviewPayload['tipoImovel'] as String?
                : null;
        final captures = <OverlayCameraCaptureResult>[];

        if (reviewPayload is Map<String, dynamic>) {
          final rawCaptures = reviewPayload['captures'];
          if (rawCaptures is List) {
            for (final rawCapture in rawCaptures) {
              if (rawCapture is Map<String, dynamic>) {
                captures.add(OverlayCameraCaptureResult.fromMap(rawCapture));
              }
            }
          }
        }

        if (tipoImovel != null) {
          final initialData =
              appState.step2Payload.isNotEmpty
                  ? CheckinDynamicConfigService.instance.restoreStep2Model(
                    tipo: TipoImovelExtension.fromString(tipoImovel),
                    step2Payload: appState.step2Payload,
                  )
                  : null;

          widget.flowCoordinator.restoreReviewRecoveryFlow(
            context,
            tipoImovel: tipoImovel,
            initialData: initialData,
            onContinue: (model) async {
              await appState.persistStep2Draft(model.toMap());
            },
            captures: captures,
          );
          return;
        }
      }

      if (recoveryRoute == '/checkin_step2') {
        final tipoImovel = appState.step1Payload['tipoImovel'] as String?;
        final initialData =
            appState.step2Payload.isNotEmpty
                ? CheckinDynamicConfigService.instance.restoreStep2Model(
                  tipo: TipoImovelExtension.fromString(
                    tipoImovel ?? 'Urbano',
                  ),
                  step2Payload: appState.step2Payload,
                )
                : null;

        if (tipoImovel != null) {
          widget.flowCoordinator.restoreCheckinStep2RecoveryFlow(
            context,
            tipoImovel: tipoImovel,
            initialData: initialData,
            onContinue: (model) async {
              await appState.persistStep2Draft(model.toMap());
            },
          );
          return;
        }
      }
    }

    widget.flowCoordinator.openCheckin(context);
  }

  void _openNotifications() {
    _appNavigationCoordinator.openNotifications(context);
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
    final config = BrandProvider.configOf(context);
    final flags = config.featureFlags;

    final tabBodies = <Widget>[
      RefreshIndicator(
        onRefresh: _manualRefresh,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            HomeHeader(
              firstName: appState.primeiroNome,
              unreadMessages: appState.mensagensNaoLidas,
              photoPath: appState.userPhotoPath,
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Painel'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Vistorias'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
        ],
      ),
      body: SafeArea(child: tabBodies[_currentTabIndex]),
    );
  }
}
