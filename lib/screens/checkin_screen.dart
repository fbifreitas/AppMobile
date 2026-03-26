import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/checkin_step2_screen.dart';
import '../screens/overlay_camera_screen.dart';
import '../services/location_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  bool? clientePresente;
  String? tipoImovel;
  String? subtipoImovel;
  String? porOndeComecar;

  final List<String> tipos = const ['Urbano', 'Rural', 'Comercial', 'Industrial'];

  final Map<String, List<String>> subtiposPorTipo = const {
    'Urbano': ['Apartamento', 'Casa', 'Sobrado', 'Terreno'],
    'Rural': ['Sítio', 'Chácara', 'Fazenda'],
    'Comercial': ['Loja', 'Sala comercial', 'Galpão'],
    'Industrial': ['Fábrica', 'Armazém', 'Planta industrial'],
  };

  final List<String> contextos = const ['Rua', 'Área externa', 'Área interna'];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final job = appState.jobAtual;

    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-in Vistoria')),
        body: const Center(child: Text('Nenhum job selecionado')),
      );
    }

    final subtipos = tipoImovel == null ? const <String>[] : (subtiposPorTipo[tipoImovel] ?? const <String>[]);

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Vistoria')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            Text(
              job.titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              job.endereco,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: LocationService().getCurrentLocation(),
              builder: (context, snapshot) {
                String texto = 'Validando GPS...';
                Color cor = AppColors.warning;
                Color fundo = AppColors.warningLight;

                if (snapshot.hasData && job.latitude != null && job.longitude != null) {
                  final pos = snapshot.data!;
                  final distancia = LocationService().calcularDistancia(
                    lat1: pos.latitude,
                    lon1: pos.longitude,
                    lat2: job.latitude!,
                    lon2: job.longitude!,
                  );
                  if (distancia <= 100) {
                    texto = 'GPS confirmado no local';
                    cor = AppColors.success;
                    fundo = AppColors.successLight;
                  } else {
                    texto = 'Você ainda não está no raio do local (${distancia.toStringAsFixed(0)}m)';
                    cor = AppColors.danger;
                    fundo = AppColors.dangerLight;
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: fundo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: cor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          texto,
                          style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirWhatsApp(job.telefoneCliente),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _ligar(job.telefoneCliente),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Ligar', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Cliente está presente?',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Sim'),
                  selected: clientePresente == true,
                  onSelected: (_) => setState(() => clientePresente = true),
                ),
                ChoiceChip(
                  label: const Text('Não'),
                  selected: clientePresente == false,
                  onSelected: (_) => setState(() => clientePresente = false),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (clientePresente == true) ...[
              const Text(
                'Tipo de imóvel',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tipos.map((tipo) {
                  return ChoiceChip(
                    label: Text(tipo),
                    selected: tipoImovel == tipo,
                    onSelected: (_) {
                      setState(() {
                        tipoImovel = tipo;
                        subtipoImovel = null;
                      });
                    },
                  );
                }).toList(),
              ),
              if (tipoImovel != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Subtipo',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subtipos.map((subtipo) {
                    return ChoiceChip(
                      label: Text(subtipo),
                      selected: subtipoImovel == subtipo,
                      onSelected: (_) => setState(() => subtipoImovel = subtipo),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Por onde deseja começar?',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: contextos.map((ctx) {
                  return ChoiceChip(
                    label: Text(ctx),
                    selected: porOndeComecar == ctx,
                    onSelected: (_) => setState(() => porOndeComecar = ctx),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: tipoImovel == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckinStep2Screen(
                                tipoImovel: tipoImovel!,
                              ),
                            ),
                          );
                        },
                  child: const Text('Ir para etapa 2 do check-in', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleConfirm,
                child: const Text('Confirmar e abrir a câmera', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    if (clientePresente != true || tipoImovel == null || subtipoImovel == null || porOndeComecar == null) {
      _mostrarInfo('Preencha presença, tipo, subtipo e por onde deseja começar.');
      return;
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OverlayCameraScreen(
          title: 'COLETA',
          tipoImovel: tipoImovel!,
          subtipoImovel: subtipoImovel!,
          preselectedMacroLocal: porOndeComecar,
          cameFromCheckinStep1: true,
        ),
      ),
    );
  }

  Future<void> _abrirWhatsApp(String? telefone) async {
    if (telefone == null || telefone.isEmpty) return;
    final somenteNumeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/55$somenteNumeros');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _ligar(String? telefone) async {
    if (telefone == null || telefone.isEmpty) return;
    final uri = Uri.parse('tel:$telefone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _mostrarInfo(String msg) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atenção'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}