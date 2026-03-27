import 'package:flutter/material.dart';

import 'overlay_camera_screen.dart';

class InspectionReviewScreen extends StatefulWidget {
  final List<OverlayCameraCaptureResult> captures;
  final String tipoImovel;

  const InspectionReviewScreen({
    super.key,
    this.captures = const <OverlayCameraCaptureResult>[],
    this.tipoImovel = 'Urbano',
  });

  @override
  State<InspectionReviewScreen> createState() => _InspectionReviewScreenState();
}

class _InspectionReviewScreenState extends State<InspectionReviewScreen> {
  late final List<_EditableCapture> _items;
  bool _reviewConfirmed = false;
  final TextEditingController _observacaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = widget.captures.map(_EditableCapture.fromCapture).toList();
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();
    final pendingCount = _items.where((item) => item.status == _PhotoStatus.pending).length;
    final suggestedCount = _items.where((item) => item.status == _PhotoStatus.suggested).length;
    final classifiedCount = _items.where((item) => item.status == _PhotoStatus.classified).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pós-vistoria'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(
            context: context,
            total: _items.length,
            pending: pendingCount,
            suggested: suggestedCount,
            classified: classifiedCount,
          ),
          const SizedBox(height: 16),
          if (pendingCount > 0 || suggestedCount > 0)
            _buildPendingPanel(
              context: context,
              pendingCount: pendingCount,
              suggestedCount: suggestedCount,
            ),
          const SizedBox(height: 16),
          ...groups.entries.map((entry) => _buildSubtypeCard(context, entry.key, entry.value)),
          const SizedBox(height: 16),
          _buildClosingCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderCard({
    required BuildContext context,
    required int total,
    required int pending,
    required int suggested,
    required int classified,
  }) {
    final cards = <_SummaryData>[
      _SummaryData(label: 'Fotos', value: '$total', icon: Icons.photo_library_outlined),
      _SummaryData(label: 'Pendências', value: '$pending', icon: Icons.priority_high_rounded),
      _SummaryData(label: 'Sugeridas', value: '$suggested', icon: Icons.auto_awesome_outlined),
      _SummaryData(label: 'Classificadas', value: '$classified', icon: Icons.task_alt_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formulário pós-vistoria consolidado',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tipo de imóvel: ${widget.tipoImovel}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.3,
          children: cards.map((item) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Icon(item.icon, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(item.label, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPendingPanel({
    required BuildContext context,
    required int pendingCount,
    required int suggestedCount,
  }) {
    final hasCritical = pendingCount > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: hasCritical
            ? Colors.red.withValues(alpha: 0.10)
            : Colors.amber.withValues(alpha: 0.10),
        border: Border.all(
          color: hasCritical
              ? Colors.red.withValues(alpha: 0.35)
              : Colors.amber.withValues(alpha: 0.35),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasCritical ? 'Pendências críticas encontradas' : 'Existem sugestões para revisar',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: hasCritical ? Colors.red.shade800 : Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 8),
          if (pendingCount > 0)
            Text(
              '• $pendingCount foto(s) com classificação incompleta.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (suggestedCount > 0)
            Text('• $suggestedCount foto(s) ainda estão apenas com sugestão automática.'),
          const SizedBox(height: 8),
          const Text(
            'Revise os grupos abaixo antes de encerrar a vistoria. As pendências ficam destacadas por subtipo.',
          ),
        ],
      ),
    );
  }

  Widget _buildSubtypeCard(
    BuildContext context,
    String subtype,
    List<_EditableCapture> captures,
  ) {
    final pendingCount = captures.where((item) => item.status == _PhotoStatus.pending).length;
    final suggestedCount = captures.where((item) => item.status == _PhotoStatus.suggested).length;
    final classifiedCount = captures.where((item) => item.status == _PhotoStatus.classified).length;

    final statusColor = pendingCount > 0
        ? Colors.red
        : suggestedCount > 0
            ? Colors.amber
            : Colors.green;

    final statusText = pendingCount > 0
        ? 'Pendente'
        : suggestedCount > 0
            ? 'Sugerida'
            : 'Completo';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: pendingCount > 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          subtype,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${captures.length} foto(s) • $classifiedCount classificadas • $pendingCount pendente(s)',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: statusColor.withValues(alpha: 0.12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: statusColor.shade700,
            ),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: captures.isEmpty ? null : () => _applyFirstClassificationToSubtype(captures),
                  icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                  label: const Text('Aplicar ao subtipo'),
                ),
                if (pendingCount > 0)
                  FilledButton.icon(
                    onPressed: () => _markSuggestedAsClassified(captures),
                    icon: const Icon(Icons.task_alt_outlined, size: 18),
                    label: const Text('Aceitar sugestões'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...captures.map((capture) => _buildCaptureEditor(context, subtype, capture)),
        ],
      ),
    );
  }

  Widget _buildCaptureEditor(
    BuildContext context,
    String subtype,
    _EditableCapture item,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildStatusChip(item.status),
              Text(
                'Capturada às ${item.hourMinute}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (item.macroLocal != null && item.macroLocal!.isNotEmpty)
                Text(
                  item.macroLocal!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dropdownField(
                  label: 'Elemento',
                  initialValue: item.elemento,
                  items: const [
                    'Visão geral',
                    'Número',
                    'Porta',
                    'Portão',
                    'Janela',
                    'Piso',
                    'Parede',
                    'Teto',
                    'Outro',
                  ],
                  onChanged: (value) => setState(() {
                    item.elemento = value;
                    item.recalculateStatus();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdownField(
                  label: 'Material',
                  initialValue: item.material,
                  items: const [
                    'Alvenaria',
                    'Metal',
                    'Madeira',
                    'Vidro',
                    'Cerâmica',
                    'Concreto',
                    'Outro',
                  ],
                  onChanged: (value) => setState(() {
                    item.material = value;
                    item.recalculateStatus();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdownField(
                  label: 'Estado',
                  initialValue: item.estado,
                  items: const [
                    'Bom',
                    'Regular',
                    'Ruim',
                    'Necessita reparo',
                    'Não se aplica',
                  ],
                  onChanged: (value) => setState(() {
                    item.estado = value;
                    item.recalculateStatus();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdownField(
                  label: 'Área da foto',
                  initialValue: item.macroLocal,
                  items: const [
                    'Área externa',
                    'Área interna',
                    'Área comum',
                    'Acesso',
                    'Entorno',
                  ],
                  onChanged: (value) => setState(() {
                    item.macroLocal = value;
                    item.recalculateStatus();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _dropdownField(
            label: 'Subtipo / Local',
            initialValue: item.ambiente,
            items: const [
              'Fachada',
              'Logradouro',
              'Acesso ao imóvel',
              'Entorno',
              'Sala',
              'Dormitório',
              'Cozinha',
              'Banheiro',
              'Área de serviço',
              'Garagem',
              'Outro ambiente',
            ],
            onChanged: (value) => setState(() {
              item.ambiente = value ?? item.ambiente;
              item.recalculateStatus();
            }),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _applyToSimilar(subtype, item),
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              label: const Text('Aplicar aos semelhantes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? initialValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = initialValue != null && items.contains(initialValue) ? initialValue : null;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildStatusChip(_PhotoStatus status) {
    late final Color color;
    late final String text;

    switch (status) {
      case _PhotoStatus.pending:
        color = Colors.red;
        text = 'Pendente';
        break;
      case _PhotoStatus.suggested:
        color = Colors.amber;
        text = 'Sugerida';
        break;
      case _PhotoStatus.classified:
        color = Colors.green;
        text = 'Classificada';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: status == _PhotoStatus.pending
        ? Colors.red.shade700
        : status == _PhotoStatus.suggested
            ? Colors.amber.shade800
            : Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _buildClosingCard(BuildContext context) {
    final pendingCount = _items.where((item) => item.status == _PhotoStatus.pending).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Encerramento da vistoria',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _observacaoController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Observação final',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _reviewConfirmed,
            title: const Text('Confirmo que revisei as evidências e pendências desta vistoria.'),
            onChanged: (value) {
              setState(() {
                _reviewConfirmed = value ?? false;
              });
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (!_reviewConfirmed) ? null : () => _finishInspection(context, pendingCount),
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Encerrar vistoria'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishInspection(BuildContext context, int pendingCount) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final shouldContinue = pendingCount == 0
      ? true
      : await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Existem pendências'),
              content: Text(
                'Ainda existem $pendingCount foto(s) com classificação incompleta. Deseja encerrar a vistoria mesmo assim?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Voltar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Encerrar mesmo assim'),
                ),
              ],
            ),
          ) ??
          false;

  if (!shouldContinue) return;
  if (!mounted) return;

  messenger.showSnackBar(
    const SnackBar(content: Text('Vistoria encerrada com sucesso.')),
  );
  navigator.popUntil((route) => route.isFirst);
}

  Map<String, List<_EditableCapture>> _buildGroups() {
    final grouped = <String, List<_EditableCapture>>{};
    for (final item in _items) {
      final subtype = item.ambiente.trim().isEmpty ? 'Sem subtipo' : item.ambiente;
      grouped.putIfAbsent(subtype, () => <_EditableCapture>[]).add(item);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final aPending = a.value.where((item) => item.status == _PhotoStatus.pending).length;
        final bPending = b.value.where((item) => item.status == _PhotoStatus.pending).length;
        if (aPending != bPending) return bPending.compareTo(aPending);
        return a.key.compareTo(b.key);
      });

    return Map<String, List<_EditableCapture>>.fromEntries(entries);
  }

  void _applyFirstClassificationToSubtype(List<_EditableCapture> captures) {
    if (captures.isEmpty) return;
    final source = captures.firstWhere(
      (item) => item.elemento != null || item.material != null || item.estado != null,
      orElse: () => captures.first,
    );

    setState(() {
      for (final item in captures) {
        item.elemento = source.elemento;
        item.material = source.material;
        item.estado = source.estado;
        item.recalculateStatus(forceClassified: true);
      }
    });
  }

  void _markSuggestedAsClassified(List<_EditableCapture> captures) {
    setState(() {
      for (final item in captures) {
        if (item.status == _PhotoStatus.suggested) {
          item.recalculateStatus(forceClassified: true);
        }
      }
    });
  }

  void _applyToSimilar(String subtype, _EditableCapture source) {
    setState(() {
      for (final item in _items.where((capture) => capture.ambiente == subtype)) {
        item.elemento = source.elemento;
        item.material = source.material;
        item.estado = source.estado;
        item.macroLocal = source.macroLocal;
        item.recalculateStatus(forceClassified: true);
      }
    });
  }
}

class _EditableCapture {
  String filePath;
  String? macroLocal;
  String ambiente;
  String? elemento;
  String? material;
  String? estado;
  DateTime capturedAt;
  _PhotoStatus status;

  _EditableCapture({
    required this.filePath,
    required this.macroLocal,
    required this.ambiente,
    required this.elemento,
    required this.material,
    required this.estado,
    required this.capturedAt,
    required this.status,
  });

  factory _EditableCapture.fromCapture(OverlayCameraCaptureResult capture) {
    final hasCompleteClassification = (capture.elemento?.trim().isNotEmpty ?? false) &&
        (capture.material?.trim().isNotEmpty ?? false) &&
        (capture.estado?.trim().isNotEmpty ?? false);

    final hasAnySuggestion = (capture.elemento?.trim().isNotEmpty ?? false) ||
        (capture.material?.trim().isNotEmpty ?? false) ||
        (capture.estado?.trim().isNotEmpty ?? false);

    return _EditableCapture(
      filePath: capture.filePath,
      macroLocal: capture.macroLocal,
      ambiente: capture.ambiente,
      elemento: capture.elemento,
      material: capture.material,
      estado: capture.estado,
      capturedAt: capture.capturedAt,
      status: hasCompleteClassification
          ? _PhotoStatus.classified
          : hasAnySuggestion
              ? _PhotoStatus.suggested
              : _PhotoStatus.pending,
    );
  }

  String get hourMinute =>
      '${capturedAt.hour.toString().padLeft(2, '0')}:${capturedAt.minute.toString().padLeft(2, '0')}';

  void recalculateStatus({bool forceClassified = false}) {
    final hasCompleteClassification = (elemento?.trim().isNotEmpty ?? false) &&
        (material?.trim().isNotEmpty ?? false) &&
        (estado?.trim().isNotEmpty ?? false);

    final hasAnySuggestion = (elemento?.trim().isNotEmpty ?? false) ||
        (material?.trim().isNotEmpty ?? false) ||
        (estado?.trim().isNotEmpty ?? false);

    if (forceClassified && hasAnySuggestion) {
      status = _PhotoStatus.classified;
      return;
    }

    if (hasCompleteClassification) {
      status = _PhotoStatus.classified;
    } else if (hasAnySuggestion) {
      status = _PhotoStatus.suggested;
    } else {
      status = _PhotoStatus.pending;
    }
  }
}

enum _PhotoStatus { pending, suggested, classified }

class _SummaryData {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryData({
    required this.label,
    required this.value,
    required this.icon,
  });
}
