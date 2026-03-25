import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../state/app_state.dart';
import 'checkin_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final jobs = appState.jobs;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF0D3B92),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Painel'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Vistorias'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
        ],
      ),
      body: SafeArea(
        child: jobs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=3',
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Olá, Fábio Freitas! 👋',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _iconButton(
                            context,
                            icon: Icons.notifications_none,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _iconButton(
                            context,
                            icon: Icons.settings_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'MEUS JOBS DE HOJE',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...jobs.map((job) => _jobCard(context, appState, job)),
                  const SizedBox(height: 30),
                  const Text(
                    'NOVAS PROPOSTAS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Feature ainda não implementada.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _jobCard(BuildContext context, AppState appState, Job job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: FutureBuilder(
        future: LocationService().getCurrentLocation(),
        builder: (context, snapshot) {
          String distanciaTexto = 'Calculando distância...';
          bool podeIniciar = appState.permitirIniciarLonge;
          double? distanciaMetros;

          if (snapshot.hasData) {
            final pos = snapshot.data!;
            distanciaMetros = LocationService().calcularDistancia(
              lat1: pos.latitude,
              lon1: pos.longitude,
              lat2: job.latitude ?? 0,
              lon2: job.longitude ?? 0,
            );

            distanciaTexto =
                '📍 ${(distanciaMetros / 1000).toStringAsFixed(1)} km de distância';

            podeIniciar = appState.podeIniciarVistoria(distanciaMetros);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.circle, size: 10, color: Color(0xFF0D3B92)),
                  SizedBox(width: 8),
                  Text(
                    'EM ANDAMENTO',
                    style: TextStyle(
                      color: Color(0xFF0D3B92),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                job.titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(job.endereco, style: const TextStyle(color: Colors.grey)),
              Text(
                job.nomeCliente,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                distanciaTexto,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '14:30 (Em 15 min)',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        if (job.latitude == null || job.longitude == null) {
                          _mostrarInfo(
                            context,
                            'Localização do job não definida.',
                          );
                          return;
                        }

                        await MapService().abrirWaze(
                          job.latitude!,
                          job.longitude!,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCEFE6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'COMO CHEGAR',
                            style: TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: podeIniciar
                              ? const Color(0xFF0D3B92)
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            appState.permitirIniciarLonge
                                ? 'INICIAR (DEV)'
                                : 'INICIAR VISTORIA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF0D3B92)),
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