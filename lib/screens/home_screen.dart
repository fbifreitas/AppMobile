import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../branding/brand_provider.dart';
import '../branding/brand_tokens.dart';
import '../l10n/app_strings.dart';
import '../models/home_location_snapshot.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../models/proposal_offer.dart';
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
      SnackBar(
        content: Text(
          AppStrings.of(context).tr(
            'Foto de perfil atualizada.',
            'Profile photo updated.',
          ),
        ),
      ),
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
    final strings = AppStrings.of(context);
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
            ),
            const SizedBox(height: 16),
            JobsSection(
              appState: appState,
              currentLatitude:
                  appState.ultimaLatitude ?? _locationSnapshot.latitude,
              currentLongitude:
                  appState.ultimaLongitude ?? _locationSnapshot.longitude,
              useDistanceMetrics: true,
              sectionTitle: strings.branded(
                config,
                key: 'jobs_section_title',
                portuguese: 'MEUS JOBS DE HOJE',
                english: 'MY JOBS TODAY',
              ),
              geofenceRequired: flags.geofenceRequired,
              startLabel: strings.branded(
                config,
                key: 'job_start_label',
                portuguese: 'INICIAR VISTORIA',
                english: 'START INSPECTION',
              ),
              resumeLabel: strings.branded(
                config,
                key: 'job_resume_label',
                portuguese: 'RETOMAR VISTORIA',
                english: 'RESUME INSPECTION',
              ),
              startBlockedLabel: strings.branded(
                config,
                key: 'job_start_blocked_label',
                portuguese: 'Fora do raio de vistoria.',
                english: 'Outside the inspection radius.',
              ),
              navigateLabel: strings.branded(
                config,
                key: 'job_navigate_label',
                portuguese: 'COMO CHEGAR',
                english: 'DIRECTIONS',
              ),
              withinRangeLabel: strings.branded(
                config,
                key: 'job_within_range_label',
                portuguese: 'Dentro do raio',
                english: 'Within radius',
              ),
              outOfRangeLabel: strings.branded(
                config,
                key: 'job_out_of_range_label',
                portuguese: 'Fora do raio',
                english: 'Outside radius',
              ),
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
                sectionTitle: strings.branded(
                  config,
                  key: 'proposals_section_title',
                  portuguese: 'NOVAS PROPOSTAS',
                  english: 'NEW PROPOSALS',
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
            label: strings.branded(
              config,
              key: 'nav_home_label',
              portuguese: 'Painel',
              english: 'Dashboard',
            ),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: strings.branded(
              config,
              key: 'nav_jobs_label',
              portuguese: 'Vistorias',
              english: 'Inspections',
            ),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: strings.branded(
              config,
              key: 'nav_agenda_label',
              portuguese: 'Agenda',
              english: 'Schedule',
            ),
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
        ? AppStrings.of(context).tr('Usuario', 'User')
        : fallbackName.trim().split(RegExp(r'\s+')).first;
  }
}

class ProposalsSection extends StatefulWidget {
  const ProposalsSection({
    super.key,
    this.propostas,
    this.onAcceptProposal,
    this.sectionTitle,
    this.swipeRequired = true,
    this.financialSummaryEnabled = true,
  });

  final List<ProposalOffer>? propostas;
  final ValueChanged<ProposalOffer>? onAcceptProposal;
  final String? sectionTitle;
  final bool swipeRequired;
  final bool financialSummaryEnabled;

  static final List<ProposalOffer> _mockPropostas = [
    ProposalOffer(
      id: 'prop-001',
      valor: 'R\$ 150,00',
      expiraEm: const Duration(minutes: 45),
      distanciaKm: 2.5,
      endereco: 'Rua Serra de Braganca, 123 - Tatuape, Sao Paulo/SP',
      proprietario: 'Fabio Freitas',
      dataHoraAgendamento: DateTime(2026, 3, 28, 14, 30),
      tipoImovel: 'Urbano',
      subtipoImovel: 'Apartamento',
    ),
    ProposalOffer(
      id: 'prop-002',
      valor: 'R\$ 220,00',
      expiraEm: const Duration(hours: 1, minutes: 10),
      distanciaKm: 4.1,
      endereco: 'Av. Paes de Barros, 980 - Mooca, Sao Paulo/SP',
      proprietario: 'Maria Souza',
      dataHoraAgendamento: DateTime(2026, 3, 28, 16, 0),
      tipoImovel: 'Urbano',
      subtipoImovel: 'Casa',
    ),
  ];

