import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/checkin_step2_model.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../services/location_service.dart';
import '../services/voice_input_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/voice_selector_sheet.dart';

class CheckinScreen extends StatefulWidget {
  final InspectionFlowCoordinator flowCoordinator;

  const CheckinScreen({
    super.key,
    this.flowCoordinator = const DefaultInspectionFlowCoordinator(),
  });

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  bool? clientePresente;
  String? tipoImovel;
  String? subtipoImovel;
  String? porOndeComecar;

  static const List<String> _defaultTipos = <String>[
    'Urbano',
    'Rural',
    'Comercial',
    'Industrial',
  ];

  static const Map<String, List<String>> _defaultSubtiposPorTipo = {
    'Urbano': ['Apartamento', 'Casa', 'Sobrado', 'Terreno'],
    'Rural': ['Sítio', 'Chácara', 'Fazenda'],
    'Comercial': ['Loja', 'Sala comercial', 'Galpão'],
    'Industrial': ['Fábrica', 'Armazém', 'Planta industrial'],
  };

  static const List<String> _defaultContextos = <String>[
    'Rua',
    'Área externa',
    'Área interna',
  ];

  final CheckinDynamicConfigService _dynamicConfigService =
      CheckinDynamicConfigService.instance;

  List<String> _tipos = List<String>.from(_defaultTipos);
  Map<String, List<String>> _subtiposPorTipo =
      Map<String, List<String>>.fromEntries(
        _defaultSubtiposPorTipo.entries.map(
          (entry) => MapEntry(entry.key, List<String>.from(entry.value)),
        ),
      );
  List<String> _contextos = List<String>.from(_defaultContextos);

  final VoiceInputService _voiceService = VoiceInputService();
  bool _hydrated = false;
  bool _loadingDynamicConfig = false;

  @override
  void initState() {
    super.initState();
    _loadDynamicStep1Config();
  }

