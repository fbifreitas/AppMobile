import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/home_location_snapshot.dart';
import '../models/operational_hub_item.dart';
import '../services/home_location_service.dart';
import '../services/location_service.dart';
import '../services/operational_hub_registry_service.dart';
import '../state/app_state.dart';
import '../state/field_operation_state.dart';
import '../widgets/home/location_status_card.dart';
import '../widgets/home/startup_status_card.dart';
import '../widgets/operational_hub_grid.dart';
import 'admin_remote_config_center_screen.dart';
import 'assistive_intelligence_center_screen.dart';
import 'checkin_screen.dart';
import 'clean_code_audit_center_screen.dart';
import 'data_governance_center_screen.dart';
import 'field_operations_center_screen.dart';
import 'observability_support_center_screen.dart';
import 'operational_snapshot_export_screen.dart';
import 'production_readiness_center_screen.dart';
import 'quality_stability_center_screen.dart';

class OperationalHubScreen extends StatefulWidget {
  const OperationalHubScreen({super.key});

  @override
  State<OperationalHubScreen> createState() => _OperationalHubScreenState();
}

class _OperationalHubScreenState extends State<OperationalHubScreen> {
  final HomeLocationService _homeLocationService = const HomeLocationService();

  HomeLocationSnapshot _locationSnapshot = HomeLocationSnapshot.initial();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLocation();
    });
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

  @override
  Widget build(BuildContext context) {
    final items = const OperationalHubRegistryService().items();
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub operacional'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Centrais integradas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acesse o fluxo principal e os painéis técnicos a partir de um único ponto.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          StartupStatusCard(
            isLoadingJobs: appState.isLoadingJobs,
            jobsCount: appState.jobs.length,
            jobsLoadError: appState.jobsLoadError,
          ),
          const SizedBox(height: 12),
          LocationStatusCard(
            loading: _locationSnapshot.loading,
            errorMessage: _locationSnapshot.errorMessage,
            lastSyncAt: _locationSnapshot.lastSyncAt,
            latitude: appState.ultimaLatitude ?? _locationSnapshot.latitude,
            longitude: appState.ultimaLongitude ?? _locationSnapshot.longitude,
            onRefresh: _refreshLocation,
          ),
          const SizedBox(height: 16),
          OperationalHubGrid(
            items: items,
            onTap: (item) => _open(context, item),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, OperationalHubItem item) {
    Widget destination;

    switch (item.id) {
      case 'checkin':
        destination = const CheckinScreen();
        break;
      case 'field_ops':
        destination = ChangeNotifierProvider<FieldOperationState>(
          create: (_) => FieldOperationState.demo(),
          child: const FieldOperationsCenterScreen(),
        );
        break;
      case 'assistive':
        destination = const AssistiveIntelligenceCenterScreen();
        break;
      case 'quality':
        destination = const QualityStabilityCenterScreen();
        break;
      case 'observability':
        destination = const ObservabilitySupportCenterScreen();
        break;
      case 'governance':
        destination = const DataGovernanceCenterScreen();
        break;
      case 'production':
        destination = const ProductionReadinessCenterScreen();
        break;
      case 'admin':
        destination = const AdminRemoteConfigCenterScreen();
        break;
      case 'clean_code':
        destination = const CleanCodeAuditCenterScreen();
        break;
      case 'export':
        destination = const OperationalSnapshotExportScreen();
        break;
      default:
        destination = const CheckinScreen();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}
