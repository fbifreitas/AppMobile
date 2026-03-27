import 'dart:io';

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
  final TextEditingController _observacaoController = TextEditingController();
  bool _reviewConfirmed = false;

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
    final summary = _buildSummary();

    return Scaffold(
      appBar: AppBar(title: const Text('Pós-vistoria')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryHeader(context, summary),
          const SizedBox(height: 16),
          if (summary.pending > 0 || summary.suggested > 0)
            _buildPendingBanner(context, summary),
          const SizedBox(height: 16),
          ...groups.entries.map((entry) {
            return _SubtypeSection(
              subtype: entry.key,
              items: entry.value,
              onItemChanged: () => setState(() {}),
              onApplyToSubtype: () => _applyToSubtype(entry.value),
              onAcceptSuggestions: () => _acceptSuggestions(entry.value),
              onApplyToSimilar: (source) => _applyToSimilar(entry.key, source),
            );
          }),
          const SizedBox(height: 16),
          _buildClosingCard(context, summary.pending),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  _ReviewSummary _buildSummary() {
    final pending = _items.where((item) => item.status == _PhotoStatus.pending).length;
    final suggested = _items.where((item) => item.status == _PhotoStatus.suggested).length;
    final classified = _items.where((item) => item.status == _PhotoStatus.classified).length;
    final subtypes = _buildGroups().length;
    return _ReviewSummary(
      total: _items.length,
      pending: pending,
      suggested: suggested,
      classified: classified,
      subtypes: subtypes,
    );
  }

  Widget _buildSummaryHeader(BuildContext context, _ReviewSummary summary) {
    final cards = <_SummaryCardData>[
      _SummaryCardData('Fotos', '${summary.total}', Icons.photo_library_outlined),
      _SummaryCardData('Subtipos', '${summary.subtypes}', Icons.grid_view_rounded),
      _SummaryCardData('Pendências', '${summary.pending}', Icons.priority_high_rounded),
      _SummaryCardData('Classificadas', '${summary.classified}', Icons.task_alt_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formulário pós-vistoria consolidado',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Tipo de imóvel: ${widget.tipoImovel}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          itemCount: cards.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.15,
          ),
          itemBuilder: (context, index) {
            final item = cards[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Icon(item.icon, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.value,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          item.label,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPendingBanner(BuildContext context, _ReviewSummary summary) {
    final hasCritical = summary.pending > 0;
    final background = hasCritical ? Colors.red.shade50 : Colors.amber.shade50;
    final border = hasCritical ? Colors.red.shade200 : Colors.amber.shade200;
    final titleColor = hasCritical ? Colors.red.shade800 : Colors.amber.shade900;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasCritical ? 'Pendências críticas encontradas' : 'Existem sugestões para revisar',
            style: TextStyle(fontWeight: FontWeight.w800, color: titleColor),
          ),
          const SizedBox(height: 8),
          if (summary.pending > 0)
            Text('• ${summary.pending} foto(s) com classificação incompleta.'),
          if (summary.suggested > 0)
            Text('• ${summary.suggested} foto(s) ainda estão com sugestão automática.'),
          const SizedBox(height: 8),
          const Text(
            'Revise os grupos abaixo. As pendências aparecem destacadas por subtipo para facilitar a validação final.',
          ),
        ],
      ),
    );
  }

  Widget _buildClosingCard(BuildContext context, int pendingCount) {
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
            value: _reviewConfirmed,
            contentPadding: EdgeInsets.zero,
            title: const Text('Confirmo que revisei evidências e pendências desta vistoria.'),
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
              onPressed: _reviewConfirmed ? () => _finishInspection(context, pendingCount) : null,
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
      final key = item.ambiente.trim().isEmpty ? 'Sem subtipo' : item.ambiente;
      grouped.putIfAbsent(key, () => <_EditableCapture>[]).add(item);
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

  void _applyToSubtype(List<_EditableCapture> captures) {
    if (captures.isEmpty) return;
    final source = captures.firstWhere(
      (item) => item.hasAnyClassification,
      orElse: () => captures.first,
    );

    setState(() {
      for (final item in captures) {
        item.copyClassificationFrom(source);
        item.recalculateStatus(forceClassified: true);
      }
    });
  }

  void _acceptSuggestions(List<_EditableCapture> captures) {
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
        item.copyClassificationFrom(source);
        item.recalculateStatus(forceClassified: true);
      }
    });
  }
}

class _SubtypeSection extends StatelessWidget {
  final String subtype;
  final List<_EditableCapture> items;
  final VoidCallback onItemChanged;
  final VoidCallback onApplyToSubtype;
  final VoidCallback onAcceptSuggestions;
  final ValueChanged<_EditableCapture> onApplyToSimilar;

  const _SubtypeSection({
    required this.subtype,
    required this.items,
    required this.onItemChanged,
    required this.onApplyToSubtype,
    required this.onAcceptSuggestions,
    required this.onApplyToSimilar,
  });