  Future<void> _loadDynamicStep1Config() async {
    setState(() => _loadingDynamicConfig = true);
    final dynamicConfig = await _dynamicConfigService.loadStep1Config(
      fallbackTipos: _defaultTipos,
      fallbackSubtiposPorTipo: _defaultSubtiposPorTipo,
      fallbackContextos: _defaultContextos,
    );
    if (!mounted) return;

    setState(() {
      _tipos = dynamicConfig.tipos;
      _subtiposPorTipo = dynamicConfig.subtiposPorTipo;
      _contextos = dynamicConfig.contextos;

      if (tipoImovel != null && !_tipos.contains(tipoImovel)) {
        tipoImovel = null;
        subtipoImovel = null;
      }

      final allowedSubtipos =
          tipoImovel == null
              ? const <String>[]
              : (_subtiposPorTipo[tipoImovel] ?? const <String>[]);
      if (subtipoImovel != null && !allowedSubtipos.contains(subtipoImovel)) {
        subtipoImovel = null;
      }

      if (porOndeComecar != null && !_contextos.contains(porOndeComecar)) {
        porOndeComecar = null;
      }

      _loadingDynamicConfig = false;
    });

    await _persistStep1();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  void _hydrateFromDraft(AppState appState) {
    if (_hydrated) return;
    _hydrated = true;

    final payload = appState.step1Payload;
    if (payload.isEmpty) return;

    clientePresente = payload['clientePresente'] as bool?;
    tipoImovel = payload['tipoImovel'] as String?;
    subtipoImovel = payload['subtipoImovel'] as String?;
    porOndeComecar = payload['porOndeComecar'] as String?;
  }

  Future<void> _persistStep1() async {
    final appState = context.read<AppState>();
    await appState.persistStep1Draft(
      clientePresente: clientePresente,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      porOndeComecar: porOndeComecar,
    );
  }

  CheckinStep2Model? _readInitialStep2(AppState appState) {
    final payload = appState.step2Payload;
    if (payload.isEmpty) return null;
    try {
      return CheckinStep2Model.fromMap(payload);
    } catch (_) {
      return null;
    }
  }

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

    _hydrateFromDraft(appState);

    final subtipos =
        tipoImovel == null
            ? const <String>[]
            : (_subtiposPorTipo[tipoImovel] ?? const <String>[]);

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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: LocationService().getCurrentLocation(),
              builder: (context, snapshot) {
                String texto = 'Validando GPS...';
                Color cor = AppColors.warning;
                Color fundo = AppColors.warningLight;

                if (snapshot.hasData &&
                    job.latitude != null &&
                    job.longitude != null) {
                  final pos = snapshot.data!;
                  final distancia = LocationService().calcularDistancia(
                    lat1: pos.latitude,
                    lon1: pos.longitude,
                    lat2: job.latitude!,
                    lon2: job.longitude!,
                  );

                  final raio = appState.resolveInspectionRadiusMeters(job);

                  if (distancia <= raio) {
                    texto = 'GPS confirmado no local';
                    cor = AppColors.success;
                    fundo = AppColors.successLight;
                  } else {
                    texto =
                        'Você ainda não está no raio do local (${distancia.toStringAsFixed(0)}m de ${raio.toStringAsFixed(0)}m)';
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
                          style: TextStyle(
                            color: cor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
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
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(fontSize: 13),
                    ),
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
            _buildSectionTitle(
              label: 'Cliente está presente?',
              onVoiceTap: _selectClientePresenteByVoice,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Sim'),
                  selected: clientePresente == true,
                  onSelected: (_) async {
                    setState(() => clientePresente = true);
                    await _persistStep1();
                  },
                ),
                ChoiceChip(
                  label: const Text('Não'),
                  selected: clientePresente == false,
                  onSelected: (_) async {
                    setState(() => clientePresente = false);
                    await _persistStep1();
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (clientePresente == true) ...[
              _buildSectionTitle(
                label: 'Tipo de imóvel',
                onVoiceTap: _selectTipoByVoice,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _tipos.map((tipo) {
                      return ChoiceChip(
                        label: Text(tipo),
                        selected: tipoImovel == tipo,
                        onSelected: (_) async {
                          setState(() {
                            tipoImovel = tipo;
                            subtipoImovel = null;
                          });
                          await _persistStep1();
                        },
                      );
                    }).toList(),
              ),
              if (tipoImovel != null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle(
                  label: 'Subtipo',
                  onVoiceTap: _selectSubtipoByVoice,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      subtipos.map((subtipo) {
                        return ChoiceChip(
                          label: Text(subtipo),
                          selected: subtipoImovel == subtipo,
                          onSelected: (_) async {
                            setState(() => subtipoImovel = subtipo);
                            await _persistStep1();
                          },
                        );
                      }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              _buildSectionTitle(
                label: 'Por onde deseja começar?',
                onVoiceTap: _selectContextoByVoice,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _contextos.map((ctx) {
                      return ChoiceChip(
                        label: Text(ctx),
                        selected: porOndeComecar == ctx,
                        onSelected: (_) async {
                          setState(() => porOndeComecar = ctx);
                          await _persistStep1();
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      tipoImovel == null
                          ? null
                          : () async {
                            final appStateRead = context.read<AppState>();
                            final flowCoordinator = widget.flowCoordinator;

                            await appStateRead.setInspectionRecoveryStage(
                              stageKey: 'checkin_step2',
                              stageLabel: 'Check-in etapa 2',
                              routeName: '/checkin_step2',
                              payload: {
                                ...appStateRead.inspectionRecoveryPayload,
                                'step1': appStateRead.step1Payload,
                                'step2': appStateRead.step2Payload,
                              },
                            );

                            if (!context.mounted) return;

                            flowCoordinator.openCheckinStep2(
                              context,
                              tipoImovel: tipoImovel!,
                              initialData: _readInitialStep2(appStateRead),
                              onContinue: (model) async {
                                await context
                                    .read<AppState>()
                                    .persistStep2Draft(model.toMap());
                              },
                            );
                          },
                  child: const Text(
                    'Ir para etapa 2 do check-in',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadingDynamicConfig ? null : _handleConfirm,
                child: const Text(
                  'Confirmar e abrir a câmera',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String label,
    required Future<void> Function() onVoiceTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Selecionar por voz',
          onPressed: onVoiceTap,
          icon: const Icon(Icons.mic_none, size: 18),
        ),
      ],
    );
  }

  Future<void> _selectClientePresenteByVoice() async {
    final selected = await VoiceSelectorSheet.open(
      context,
      voiceService: _voiceService,
      options: const ['Sim', 'Não'],
      title: 'Cliente está presente?',
      currentValue:
          clientePresente == null ? null : (clientePresente! ? 'Sim' : 'Não'),
    );
    if (selected == null || !mounted) return;
    setState(() => clientePresente = selected == 'Sim');
    await _persistStep1();
  }

  Future<void> _selectTipoByVoice() async {
    final selected = await VoiceSelectorSheet.open(
      context,
      voiceService: _voiceService,
      options: _tipos,
      title: 'Tipo de imóvel',
      currentValue: tipoImovel,
    );
    if (selected == null || !mounted) return;
    setState(() {
      tipoImovel = selected;
      subtipoImovel = null;
    });
    await _persistStep1();
  }

  Future<void> _selectSubtipoByVoice() async {
    final subtipos =
        tipoImovel == null
            ? const <String>[]
            : (_subtiposPorTipo[tipoImovel] ?? const <String>[]);
    if (subtipos.isEmpty) {
      _mostrarInfo('Selecione o tipo de imóvel antes do subtipo.');
      return;
    }

    final selected = await VoiceSelectorSheet.open(
      context,
      voiceService: _voiceService,
      options: subtipos,
      title: 'Subtipo',
      currentValue: subtipoImovel,
    );
    if (selected == null || !mounted) return;
    setState(() => subtipoImovel = selected);
    await _persistStep1();
  }

  Future<void> _selectContextoByVoice() async {
    final selected = await VoiceSelectorSheet.open(
      context,
      voiceService: _voiceService,
      options: _contextos,
      title: 'Por onde deseja começar?',
      currentValue: porOndeComecar,
    );
    if (selected == null || !mounted) return;
    setState(() => porOndeComecar = selected);
    await _persistStep1();
  }

  Future<void> _handleConfirm() async {
    if (clientePresente != true ||
        tipoImovel == null ||
        subtipoImovel == null ||
        porOndeComecar == null) {
      _mostrarInfo(
        'Preencha presença, tipo, subtipo e por onde deseja começar.',
      );
      return;
    }

    await _persistStep1();

    if (!mounted) return;
    await widget.flowCoordinator.openOverlayCamera(
      context,
      title: 'COLETA',
      tipoImovel: tipoImovel!,
      subtipoImovel: subtipoImovel!,
      preselectedMacroLocal: porOndeComecar,
      cameFromCheckinStep1: true,
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
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
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
