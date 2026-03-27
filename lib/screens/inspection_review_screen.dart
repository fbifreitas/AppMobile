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
    final summary = _buildSummary();
    final groups = _buildGroups();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu de vistoria'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: _reviewConfirmed
                ? () => _finishInspection(context, summary.pending)
                : null,
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text(
              'FINALIZAR VISTORIA',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _buildProgressCard(context, summary),
          const SizedBox(height: 18),
          Text(
            'Nós de coleta',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 10),
          ...groups.map((group) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NodeCard(
                  group: group,
                  onChanged: () => setState(() {}),
                  onApplySubtype: () => _applySubtype(group),
                  onApplySimilar: (source) => _applySimilar(group, source),
                  onAcceptSuggestions: () => _acceptSuggestions(group),
                ),
              )),
          const SizedBox(height: 16),
          _buildClosingCard(context, summary),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, _ReviewSummary summary) {
    final progress = summary.total == 0
        ? 0.0
        : (summary.classified / summary.total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.map_outlined, size: 24),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Fotos',
                value: '${summary.total}',
                color: Colors.blueGrey,
              ),
              _MetricChip(
                label: 'Concluídas',
                value: '${summary.classified}',
                color: Colors.green,
              ),
              _MetricChip(
                label: 'Pendências',
                value: '${summary.pending}',
                color: summary.pending > 0 ? Colors.orange : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary.pending > 0
                ? 'Existem pendências destacadas abaixo para revisão rápida.'
                : 'Tudo pronto para finalizar a vistoria.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingCard(BuildContext context, _ReviewSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Encerramento',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _observacaoController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Observação final',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Confirmo a revisão das evidências e pendências.',
              style: TextStyle(fontSize: 13),
            ),
            value: _reviewConfirmed,
            onChanged: (value) {
              setState(() {
                _reviewConfirmed = value ?? false;
              });
            },
          ),
          if (summary.pending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Atenção: ainda existem ${summary.pending} pendência(s).',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  _ReviewSummary _buildSummary() {
    final pending = _items.where((item) => item.status == _PhotoStatus.pending).length;
    final suggested = _items.where((item) => item.status == _PhotoStatus.suggested).length;
    final classified = _items.where((item) => item.status == _PhotoStatus.classified).length;
    return _ReviewSummary(
      total: _items.length,
      pending: pending,
      suggested: suggested,
      classified: classified,
    );
  }

  List<_NodeGroup> _buildGroups() {
    final map = <String, List<_EditableCapture>>{};
    for (final item in _items) {
      final key = item.ambiente.trim().isEmpty ? 'Sem subtipo' : item.ambiente;
      map.putIfAbsent(key, () => <_EditableCapture>[]).add(item);
    }

    final groups = map.entries.map((entry) {
      final items = entry.value;
      final pending = items.where((e) => e.status == _PhotoStatus.pending).length;
      final suggested = items.where((e) => e.status == _PhotoStatus.suggested).length;
      final classified = items.where((e) => e.status == _PhotoStatus.classified).length;

      return _NodeGroup(
        title: entry.key,
        items: items,
        pending: pending,
        suggested: suggested,
        classified: classified,
      );
    }).toList();

    groups.sort((a, b) {
      if (a.pending != b.pending) return b.pending.compareTo(a.pending);
      if (a.suggested != b.suggested) return b.suggested.compareTo(a.suggested);
      return a.title.compareTo(b.title);
    });

    return groups;
  }

  void _applySubtype(_NodeGroup group) {
    if (group.items.isEmpty) return;
    final source = group.items.firstWhere(
      (item) => item.hasAnyClassification,
      orElse: () => group.items.first,
    );
    setState(() {
      for (final item in group.items) {
        item.copyClassificationFrom(source);
        item.recalculateStatus(forceClassified: true);
      }
    });
  }

  void _acceptSuggestions(_NodeGroup group) {
    setState(() {
      for (final item in group.items) {
        if (item.status == _PhotoStatus.suggested) {
          item.recalculateStatus(forceClassified: true);
        }
      }
    });
  }

  void _applySimilar(_NodeGroup group, _EditableCapture source) {
    setState(() {
      for (final item in group.items) {
        item.copyClassificationFrom(source);
        item.recalculateStatus(forceClassified: true);
      }
    });
  }

  Future<void> _editItem(_EditableCapture item) async {
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        String? elemento = item.elemento;
        String? material = item.material;
        String? estado = item.estado;
        String? ambiente = item.ambiente;

        const elementos = <String>[
          'Visão geral',
          'Número',
          'Porta',
          'Portão',
          'Janela',
          'Piso',
          'Parede',
          'Teto',
          'Outro',
        ];
        const materiais = <String>[
          'Alvenaria',
          'Metal',
          'Madeira',
          'Vidro',
          'Cerâmica',
          'Concreto',
          'Outro',
        ];
        const estados = <String>[
          'Bom',
          'Regular',
          'Ruim',
          'Necessita reparo',
          'Não se aplica',
        ];
        const ambientes = <String>[
          'Fachada',
          'Logradouro',
          'Acesso ao imóvel',
          'Entorno',
          'Sala de Estar',
          'Sala',
          'Dormitório',
          'Cozinha',
          'Banheiro',
          'Área de serviço',
          'Áreas Comuns',
          'Garagem',
          'Outro ambiente',
        ];

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 4,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classificar foto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _EditorDropdown(
                      label: 'Subtipo / Local',
                      value: ambientes.contains(ambiente) ? ambiente : null,
                      items: ambientes,
                      onChanged: (value) => setSheetState(() => ambiente = value),
                    ),
                    const SizedBox(height: 10),
                    _EditorDropdown(
                      label: 'Elemento',
                      value: elementos.contains(elemento) ? elemento : null,
                      items: elementos,
                      onChanged: (value) => setSheetState(() => elemento = value),
                    ),
                    const SizedBox(height: 10),
                    _EditorDropdown(
                      label: 'Material',
                      value: materiais.contains(material) ? material : null,
                      items: materiais,
                      onChanged: (value) => setSheetState(() => material = value),
                    ),
                    const SizedBox(height: 10),
                    _EditorDropdown(
                      label: 'Estado',
                      value: estados.contains(estado) ? estado : null,
                      items: estados,
                      onChanged: (value) => setSheetState(() => estado = value),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          item.ambiente = ambiente ?? item.ambiente;
                          item.elemento = elemento;
                          item.material = material;
                          item.estado = estado;
                          item.recalculateStatus();
                          Navigator.of(sheetContext).pop(true);
                        },
                        child: const Text('Salvar classificação'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (edited == true && mounted) {
      setState(() {});
    }
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
                  'Ainda existem $pendingCount item(ns) com pendência. Deseja finalizar a vistoria mesmo assim?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Voltar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Finalizar mesmo assim'),
                  ),
                ],
              ),
            ) ??
            false;

    if (!shouldContinue) return;
    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Vistoria finalizada com sucesso.')),
    );
    navigator.popUntil((route) => route.isFirst);
  }
}

