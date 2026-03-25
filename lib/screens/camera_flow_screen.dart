import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/inspection_state.dart';
import '../models/inspection_template_model.dart';
import '../models/inspection_session_model.dart';

class CameraFlowScreen extends StatefulWidget {
  const CameraFlowScreen({super.key});

  @override
  State<CameraFlowScreen> createState() => _CameraFlowScreenState();
}

class _CameraFlowScreenState extends State<CameraFlowScreen> {
  String? _selectedElementId;
  String? _selectedMaterial;
  String? _selectedEstado;

  @override
  Widget build(BuildContext context) {
    return Consumer<InspectionState>(
      builder: (context, inspectionState, _) {
        final session = inspectionState.session;
        final ambiente = inspectionState.getSelectedEnvironment();

        if (session == null || ambiente == null) {
          return const Scaffold(
            body: Center(child: Text('Nenhum ambiente selecionado.')),
          );
        }

        final template = session.template.getEnvironmentById(ambiente.ambienteId);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Coleta'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _WhereAmICard(
                  ambiente: ambiente,
                  onChangeEnvironment: () {
                    _showEnvironmentPicker(context, inspectionState, session);
                  },
                ),
                if (!session.gpsEnabled)
                  _GpsBlockedBanner(
                    onEnable: () => inspectionState.setGpsEnabled(true),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (template != null) ...[
                          Text(
                            'O que estou analisando?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: template.elementos.map((elemento) {
                              final selected = _selectedElementId == elemento.id;
                              return ChoiceChip(
                                label: Text(elemento.nome),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedElementId = elemento.id;
                                    _selectedMaterial = null;
                                    _selectedEstado = null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          if (_selectedElementId != null) ...[
                            _buildMaterialSection(template),
                            const SizedBox(height: 16),
                            _buildEstadoSection(template),
                            const SizedBox(height: 20),
                          ],
                        ],
                        _CaptureActions(
                          gpsEnabled: session.gpsEnabled,
                          onCamera: session.gpsEnabled
                              ? () {
                                  final element = _getSelectedElement(template);
                                  inspectionState.addMockCameraEvidence(
                                    ambienteId: ambiente.ambienteId,
                                    elementoId: element?.id,
                                    elementoNome: element?.nome,
                                    material: _selectedMaterial,
                                    estadoConservacao: _selectedEstado,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Foto capturada com sucesso.'),
                                    ),
                                  );
                                }
                              : null,
                          onGallery: session.gpsEnabled &&
                                  session.template.auditRules.galleryAllowed
                              ? () {
                                  final element = _getSelectedElement(template);
                                  inspectionState.addMockGalleryEvidence(
                                    ambienteId: ambiente.ambienteId,
                                    elementoId: element?.id,
                                    elementoNome: element?.nome,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Imagem da galeria vinculada com sucesso.',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                        const SizedBox(height: 24),
                        _EvidenceList(
                          ambiente: ambiente,
                          onDelete: (evidenceId) {
                            inspectionState.removeEvidence(
                              ambienteId: ambiente.ambienteId,
                              evidenceId: evidenceId,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialSection(EnvironmentTemplate template) {
    final selectedElement = _getSelectedElement(template);
    final materiais = selectedElement?.materiais ?? const <String>[];

    if (materiais.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Material',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: materiais.map((material) {
            return ChoiceChip(
              label: Text(material),
              selected: _selectedMaterial == material,
              onSelected: (_) {
                setState(() {
                  _selectedMaterial = material;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEstadoSection(EnvironmentTemplate template) {
    final selectedElement = _getSelectedElement(template);
    final estados = selectedElement?.estadosConservacao ?? const <String>[];

    if (estados.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado de conservação',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: estados.map((estado) {
            return ChoiceChip(
              label: Text(estado),
              selected: _selectedEstado == estado,
              onSelected: (_) {
                setState(() {
                  _selectedEstado = estado;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  ElementTemplate? _getSelectedElement(EnvironmentTemplate? template) {
    if (template == null || _selectedElementId == null) return null;
    try {
      return template.elementos.firstWhere((e) => e.id == _selectedElementId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _showEnvironmentPicker(
    BuildContext context,
    InspectionState inspectionState,
    InspectionSession session,
  ) async {
    final textController = TextEditingController(
      text: inspectionState.suggestedMissingEnvironmentName,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Onde estou?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...session.ambientes.map((ambiente) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ambiente.ambienteNome),
                      onTap: () {
                        inspectionState.selectEnvironment(ambiente.ambienteId);
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const Divider(),
                  Text(
                    'Ambiente não existe',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Qual ambiente encontrou?',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      inspectionState.setSuggestedMissingEnvironmentName(value);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: textController.text.trim().isEmpty
                          ? null
                          : () {
                              inspectionState.setSuggestedMissingEnvironmentName(
                                textController.text,
                              );
                              inspectionState.registerMissingEnvironmentSuggestion();
                              Navigator.pop(context);
                            },
                      child: const Text('Salvar ambiente não configurado'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _WhereAmICard extends StatelessWidget {
  final InspectionEnvironmentProgress ambiente;
  final VoidCallback onChangeEnvironment;

  const _WhereAmICard({
    required this.ambiente,
    required this.onChangeEnvironment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.primary.withOpacity(0.08),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Onde estou?',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ambiente.ambienteNome,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeEnvironment,
            child: const Text('Trocar'),
          ),
        ],
      ),
    );
  }
}

class _GpsBlockedBanner extends StatelessWidget {
  final VoidCallback onEnable;

  const _GpsBlockedBanner({
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.errorContainer,
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Para registrar evidências da vistoria, ative o GPS do aparelho.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: onEnable,
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
  }
}

class _CaptureActions extends StatelessWidget {
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final bool gpsEnabled;

  const _CaptureActions({
    required this.onCamera,
    required this.onGallery,
    required this.gpsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registrar evidência',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Capturar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeria'),
              ),
            ),
          ],
        ),
        if (!gpsEnabled) ...[
          const SizedBox(height: 8),
          const Text('Captura bloqueada enquanto o GPS estiver desligado.'),
        ],
      ],
    );
  }
}

class _EvidenceList extends StatelessWidget {
  final InspectionEnvironmentProgress ambiente;
  final ValueChanged<String> onDelete;

  const _EvidenceList({
    required this.ambiente,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (ambiente.evidencias.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        ),
        child: const Text('Nenhuma evidência registrada neste ambiente.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidências deste ambiente',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        ...ambiente.evidencias.map(
          (evidence) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.photo_camera_back_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(evidence.elementoNome ?? 'Sem elemento definido'),
                      const SizedBox(height: 4),
                      Text(
                        '${evidence.source == EvidenceSource.camera ? 'Câmera' : 'Galeria'} • ${evidence.geoPoint.capturedAt}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onDelete(evidence.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}