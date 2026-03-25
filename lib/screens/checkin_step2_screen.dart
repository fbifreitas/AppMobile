import 'package:flutter/material.dart';

import '../config/checkin_step2_config.dart';
import '../models/checkin_step2_model.dart';

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
    /// Aqui fica o ponto de integração com camera/image_picker.
    /// Por enquanto deixei um mock funcional para não travar a tela.
    setState(() {
      _model = _model.setPhoto(
        fieldId: field.id,
        titulo: field.titulo,
        imagePath: 'mock://${field.id}/${DateTime.now().millisecondsSinceEpoch}',
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Foto de "${field.titulo}" marcada como capturada.'),
      ),
    );
  }

  void _handleRemovePhoto(CheckinStep2PhotoFieldConfig field) {
    setState(() {
      _model = _model.removePhoto(field.id);
    });
  }

  void _handleContinue() {
    widget.onContinue?.call(_model);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Etapa 2 preenchida com sucesso.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Vistoria'),
      ),
      body: SafeArea(
        child: Column(
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
                        onPressed: _handleContinue,
                        child: const Text('Salvar e continuar'),
                      ),
                    ),
                  ],
                ),
              ),
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
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
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
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Preencha as evidências fotográficas e as informações externas do imóvel.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
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
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._config.camposFotos.map((field) => _PhotoCaptureCard(
              titulo: field.titulo,
              obrigatorio: field.obrigatorio,
              capturado: _model.isPhotoCaptured(field.id),
              icon: field.icon,
              onCapture: () => _handleCapture(field),
              onRemove: () => _handleRemovePhoto(field),
            )),
      ],
    );
  }

  Widget _buildDynamicOptionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Infraestrutura e serviços',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
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

  Widget _buildOptionGroupCard(
    ThemeData theme,
    CheckinStep2OptionGroupConfig grupo,
  ) {
    final resposta = _model.respostas[grupo.id];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            grupo.titulo,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
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
                _model = _model.setObservacao(
                  groupId: grupo.id,
                  observacao: value,
                );
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
  final IconData icon;
  final VoidCallback onCapture;
  final VoidCallback onRemove;

  const _PhotoCaptureCard({
    required this.titulo,
    required this.obrigatorio,
    required this.capturado,
    required this.icon,
    required this.onCapture,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: capturado
              ? theme.colorScheme.primary.withOpacity(0.35)
              : theme.dividerColor.withOpacity(0.20),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: capturado
                ? theme.colorScheme.primary.withOpacity(0.12)
                : theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              capturado ? Icons.check_circle_outline : icon,
              color: capturado
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  capturado
                      ? 'Imagem capturada'
                      : obrigatorio
                          ? 'Foto obrigatória'
                          : 'Foto opcional',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: capturado
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodySmall?.color?.withOpacity(0.70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (capturado)
            IconButton(
              tooltip: 'Remover',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          FilledButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(capturado ? 'Refazer' : 'Capturar'),
          ),
        ],
      ),
    );
  }
}