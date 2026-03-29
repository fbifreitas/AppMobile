import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/checkin_step2_model.dart';
import '../models/home_location_snapshot.dart';
import '../models/job.dart';
import '../services/home_bootstrap_service.dart';
import '../services/home_location_service.dart';
import '../services/inspection_sync_queue_service.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../state/app_state.dart';
import 'overlay_camera_screen.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/jobs_section.dart';
import '../widgets/home/proposals_section.dart';
import 'checkin_screen.dart';
import 'checkin_step2_screen.dart';
import 'completed_inspections_screen.dart';
import 'inspection_review_screen.dart';
import 'notifications_screen.dart';
import 'operational_hub_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeLocationService _homeLocationService = const HomeLocationService();
  final HomeBootstrapService _homeBootstrapService = const HomeBootstrapService();
  final InspectionSyncQueueService _syncQueueService =
      const InspectionSyncQueueService();

  bool _bootstrapped = false;
  int _currentTabIndex = 0;
  HomeLocationSnapshot _locationSnapshot = HomeLocationSnapshot.initial();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bootstrapped) return;
      _bootstrapped = true;
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final appState = context.read<AppState>();
    await _syncQueueService.flush();
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
    await _syncQueueService.flush();
    if (!mounted) return;

    await appState.carregarJobs();
    await _refreshLocation();
  }

  Future<void> _refreshLocation() async {
    if (!mounted) return;

    setState(() {
      _locationSnapshot = _locationSnapshot.copyWith(
        loading: true,
        clearErrorMessage: true,
      );
    });

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
        final tipoImovel = (reviewPayload is Map<String, dynamic>)
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InspectionReviewScreen(
                captures: captures,
                tipoImovel: tipoImovel,
              ),
            ),
          );
          return;
        }
      }

      if (recoveryRoute == '/checkin_step2') {
        final tipoImovel = appState.step1Payload['tipoImovel'] as String?;
        final initialData = appState.step2Payload.isNotEmpty
            ? CheckinStep2Model.fromMap(appState.step2Payload)
            : null;

        if (tipoImovel != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CheckinStep2Screen(
                tipoImovel: tipoImovel,
                initialData: initialData,
                onContinue: (model) async {
                  await appState.persistStep2Draft(model.toMap());
                },
              ),
            ),
          );
          return;
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CheckinScreen(),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _openOperationalHub() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OperationalHubScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tabBodies = <Widget>[
      RefreshIndicator(
        onRefresh: _manualRefresh,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            HomeHeader(
              firstName: appState.primeiroNome,
              onNotificationsTap: _openNotifications,
              onSettingsTap: _openSettings,
              onHubTap: _openOperationalHub,
              showHubButton: appState.developerModeEnabled,
            ),
            const SizedBox(height: 16),
            JobsSection(
              appState: appState,
              currentLatitude: appState.ultimaLatitude ?? _locationSnapshot.latitude,
              currentLongitude: appState.ultimaLongitude ?? _locationSnapshot.longitude,
              useDistanceMetrics: true,
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
                await _handleStartInspection(
                  appState: appState,
                  job: job,
                );
              },
            ),
            const SizedBox(height: 14),
            const ProposalsSection(),
          ],
        ),
      ),
      const CompletedInspectionsScreen(),
      const Center(
        child: Text(
          'Agenda em evolucao',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Painel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Vistorias',
          ),
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
