import 'package:flutter/material.dart';

import '../config/checkin_step2_config.dart';
import '../models/checkin_step2_model.dart';
import '../screens/overlay_camera_screen.dart';
import '../services/checkin_photo_capture_service.dart';

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
  final CheckinPhotoCaptureService _captureService = CheckinPhotoCaptureService();

  bool _busy = false;
  String? _busyFieldId;

  @override
  void initState() {
    super.initState();
    _tipo = TipoImovelExtension.fromString(widget.tipoImovel);
    _config = CheckinStep2Configs.byTipo(_tipo);
    _model = widget.initialData ?? CheckinStep2Model.empty(_tipo);

    for (final grupo in _config.gruposOpcoes) {
      _obsControllers[grupo.id] = TextEditingController(
        text: _model.respostas[grupo.id]?.observacao ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _obsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleCapture(CheckinStep2PhotoFieldConfig field) async {
    try {
      setState(() {
        _busy = true;
        _busyFieldId = field.id;
      });

      final result = await _captureService.captureFromCamera();

      if (!mounted) return;

      setState(() {
        _model = _model.setPhoto(
          fieldId: field.id,
          titulo: field.titulo,
          imagePath: result.path,
          geoPoint: result.geoPoint,
          importedFromGallery: false,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto de "${field.titulo}" capturada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao capturar foto: $e')),
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

  Future<void> _handleGallery(CheckinStep2PhotoFieldConfig field) async {
    try {
      setState(() {
        _busy = true;
        _busyFieldId = field.id;
      });

      final result = await _captureService.captureFromGallery();

      if (!mounted) return;

      setState(() {
        _model = _model.setPhoto(
          fieldId: field.id,
          titulo: field.titulo,
          imagePath: result.path,
          geoPoint: result.geoPoint,
          importedFromGallery: true,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imagem de "${field.titulo}" vinculada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao importar imagem: $e')),
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

  void _handleRemovePhoto(CheckinStep2PhotoFieldConfig field) {
    setState(() {
      _model = _model.removePhoto(field.id);
    });
  }

  Future<void> _handleContinue() async {
    widget.onContinue?.call(_model);

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OverlayCameraScreen(
          title: 'COLETA',
          ambientes: ['Fachada', 'Logradouro', 'Número', 'Entorno'],
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotosSection(theme),
                        const SizedBox(height: 24),
                        _buildDynamicOptionsSection(theme),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _busy ? null : _handleContinue,
                            child: const Text('Confirmar e abrir a câmera'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_busy)
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_config.subtituloTela} ${_tipo.label}',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Preencha as evidências fotográficas e as informações externas do imóvel.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
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
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ..._config.camposFotos.map(
          (field) => _PhotoCaptureCard(
            titulo: field.titulo,
            obrigatorio: field.obrigatorio,
            capturado: _model.isPhotoCaptured(field.id),
            icon: field.icon,
            busy: _busy && _busyFieldId == field.id,
            photoInfo: _model.fotos[field.id],
            onCapture: () => _handleCapture(field),
            onGallery: () => _handleGallery(field),
            onRemove: () => _handleRemovePhoto(field),
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
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ..._config.gruposOpcoes.map((grupo) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildOptionGroupCard(theme, grupo),
          );
        }),
      ],
    );
  }

  Widget _buildOptionGroupCard(ThemeData theme, CheckinStep2OptionGroupConfig grupo) {
    final resposta = _model.respostas[grupo.id];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            grupo.titulo,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
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
            const SizedBox(height: 14),
            TextField(
              controller: _obsControllers[grupo.id],
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Descreva detalhes relevantes deste item',
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
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const _PhotoCaptureCard({
    required this.titulo,
    required this.obrigatorio,
    required this.capturado,
    required this.busy,
    required this.icon,
    required this.photoInfo,
    required this.onCapture,
    required this.onGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final subtitle = capturado
        ? photoInfo?.importedFromGallery == true
            ? 'Imagem da galeria vinculada'
            : 'Imagem capturada'
        : obrigatorio
            ? 'Foto obrigatória'
            : 'Foto opcional';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: capturado
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.dividerColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: capturado
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  capturado ? Icons.check_circle_outline : icon,
                  color: capturado ? theme.colorScheme.primary : theme.iconTheme.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: capturado
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : onCapture,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(busy ? 'Processando...' : capturado ? 'Refazer' : 'Capturar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeria'),
                ),
              ),
              if (capturado) ...[
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: busy ? null : onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}