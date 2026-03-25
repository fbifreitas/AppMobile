import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/job.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import 'checkin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    /// 📦 JOB MOCK (fixo por enquanto)
    final jobMock = Job(
      id: '1',
      endereco: 'Al. dos Pássaros, 100',
      latitude: -23.5505,
      longitude: -46.6333,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      bottomNavigationBar: BottomNavigationBar(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 👤 HEADER
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

              /// 📦 CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Casa em Condomínio - Res. Tamboré',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(jobMock.endereco,
                        style: const TextStyle(color: Colors.grey)),

                    const SizedBox(height: 10),

                    /// 📍 DISTÂNCIA + BLOQUEIO
                   FutureBuilder(
  future: LocationService().getCurrentLocation(),
  builder: (context, snapshot) {

    /// ⏳ carregando
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    /// ❌ erro (isso evita tela preta!)
    if (snapshot.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Erro ao obter localização',
            style: TextStyle(color: Colors.red),
          ),
          SizedBox(height: 10),
          Text('Verifique GPS ou permissões'),
        ],
      );
    }

    /// 🚫 sem dados
    if (!snapshot.hasData) {
      return const Text('Sem localização disponível');
    }

    final pos = snapshot.data!;
    final locationService = LocationService();

    final job = Job(
      id: '1',
      endereco: 'Al. dos Pássaros, 100',
      latitude: -23.5505,
      longitude: -46.6333,
    );

    final distancia = locationService.calcularDistancia(
      lat1: pos.latitude,
      lon1: pos.longitude,
      lat2: job.latitude!,
      lon2: job.longitude!,
    );

    final appState = Provider.of<AppState>(context, listen: false);
    final podeIniciar = appState.podeIniciarVistoria(distancia);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📍 ${(distancia / 1000).toStringAsFixed(1)} km de distância',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            /// 🗺️ COMO CHEGAR
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final mapService = MapService();

                  await mapService.abrirWaze(
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

            /// 🚀 INICIAR
            Expanded(
              child: GestureDetector(
                onTap: podeIniciar
                    ? () {
                        appState.iniciarJob(job);

                        appState.registrarDeslocamento(
                          atualLat: pos.latitude,
                          atualLng: pos.longitude,
                        );

                        appState.atualizarUltimaLocalizacao(
                          pos.latitude,
                          pos.longitude,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckinScreen(),
                          ),
                        );
                      }
                    : () {
                        _mostrarErro(
                          context,
                          'Você precisa estar próximo do local',
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: podeIniciar
                        ? const Color(0xFF0D3B92)
                        : Colors.grey,
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
      ],
    );
  },
)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoDesabilitado() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'Aguardando...',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _mostrarErro(BuildContext context, String msg) {
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