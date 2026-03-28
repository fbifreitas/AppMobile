import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'checkin_screen.dart';
import 'notifications_screen.dart';
import 'operational_hub_screen.dart';
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
    if (mounted) setState(() => _loadingLocation = true);
    final appState = context.read<AppState>();
    try {
      final pos = await _locationService.getCurrentLocation();
      appState.atualizarUltimaLocalizacao(pos.latitude, pos.longitude);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
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
        items: const [
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
                  padding: const EdgeInsets.all(18),
                  children: [
                    _buildHeader(context, appState),
                    const SizedBox(height: 16),
                    _buildOperationalHubEntry(context),
                    const SizedBox(height: 16),
                    const Text('MEUS JOBS DE HOJE', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...jobs.map((job) => _jobCard(context, appState, job)),
                    const SizedBox(height: 14),
                    const Text('NOVAS PROPOSTAS', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 12)),
                    const SizedBox(height: 8),
                    ..._buildProposalCards(),
                    if (_loadingLocation)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Center(child: Text('Atualizando localização...', style: TextStyle(color: AppColors.textSecondary, fontSize: 10))),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState appState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(radius: 21, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3')),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá, ${appState.primeiroNome}! 👋', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 1),
              const Text('Seu painel operacional de hoje', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _circleIconButton(
              icon: Icons.notifications_none,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
              badge: '3',
            ),
            const SizedBox(width: 8),
            _circleIconButton(
              icon: Icons.settings_outlined,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                if (!context.mounted) return;
                await _refreshUserLocation();
              },
            ),
            const SizedBox(width: 8),
            _circleIconButton(
              icon: Icons.dashboard_customize_outlined,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationalHubScreen()));
              },
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildProposalCards() {
    final propostas = const [
      {'valor': 'R\$ 150,00', 'resumo': '2.5 km • Apto padrão', 'tempo': '00:45'},
      {'valor': 'R\$ 220,00', 'resumo': '4.1 km • Casa', 'tempo': '01:10'},
    ];

    return propostas.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item['valor']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ),
                Text(item['resumo']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 2),
            Text('Expira em ${item['tempo']}', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 10)),
            const SizedBox(height: 8),
            Container(
              height: 40,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(width: 42, margin: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12))),
                  const Expanded(
                    child: Center(
                      child: Text('DESLIZE PARA ACEITAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
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


  Widget _buildOperationalHubEntry(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_customize_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centrais integradas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Acesse fluxo, operação, IA, qualidade, observabilidade e produção em um único ponto.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OperationalHubScreen()),
              );
            },
            child: const Text('ABRIR'),
          ),
        ],
      ),
    );
  }

  Widget _jobCard(BuildContext context, AppState appState, Job job) {
    final distanciaMetros = _distanceToJob(appState, job);
    final podeIniciar = distanciaMetros == null ? appState.permitirIniciarLonge : appState.podeIniciarVistoria(distanciaMetros);
    final distanciaTexto = _distanceLabel(distanciaMetros);
    final proximidadeTexto = _proximityLabel(distanciaMetros);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('EM ANDAMENTO', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(job.titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.05)),
          const SizedBox(height: 5),
          Text(job.endereco, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5, height: 1.05)),
          const SizedBox(height: 1),
          Text(job.nomeCliente, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5, height: 1.05)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tag(AppColors.primaryLight, AppColors.primary, distanciaTexto),
              _tag(AppColors.warningLight, AppColors.warning, '14:30 (Em 15 min)'),
              if (proximidadeTexto != null)
                _tag(
                  podeIniciar ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.10),
                  podeIniciar ? Colors.green.shade800 : Colors.red.shade700,
                  proximidadeTexto,
                ),
            ],
          ),
          const SizedBox(height: 8),
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
                  child: const Text('COMO CHEGAR', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (!podeIniciar) {
                      _mostrarInfo(context, 'Você precisa estar próximo do local da vistoria.');
                      return;
                    }

                    appState.selecionarJob(job);
                    if (appState.ultimaLatitude != null && appState.ultimaLongitude != null) {
                      appState.registrarDeslocamento(
                        atualLat: appState.ultimaLatitude!,
                        atualLng: appState.ultimaLongitude!,
                      );
                    }

                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckinScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: podeIniciar ? AppColors.primary : Colors.grey.shade400,
                  ),
                  child: Text(
                    appState.permitirIniciarLonge ? 'INICIAR (DEV)' : 'INICIAR VISTORIA',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(Color bg, Color fg, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 10.5)),
    );
  }

  double? _distanceToJob(AppState appState, Job job) {
    if (appState.ultimaLatitude == null || appState.ultimaLongitude == null || job.latitude == null || job.longitude == null) {
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
    if (distanceMeters <= 80) return 'Você está no local';
    if (distanceMeters < 1000) return '${distanceMeters.toStringAsFixed(0)} m de distância';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km de distância';
  }

  String? _proximityLabel(double? distanceMeters) {
    if (distanceMeters == null) return null;
    return distanceMeters <= 100 ? 'Dentro do raio' : 'Fora do raio';
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}