  @override
  State<ProposalsSection> createState() => _ProposalsSectionState();
}

class _ProposalsSectionState extends State<ProposalsSection> {
  late List<ProposalOffer> _itens;

  @override
  void initState() {
    super.initState();
    _itens = List.of(widget.propostas ?? ProposalsSection._mockPropostas);
  }

  void _acceptProposal(ProposalOffer proposta) {
    final appState = Provider.of<AppState>(context, listen: false);
    final config = BrandProvider.configOf(context);
    final strings = AppStrings.of(context);

    final newJob = Job(
      id: proposta.id,
      titulo:
          'Vistoria ${proposta.subtipoImovel ?? proposta.tipoImovel ?? strings.tr('Imovel', 'Property')}',
      endereco: proposta.endereco,
      status: JobStatus.novo,
      nomeCliente: proposta.proprietario,
      tipoImovel: proposta.tipoImovel,
      subtipoImovel: proposta.subtipoImovel,
    );

    setState(() {
      _itens.removeWhere((p) => p.id == proposta.id);
    });

    appState.adicionarJob(newJob);
    widget.onAcceptProposal?.call(proposta);

    final snackbarText = strings.branded(
      config,
      key: 'proposal_snackbar_accept_success',
      portuguese: 'Proposta aceita! Job adicionado ao seu dia.',
      english: 'Proposal accepted! Job added to your day.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(snackbarText)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = BrandProvider.configOf(context);
    final tokens = config.tokens;
    final strings = AppStrings.of(context);

    final resolvedTitle =
        widget.sectionTitle?.isNotEmpty == true
            ? widget.sectionTitle!
            : strings.branded(
                config,
                key: 'proposals_section_title',
                portuguese: 'NOVAS PROPOSTAS',
                english: 'NEW PROPOSALS',
              );

    final swipeLabel = strings.branded(
      config,
      key: 'proposal_swipe_label',
      portuguese: 'DESLIZE PARA ACEITAR',
      english: 'SWIPE TO ACCEPT',
    );
    final acceptLabel = strings.branded(
      config,
      key: 'proposal_accept_label',
      portuguese: 'ACEITAR PROPOSTA',
      english: 'ACCEPT PROPOSAL',
    );
    final emptyLabel = strings.branded(
      config,
      key: 'proposal_empty_title',
      portuguese: 'Nenhuma proposta disponivel no momento.',
      english: 'No proposal available right now.',
    );
    final expirationPrefix = strings.branded(
      config,
      key: 'proposal_expiration_prefix',
      portuguese: 'Expira em',
      english: 'Expires in',
    );
    final addressLabel = strings.branded(
      config,
      key: 'proposal_address_label',
      portuguese: 'Endereço',
      english: 'Address',
    );
    final ownerLabel = strings.branded(
      config,
      key: 'proposal_owner_label',
      portuguese: 'Proprietário',
      english: 'Owner',
    );
    final scheduleLabel = strings.branded(
      config,
      key: 'proposal_schedule_label',
      portuguese: 'Agendamento',
      english: 'Schedule',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          resolvedTitle,
          style: const TextStyle(
            color: BrandTokens.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        if (_itens.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BrandTokens.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BrandTokens.border),
            ),
            child: Text(
              emptyLabel,
              style: const TextStyle(
                color: BrandTokens.textSecondary,
                fontSize: 12,
              ),
            ),
          )
        else
          ..._itens.map(
            (item) => _ProposalCard(
              key: ValueKey(item.id),
              proposta: item,
              tokens: tokens,
              swipeRequired: widget.swipeRequired,
              financialSummaryEnabled: widget.financialSummaryEnabled,
              swipeLabel: swipeLabel,
              acceptLabel: acceptLabel,
              expirationPrefix: expirationPrefix,
              addressLabel: addressLabel,
              ownerLabel: ownerLabel,
              scheduleLabel: scheduleLabel,
              onAccept: () => _acceptProposal(item),
            ),
          ),
      ],
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    super.key,
    required this.proposta,
    required this.tokens,
    required this.onAccept,
    required this.swipeRequired,
    required this.financialSummaryEnabled,
    required this.swipeLabel,
    required this.acceptLabel,
    required this.expirationPrefix,
    required this.addressLabel,
    required this.ownerLabel,
    required this.scheduleLabel,
  });

  final ProposalOffer proposta;
  final BrandTokens tokens;
  final VoidCallback onAccept;
  final bool swipeRequired;
  final bool financialSummaryEnabled;
  final String swipeLabel;
  final String acceptLabel;
  final String expirationPrefix;
  final String addressLabel;
  final String ownerLabel;
  final String scheduleLabel;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: BrandTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                if (financialSummaryEnabled)
                  Expanded(
                    child: Text(
                      proposta.valor,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BrandTokens.textPrimary,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: BrandTokens.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$expirationPrefix ${_formatDuration(proposta.expiraEm)}',
                    style: const TextStyle(
                      color: BrandTokens.warning,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _InfoTag(text: 'ID: ${proposta.id}', tokens: tokens),
                _InfoTag(
                  text: strings.tr(
                    '${proposta.distanciaKm.toStringAsFixed(1)} km de distância',
                    '${proposta.distanciaKm.toStringAsFixed(1)} km away',
                  ),
                  tokens: tokens,
                ),
                if (proposta.tipoImovel != null)
                  _InfoTag(
                    text: proposta.subtipoImovel == null
                        ? proposta.tipoImovel!
                        : '${proposta.tipoImovel} • ${proposta.subtipoImovel}',
                    tokens: tokens,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: addressLabel, value: proposta.endereco),
                const SizedBox(height: 6),
                _InfoRow(label: ownerLabel, value: proposta.proprietario),
                const SizedBox(height: 6),
                _InfoRow(
                  label: scheduleLabel,
                  value: _formatDateTime(context, proposta.dataHoraAgendamento),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (swipeRequired)
            _SwipeToAccept(
              onAccept: onAccept,
              tokens: tokens,
              swipeLabel: swipeLabel,
              acceptBgLabel: acceptLabel,
            )
          else
            _AcceptButton(
              onAccept: onAccept,
              tokens: tokens,
              label: acceptLabel,
            ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String _formatDateTime(BuildContext context, DateTime value) {
    final strings = AppStrings.of(context);
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return strings.tr('$dd/$mm/$yyyy as $hh:$min', '$dd/$mm/$yyyy at $hh:$min');
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.text, required this.tokens});

  final String text;
  final BrandTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tokens.primary,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: BrandTokens.textSecondary, fontSize: 11.5),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: BrandTokens.textPrimary,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _SwipeToAccept extends StatelessWidget {
  const _SwipeToAccept({
    required this.onAccept,
    required this.tokens,
    required this.swipeLabel,
    required this.acceptBgLabel,
  });

  final VoidCallback onAccept;
  final BrandTokens tokens;
  final String swipeLabel;
  final String acceptBgLabel;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onAccept(),
      background: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: tokens.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.swipe_right_alt, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              acceptBgLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: BrandTokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrandTokens.border),
        ),
        child: Row(
          children: [
            Icon(Icons.swipe_right_alt, color: tokens.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                swipeLabel,
                style: TextStyle(
                  color: tokens.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({
    required this.onAccept,
    required this.tokens,
    required this.label,
  });

  final VoidCallback onAccept;
  final BrandTokens tokens;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }
}