  @override
  Widget build(BuildContext context) {
    final pending = items.where((item) => item.status == _PhotoStatus.pending).length;
    final suggested = items.where((item) => item.status == _PhotoStatus.suggested).length;
    final classified = items.where((item) => item.status == _PhotoStatus.classified).length;

    final statusColor = pending > 0
        ? Colors.red
        : suggested > 0
            ? Colors.amber
            : Colors.green;
    final statusText = pending > 0
        ? 'Pendente'
        : suggested > 0
            ? 'Sugerida'
            : 'Completo';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2),
      ),
      child: ExpansionTile(
        initiallyExpanded: pending > 0,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          subtype,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallBadge(label: '${items.length} foto(s)', color: Colors.blueGrey),
              _SmallBadge(label: '$classified classificadas', color: Colors.green),
              if (pending > 0) _SmallBadge(label: '$pending pendente(s)', color: Colors.red),
              if (suggested > 0) _SmallBadge(label: '$suggested sugerida(s)', color: Colors.amber),
            ],
          ),
        ),
        trailing: _SmallBadge(label: statusText, color: statusColor),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onApplyToSubtype,
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  label: const Text('Aplicar ao subtipo'),
                ),
                if (pending > 0 || suggested > 0)
                  FilledButton.icon(
                    onPressed: onAcceptSuggestions,
                    icon: const Icon(Icons.task_alt_outlined, size: 18),
                    label: const Text('Aceitar sugestões'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _CaptureCard(
                  item: item,
                  onChanged: onItemChanged,
                  onApplyToSimilar: () => onApplyToSimilar(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  final _EditableCapture item;
  final VoidCallback onChanged;
  final VoidCallback onApplyToSimilar;

  const _CaptureCard({
    required this.item,
    required this.onChanged,
    required this.onApplyToSimilar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 285,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _CaptureThumbnail(filePath: item.filePath),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(status: item.status),
                _SmallBadge(label: item.hourMinute, color: Colors.blueGrey),
                if ((item.macroLocal ?? '').isNotEmpty)
                  _SmallBadge(label: item.macroLocal!, color: Colors.indigo),
              ],
            ),
            const SizedBox(height: 10),
            _ReviewDropdown(
              label: 'Elemento',
              value: item.elemento,
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
              onChanged: (value) {
                item.elemento = value;
                item.recalculateStatus();
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            _ReviewDropdown(
              label: 'Material',
              value: item.material,
              items: const [
                'Alvenaria',
                'Metal',
                'Madeira',
                'Vidro',
                'Cerâmica',
                'Concreto',
                'Outro',
              ],
              onChanged: (value) {
                item.material = value;
                item.recalculateStatus();
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            _ReviewDropdown(
              label: 'Estado',
              value: item.estado,
              items: const [
                'Bom',
                'Regular',
                'Ruim',
                'Necessita reparo',
                'Não se aplica',
              ],
              onChanged: (value) {
                item.estado = value;
                item.recalculateStatus();
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            _ReviewDropdown(
              label: 'Subtipo / Local',
              value: item.ambiente,
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
              onChanged: (value) {
                item.ambiente = value ?? item.ambiente;
                item.recalculateStatus();
                onChanged();
              },
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onApplyToSimilar,
                icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                label: const Text('Aplicar aos semelhantes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureThumbnail extends StatelessWidget {
  final String filePath;

  const _CaptureThumbnail({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 34),
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, size: 34),
          ),
        );
      },
    );
  }
}

class _ReviewDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _ReviewDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value != null && items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
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
}

class _StatusChip extends StatelessWidget {
  final _PhotoStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final MaterialColor color;
    late final String label;

    switch (status) {
      case _PhotoStatus.pending:
        color = Colors.red;
        label = 'Pendente';
        break;
      case _PhotoStatus.suggested:
        color = Colors.amber;
        label = 'Sugerida';
        break;
      case _PhotoStatus.classified:
        color = Colors.green;
        label = 'Classificada';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.shade50,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color.shade700,
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final MaterialColor color;

  const _SmallBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.shade50,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.shade700,
        ),
      ),
    );
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

    final hasAnyClassification = (capture.elemento?.trim().isNotEmpty ?? false) ||
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
          : hasAnyClassification
              ? _PhotoStatus.suggested
              : _PhotoStatus.pending,
    );
  }

  bool get hasAnyClassification =>
      (elemento?.trim().isNotEmpty ?? false) ||
      (material?.trim().isNotEmpty ?? false) ||
      (estado?.trim().isNotEmpty ?? false);

  String get hourMinute =>
      '${capturedAt.hour.toString().padLeft(2, '0')}:${capturedAt.minute.toString().padLeft(2, '0')}';

  void copyClassificationFrom(_EditableCapture source) {
    elemento = source.elemento;
    material = source.material;
    estado = source.estado;
    macroLocal = source.macroLocal;
  }

  void recalculateStatus({bool forceClassified = false}) {
    final hasCompleteClassification = (elemento?.trim().isNotEmpty ?? false) &&
        (material?.trim().isNotEmpty ?? false) &&
        (estado?.trim().isNotEmpty ?? false);

    final hasAnyClassification = (elemento?.trim().isNotEmpty ?? false) ||
        (material?.trim().isNotEmpty ?? false) ||
        (estado?.trim().isNotEmpty ?? false);

    if (forceClassified && hasAnyClassification) {
      status = _PhotoStatus.classified;
      return;
    }

    if (hasCompleteClassification) {
      status = _PhotoStatus.classified;
    } else if (hasAnyClassification) {
      status = _PhotoStatus.suggested;
    } else {
      status = _PhotoStatus.pending;
    }
  }
}

enum _PhotoStatus { pending, suggested, classified }

class _ReviewSummary {
  final int total;
  final int pending;
  final int suggested;
  final int classified;
  final int subtypes;

  const _ReviewSummary({
    required this.total,
    required this.pending,
    required this.suggested,
    required this.classified,
    required this.subtypes,
  });
}

class _SummaryCardData {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCardData(this.label, this.value, this.icon);
}