class _NodeCard extends StatelessWidget {
  final _NodeGroup group;
  final VoidCallback onChanged;
  final VoidCallback onApplySubtype;
  final VoidCallback onAcceptSuggestions;
  final ValueChanged<_EditableCapture> onApplySimilar;

  const _NodeCard({
    required this.group,
    required this.onChanged,
    required this.onApplySubtype,
    required this.onAcceptSuggestions,
    required this.onApplySimilar,
  });

  @override
  Widget build(BuildContext context) {
    final status = group.pending > 0
        ? _VisualStatus.pending
        : group.suggested > 0
            ? _VisualStatus.suggested
            : _VisualStatus.ok;

    final icon = _iconForSubtype(group.title);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: status.borderColor.withValues(alpha: 0.35),
          width: status == _VisualStatus.pending ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: status.iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: status.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.subtitle(group),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: group.pending > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: status.subtitleColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: _StatusPill(status: status, label: status.label(group)),
        children: [
          if (group.items.isNotEmpty)
            SizedBox(
              height: 158,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: group.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = group.items[index];
                  return _ThumbCard(
                    item: item,
                    onTap: () async {
                      final state = context.findAncestorStateOfType<_InspectionReviewScreenState>();
                      if (state != null) {
                        await state._editItem(item);
                        onChanged();
                      }
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onApplySubtype,
                icon: const Icon(Icons.copy_all_outlined, size: 16),
                label: const Text('Aplicar ao subtipo', style: TextStyle(fontSize: 12)),
              ),
              if (group.suggested > 0)
                OutlinedButton.icon(
                  onPressed: onAcceptSuggestions,
                  icon: const Icon(Icons.task_alt_outlined, size: 16),
                  label: const Text('Aceitar sugestões', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          if (group.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onApplySimilar(group.items.first),
                  icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                  label: const Text('Aplicar aos semelhantes', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForSubtype(String subtype) {
    final normalized = subtype.toLowerCase();
    if (normalized.contains('exterior') || normalized.contains('fachada')) {
      return Icons.home_outlined;
    }
    if (normalized.contains('sala')) {
      return Icons.weekend_outlined;
    }
    if (normalized.contains('cozinha')) {
      return Icons.restaurant_outlined;
    }
    if (normalized.contains('banheiro')) {
      return Icons.shower_outlined;
    }
    if (normalized.contains('área') || normalized.contains('comum')) {
      return Icons.apartment_outlined;
    }
    if (normalized.contains('garagem')) {
      return Icons.garage_outlined;
    }
    return Icons.grid_view_rounded;
  }
}

class _ThumbCard extends StatelessWidget {
  final _EditableCapture item;
  final VoidCallback onTap;

  const _ThumbCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.status == _PhotoStatus.pending
        ? _VisualStatus.pending
        : item.status == _PhotoStatus.suggested
            ? _VisualStatus.suggested
            : _VisualStatus.ok;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 122,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 92,
              width: 122,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _CaptureThumbnail(filePath: item.filePath),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.hourMinute,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _StatusPill(status: status, label: status.shortLabel),
            const SizedBox(height: 4),
            Text(
              item.shortDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
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
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 28)),
      );
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Image.file(
        file,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) {
          return const Center(child: Icon(Icons.broken_image_outlined, size: 28));
        },
      ),
    );
  }
}

class _EditorDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _EditorDropdown({
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
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.shade50,
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: color.shade800,
            fontSize: 11,
            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
          ),
          children: [
            TextSpan(
              text: '$value ',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _VisualStatus status;
  final String label;

  const _StatusPill({
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.pillBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.pillBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.pillText),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: status.pillText,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _VisualStatus { ok, suggested, pending }

extension on _VisualStatus {
  Color get borderColor {
    switch (this) {
      case _VisualStatus.ok:
        return Colors.green;
      case _VisualStatus.suggested:
        return Colors.amber;
      case _VisualStatus.pending:
        return Colors.orange;
    }
  }

  Color get iconBackground {
    switch (this) {
      case _VisualStatus.ok:
        return Colors.green.shade50;
      case _VisualStatus.suggested:
        return Colors.amber.shade50;
      case _VisualStatus.pending:
        return Colors.orange.shade50;
    }
  }

  Color get iconColor {
    switch (this) {
      case _VisualStatus.ok:
        return Colors.green.shade700;
      case _VisualStatus.suggested:
        return Colors.amber.shade800;
      case _VisualStatus.pending:
        return Colors.orange.shade700;
    }
  }

  Color get subtitleColor {
    switch (this) {
      case _VisualStatus.ok:
        return Colors.green.shade700;
      case _VisualStatus.suggested:
        return Colors.amber.shade800;
      case _VisualStatus.pending:
        return Colors.orange.shade700;
    }
  }

  Color get pillBackground {
    switch (this) {
      case _VisualStatus.ok:
        return Colors.green.shade50;
      case _VisualStatus.suggested:
        return Colors.amber.shade50;
      case _VisualStatus.pending:
        return Colors.orange.shade50;
    }
  }

  Color get pillBorder {
    switch (this) {
      case _VisualStatus.ok:
        return Colors.green.shade100;
      case _VisualStatus.suggested:
        return Colors.amber.shade100;
      case _VisualStatus.pending:
        return Colors.orange.shade200;
    }
  }

  Color get pillText {
    switch (this) {
      case _VisualStatus.ok:
        return Colors.green.shade700;
      case _VisualStatus.suggested:
        return Colors.amber.shade800;
      case _VisualStatus.pending:
        return Colors.orange.shade700;
    }
  }

  IconData get icon {
    switch (this) {
      case _VisualStatus.ok:
        return Icons.check_circle_outline;
      case _VisualStatus.suggested:
        return Icons.auto_awesome_outlined;
      case _VisualStatus.pending:
        return Icons.warning_amber_rounded;
    }
  }

  String get shortLabel {
    switch (this) {
      case _VisualStatus.ok:
        return 'OK';
      case _VisualStatus.suggested:
        return 'Sug.';
      case _VisualStatus.pending:
        return 'Pend.';
    }
  }

  String label(_NodeGroup group) {
    switch (this) {
      case _VisualStatus.ok:
        return 'OK';
      case _VisualStatus.suggested:
        return 'Revisar';
      case _VisualStatus.pending:
        final source = group.items.firstWhere(
          (item) => item.status == _PhotoStatus.pending,
          orElse: () => group.items.first,
        );
        return source.elemento?.trim().isNotEmpty == true
            ? source.elemento!
            : 'Pendente';
    }
  }

  String subtitle(_NodeGroup group) {
    switch (this) {
      case _VisualStatus.ok:
        return 'Tudo revisado e pronto para finalizar';
      case _VisualStatus.suggested:
        return 'Existem sugestões automáticas para revisar';
      case _VisualStatus.pending:
        final source = group.items.firstWhere(
          (item) => item.status == _PhotoStatus.pending,
          orElse: () => group.items.first,
        );
        final detail = source.elemento?.trim().isNotEmpty == true
            ? source.elemento!
            : 'Classificação incompleta';
        return 'Pendente: $detail';
    }
  }
}

class _NodeGroup {
  final String title;
  final List<_EditableCapture> items;
  final int pending;
  final int suggested;
  final int classified;

  const _NodeGroup({
    required this.title,
    required this.items,
    required this.pending,
    required this.suggested,
    required this.classified,
  });
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

  String get shortDescription {
    final parts = <String>[
      if (elemento?.trim().isNotEmpty == true) elemento!,
      if (material?.trim().isNotEmpty == true) material!,
      if (estado?.trim().isNotEmpty == true) estado!,
    ];
    return parts.isEmpty ? 'Sem classificação' : parts.join(' • ');
  }

  void copyClassificationFrom(_EditableCapture source) {
    ambiente = source.ambiente;
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

  const _ReviewSummary({
    required this.total,
    required this.pending,
    required this.suggested,
    required this.classified,
  });
}
