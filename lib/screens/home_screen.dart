import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'checkin_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshUserLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUserLocation();
    }
  }

  Future<void> _refreshUserLocation() async {
    if (mounted) {
      setState(() => _loadingLocation = true);
    }

    final appState = context.read<AppState>();
    try {
      final pos = await _locationService.getCurrentLocation();
      appState.atualizarUltimaLocalizacao(pos.latitude, pos.longitude);
    } catch (_) {
      // Mantém a home funcional mesmo sem GPS.
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _manualRefresh() async {
    await _refreshUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final jobs = appState.jobs;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Painel'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Vistorias'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Agenda'),
        ],
      ),
      body: SafeArea(
        child: jobs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _manualRefresh,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    const Text(
                      'MEUS JOBS DE HOJE',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...jobs.map((job) => _jobCard(context, appState, job)),
                    const SizedBox(height: 20),
                    const Text(
                      'NOVAS PROPOSTAS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildProposalCards(),
                    if (_loadingLocation) ...[
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Atualizando localização...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Olá, Fábio Freitas! 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Seu painel operacional de hoje',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _circleIconButton(
              icon: Icons.notifications_none,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
              badge: '3',
            ),
            const SizedBox(width: 8),
            _circleIconButton(
              icon: Icons.settings_outlined,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                if (!context.mounted) return;
                await _refreshUserLocation();
              },
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildProposalCards() {
    final propostas = const [
      {
        'valor': 'R\$ 150,00',
        'resumo': '2.5 km • Apto padrão',
        'tempo': '00:45',
      },
      {
        'valor': 'R\$ 220,00',
        'resumo': '4.1 km • Casa',
        'tempo': '01:10',
      },
    ];

    return propostas.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['valor']!,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  item['resumo']!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Expira em ${item['tempo']}',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'DESLIZE PARA ACEITAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _jobCard(BuildContext context, AppState appState, Job job) {
    final distanciaMetros = _distanceToJob(appState, job);
    final podeIniciar = distanciaMetros == null
        ? appState.permitirIniciarLonge
        : appState.podeIniciarVistoria(distanciaMetros);
    final distanciaTexto = _distanceLabel(distanciaMetros);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'EM ANDAMENTO',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            job.titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job.endereco,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            job.nomeCliente,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  distanciaTexto,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '14:30 (Em 15 min)',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    if (job.latitude == null || job.longitude == null) {
                      _mostrarInfo(context, 'Localização do job não definida.');
                      return;
                    }
                    await MapService().abrirWaze(job.latitude!, job.longitude!);
                  },
                  child: const Text(
                    'COMO CHEGAR',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (!podeIniciar) {
                      _mostrarInfo(
                        context,
                        'Você precisa estar próximo do local da vistoria.',
                      );
                      return;
                    }

                    appState.selecionarJob(job);

                    if (appState.ultimaLatitude != null &&
                        appState.ultimaLongitude != null) {
                      appState.registrarDeslocamento(
                        atualLat: appState.ultimaLatitude!,
                        atualLng: appState.ultimaLongitude!,
                      );
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckinScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        podeIniciar ? AppColors.primary : Colors.grey.shade400,
                  ),
                  child: Text(
                    appState.permitirIniciarLonge
                        ? 'INICIAR (DEV)'
                        : 'INICIAR VISTORIA',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          if (!appState.permitirIniciarLonge &&
              distanciaMetros != null &&
              !podeIniciar) ...[
            const SizedBox(height: 10),
            Text(
              'Aproxime-se do local para iniciar a vistoria. Distância atual: ${distanciaMetros.toStringAsFixed(0)}m',
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double? _distanceToJob(AppState appState, Job job) {
    if (appState.ultimaLatitude == null ||
        appState.ultimaLongitude == null ||
        job.latitude == null ||
        job.longitude == null) {
      return null;
    }

    return _locationService.calcularDistancia(
      lat1: appState.ultimaLatitude!,
      lon1: appState.ultimaLongitude!,
      lat2: job.latitude!,
      lon2: job.longitude!,
    );
  }

  String _distanceLabel(double? distanceMeters) {
    if (distanceMeters == null) return 'Localização indisponível';
    if (distanceMeters <= 100) return 'Você está no local';
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m de distância';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km de distância';
    }

  static Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static void _mostrarInfo(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Atenção'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}