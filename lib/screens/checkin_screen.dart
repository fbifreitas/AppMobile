import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/checkin_step2_screen.dart';
import '../screens/inspection_menu_screen.dart';
import '../services/location_service.dart';
import '../state/app_state.dart';
import '../state/inspection_state.dart';
import '../theme/app_colors.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  bool? clientePresente;
  String? tipoImovel;
  bool _busy = false;

  final List<String> tipos = const [
    'Urbano',
    'Rural',
    'Comercial',
    'Industrial',
  ];

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

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Vistoria')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                job.endereco,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
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

                  if (snapshot.hasError) {
                    texto = 'Erro ao validar GPS';
                    cor = AppColors.danger;
                    fundo = AppColors.dangerLight;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: fundo,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: cor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            texto,
                            style: TextStyle(color: cor, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _abrirWhatsApp(job.telefoneCliente),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _ligar(job.telefoneCliente),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Ligar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Cliente está presente?',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Sim'),
                    selected: clientePresente == true,
                    onSelected: _busy ? null : (_) => setState(() => clientePresente = true),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Não'),
                    selected: clientePresente == false,
                    onSelected: _busy ? null : (_) => setState(() => clientePresente = false),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (clientePresente == true) ...[
                const Text(
                  'Tipo de imóvel',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: tipos.map((tipo) {
                    return ChoiceChip(
                      label: Text(tipo),
                      selected: tipoImovel == tipo,
                      onSelected: _busy ? null : (_) => setState(() => tipoImovel = tipo),
                    );
                  }).toList(),
                ),
              ],
              const Spacer(),
              if (clientePresente == true) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy || tipoImovel == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckinStep2Screen(tipoImovel: tipoImovel!),
                              ),
                            );
                          },
                    child: const Text('Ir para etapa 2 do check-in'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        clientePresente == false ? AppColors.danger : AppColors.primary,
                  ),
                  child: Text(
                    _busy
                        ? 'Abrindo...'
                        : clientePresente == false
                            ? 'Solicitar reagendamento'
                            : 'Confirmar e abrir a câmera',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    if (clientePresente == null) {
      _mostrarInfo('Selecione se o cliente está presente.');
      return;
    }

    if (clientePresente == false) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cliente ausente'),
          content: const Text('Deseja solicitar reagendamento da vistoria?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (confirmar == true) {
        final navigator = Navigator.of(context);
        context.read<AppState>().recusarJob();
        navigator.pop();
      }
      return;
    }

    if (tipoImovel == null) {
      _mostrarInfo('Selecione o tipo de imóvel.');
      return;
    }

    try {
      setState(() => _busy = true);

      context.read<AppState>().fazerCheckin(
            clientePresente: true,
            tipoImovel: tipoImovel,
          );

      await context.read<InspectionState>().startMockInspection(
            tipoImovel: tipoImovel!,
            subtipoImovel: _defaultSubtype(tipoImovel!),
          );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InspectionMenuScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarInfo('Falha ao abrir a vistoria: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _defaultSubtype(String tipo) {
    switch (tipo.trim().toLowerCase()) {
      case 'rural':
        return 'Sítio';
      case 'comercial':
        return 'Loja';
      case 'industrial':
        return 'Fábrica';
      case 'urbano':
      default:
        return 'Apartamento';
    }
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