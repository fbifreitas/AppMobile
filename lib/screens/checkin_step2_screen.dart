import 'package:flutter/material.dart';

import '../config/checkin_step2_config.dart';
import '../models/checkin_step2_model.dart';
import '../services/inspection_menu_service.dart';
import 'overlay_camera_screen.dart';

class CheckinStep2Screen extends StatefulWidget {
  final String tipoImovel;
  final CheckinStep2Model? initialData;
  final ValueChanged<CheckinStep2Model>? onContinue;

  const CheckinStep2Screen({
    super.key,
    required this.tipoImovel,
    this.initialData,
    this.onContinue,
  });

  @override
  State<CheckinStep2Screen> createState() => _CheckinStep2ScreenState();
}

class _CheckinStep2ScreenState extends State<CheckinStep2Screen> {
  late final TipoImovel _tipo;
  late final CheckinStep2Config _config;
  late CheckinStep2Model _model;
  final Map<String, TextEditingController> _obsControllers = {};
  final InspectionMenuService _menuService = InspectionMenuService.instance;

  List<CheckinStep2PhotoFieldConfig> _camposFotosOrdenados = [];

  bool _busy = false;
  bool _loadingMenus = true;
  String? _busyFieldId;

  @override
  void initState() {
    super.initState();
    _tipo = TipoImovelExtension.fromString(widget.tipoImovel);
    _config = CheckinStep2Configs.byTipo(_tipo);
    _model = widget.initialData ?? CheckinStep2Model.empty(_tipo);
    _camposFotosOrdenados = List<CheckinStep2PhotoFieldConfig>.from(_config.camposFotos);

    for (final grupo in _config.gruposOpcoes) {
      _obsControllers[grupo.id] = TextEditingController(
        text: _model.respostas[grupo.id]?.observacao ?? '',
      );
    }

    _prepareMenus();
  }

  Future<void> _prepareMenus() async {
    final ordered = await _menuService.sortPhotoFields(
      tipoImovel: _tipo,
      defaults: _config.camposFotos,
    );

    if (!mounted) return;

    setState(() {
      _camposFotosOrdenados = ordered;
      _loadingMenus = false;
    });
  }

  @override
  void dispose() {
    for (final controller in _obsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _defaultSubtype() {
    switch (widget.tipoImovel.trim().toLowerCase()) {
      case 'rural':
        return 'Sítio';
      case 'comercial':
        return 'Loja';
      case 'industrial':
        return 'Fábrica';
      default:
        return 'Apartamento';
    }
  }

  Future<void> _handleCapture(CheckinStep2PhotoFieldConfig field) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _busy = true;
        _busyFieldId = field.id;
      });

      await _menuService.registerUsage(
        scope: 'checkin_step2.${_tipo.name}.field',
        value: field.id,
      );

      final result = await navigator.push<OverlayCameraCaptureResult>(
        MaterialPageRoute(
          builder: (_) => OverlayCameraScreen(
            title: field.titulo,
            tipoImovel: widget.tipoImovel,
            subtipoImovel: _defaultSubtype(),
            singleCaptureMode: true,
            preselectedMacroLocal: field.cameraMacroLocal,
            initialAmbiente: field.cameraAmbiente,
            initialElemento: field.cameraElementoInicial,
            cameFromCheckinStep1: false,
          ),
        ),
      );

      if (!mounted || result == null) return;

      setState(() {
        _model = _model.setPhoto(
          fieldId: field.id,
          titulo: field.titulo,
          imagePath: result.filePath,
          geoPoint: result.toGeoPointData(),
          importedFromGallery: false,
        );
      });

      messenger.showSnackBar(
        SnackBar(content: Text('Foto de "${field.titulo}" capturada com sucesso.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyFieldId = null;
        });
      }
    }
  }

  Future<void> _handleContinue() async {
    widget.onContinue?.call(_model);

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OverlayCameraScreen(
          title: 'COLETA',
          tipoImovel: widget.tipoImovel,
          subtipoImovel: _defaultSubtype(),
          preselectedMacroLocal: null,
          cameFromCheckinStep1: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Vistoria')),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(theme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotosSection(theme),
                        const SizedBox(height: 20),
                        _buildDynamicOptionsSection(theme),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: (_busy || _loadingMenus) ? null : _handleContinue,
                            child: const Text(
                              'Confirmar e abrir a câmera',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_busy || _loadingMenus)
              Container(
                color: Colors.black.withValues(alpha: 0.12),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Etapa 2 da Vistoria',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_config.subtituloTela} ${_tipo.label}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Preencha as evidências externas do imóvel.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registros fotográficos',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ..._camposFotosOrdenados.map(
          (field) => _PhotoCaptureCard(
            titulo: field.titulo,
            obrigatorio: field.obrigatorio,
            capturado: _model.isPhotoCaptured(field.id),
            icon: field.icon,
            busy: _busy && _busyFieldId == field.id,
            photoInfo: _model.fotos[field.id],
            onCapture: () => _handleCapture(field),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicOptionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Infraestrutura e serviços',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ..._config.gruposOpcoes.map((grupo) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOptionGroupCard(theme, grupo),
          );
        }),
      ],
    );
  }

  Widget _buildOptionGroupCard(
    ThemeData theme,
    CheckinStep2OptionGroupConfig grupo,
  ) {
    final resposta = _model.respostas[grupo.id];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            grupo.titulo,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grupo.opcoes.map((opcao) {
              final selected = resposta?.selectedOptionIds.contains(opcao.id) ?? false;

              return grupo.multiplaEscolha
                  ? FilterChip(
                      label: Text(opcao.label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _model = _model.toggleMultiOption(
                            groupId: grupo.id,
                            optionId: opcao.id,
                          );
                        });
                      },
                    )
                  : ChoiceChip(
                      label: Text(opcao.label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _model = _model.setSingleOption(
                            groupId: grupo.id,
                            optionId: opcao.id,
                          );
                        });
                      },
                    );
            }).toList(),
          ),
          if (grupo.permiteObservacao) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _obsControllers[grupo.id],
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _model = _model.setObservacao(groupId: grupo.id, observacao: value);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoCaptureCard extends StatelessWidget {
  final String titulo;
  final bool obrigatorio;
  final bool capturado;
  final bool busy;
  final IconData icon;
  final CheckinStep2PhotoAnswer? photoInfo;
  final VoidCallback onCapture;

  const _PhotoCaptureCard({
    required this.titulo,
    required this.obrigatorio,
    required this.capturado,
    required this.busy,
    required this.icon,
    required this.photoInfo,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = capturado
        ? 'Imagem capturada'
        : obrigatorio
            ? 'Foto obrigatória'
            : 'Foto opcional';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: capturado
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.dividerColor.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: capturado
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              capturado ? Icons.check_circle_outline : icon,
              color: capturado ? theme.colorScheme.primary : theme.iconTheme.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          FilledButton(
            onPressed: busy ? null : onCapture,
            child: Text(
              capturado ? 'Refazer' : 'Capturar',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
