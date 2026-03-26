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

class _HomeScreenState extends State<HomeScreen> {
  late Future<void> _bootFuture;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _bootFuture = _refreshUserLocation();
  }

  Future<void> _refreshUserLocation() async {
    final appState = context.read<AppState>();
    try {
      final pos = await _locationService.getCurrentLocation();
      appState.atualizarUltimaLocalizacao(pos.latitude, pos.longitude);
    } catch (_) {
      // mantém a home funcional mesmo sem GPS
    }
  }

  Future<void> _manualRefresh() async {
    await _refreshUserLocation();
    if (!mounted) return;
    setState(() {
      _bootFuture = Future.value();
    });
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
        child: FutureBuilder<void>(
          future: _bootFuture,
          builder: (context, _) {
            if (jobs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: _manualRefresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 28),
                  const Text(
                    'MEUS JOBS DE HOJE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...jobs.map((job) => _jobCard(context, appState, job)),
                  const SizedBox(height: 24),
                  const Text(
                    'NOVAS PROPOSTAS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._buildProposalCards(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 25,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Seu painel operacional de hoje',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
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
        'resumo': '2.5 km • Apto Padrão',
      },
      {
        'valor': 'R\$ 220,00',
        'resumo': '4.1 km • Casa',
      },
    ];

    return propostas.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  item['resumo']!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: FutureBuilder(
        future: _locationService.getCurrentLocation(),
        builder: (context, snapshot) {
          String distanciaTexto = 'Calculando distância...';
          bool podeIniciar = appState.permitirIniciarLonge;
          double? distanciaMetros;

          if (snapshot.hasData) {
            final pos = snapshot.data!;
            distanciaMetros = _locationService.calcularDistancia(
              lat1: pos.latitude,
              lon1: pos.longitude,
              lat2: job.latitude ?? 0,
              lon2: job.longitude ?? 0,
            );
            distanciaTexto =
                '${(distanciaMetros / 1000).toStringAsFixed(1)} km de distância';
            podeIniciar = appState.podeIniciarVistoria(distanciaMetros);
          }

          return Column(
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                job.endereco,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                job.nomeCliente,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      distanciaTexto,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '14:30 (Em 15 min)',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        if (job.latitude == null || job.longitude == null) {
                          _mostrarInfo(context, 'Localização do job não definida.');
                          return;
                        }
                        await MapService().abrirWaze(
                          job.latitude!,
                          job.longitude!,
                        );
                      },
                      child: const Text('COMO CHEGAR'),
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

                        if (snapshot.hasData) {
                          final pos = snapshot.data!;
                          appState.registrarDeslocamento(
                            atualLat: pos.latitude,
                            atualLng: pos.longitude,
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
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
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