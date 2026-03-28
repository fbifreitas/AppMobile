import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/map_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/jobs_section.dart';
import '../widgets/home/operational_hub_card.dart';
import '../widgets/home/proposals_section.dart';
import '../widgets/home/startup_status_card.dart';
import 'checkin_screen.dart';
import 'notifications_screen.dart';
import 'operational_hub_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bootstrapped = false;

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

    if (appState.jobs.isEmpty && !appState.isLoadingJobs) {
      await appState.carregarJobs();
    }
  }

  Future<void> _manualRefresh() async {
    final appState = context.read<AppState>();
    await appState.carregarJobs();
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

  void _handleStartInspection({
    required AppState appState,
    required dynamic job,
  }) {
    appState.selecionarJob(job);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _manualRefresh,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              HomeHeader(
                firstName: appState.primeiroNome,
                onNotificationsTap: _openNotifications,
                onSettingsTap: _openSettings,
                onHubTap: _openOperationalHub,
              ),
              const SizedBox(height: 16),
              OperationalHubCard(
                onOpen: _openOperationalHub,
              ),
              const SizedBox(height: 16),
              StartupStatusCard(
                isLoadingJobs: appState.isLoadingJobs,
                jobsCount: appState.jobs.length,
                jobsLoadError: appState.jobsLoadError,
              ),
              const SizedBox(height: 16),
              JobsSection(
                appState: appState,
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
                onStartInspection: (job) {
                  _handleStartInspection(
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
      ),
    );
  }
}
