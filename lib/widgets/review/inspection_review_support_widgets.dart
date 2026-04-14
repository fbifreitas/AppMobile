import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/inspection_review_models.dart';

class ReviewCheckinRequirementCard extends StatelessWidget {
  final InspectionReviewRequirementGroupStatus status;
  final VoidCallback? onCapture;

  const ReviewCheckinRequirementCard({
    super.key,
    required this.status,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.isDone ? Colors.green : Colors.orange;
    final subtitle =
        status.isDone ? 'Obrigatório atendido' : 'Obrigatório — pendente de captura';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: status.isDone ? 1.0 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(status.icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: status.isDone ? Colors.green.shade700 : Colors.orange.shade800,
                    fontWeight: status.isDone ? FontWeight.w600 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Progresso ${status.doneCount}/${status.totalCount}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (status.isDone)
            ReviewStatusPill(status: ReviewVisualStatus.ok, label: 'OK')
          else
            FilledButton.tonalIcon(
              onPressed: onCapture,
              icon: const Icon(Icons.photo_camera_outlined, size: 16),
              label: const Text(
                'Capturar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class ReviewNodeCard extends StatelessWidget {
  final InspectionReviewNodeGroup group;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onChanged;
  final VoidCallback onApplySubtype;
  final VoidCallback onAcceptSuggestions;
  final ValueChanged<InspectionReviewEditableCapture> onApplySimilar;
  final Future<void> Function(InspectionReviewEditableCapture) onEditItem;

  const ReviewNodeCard({
    super.key,
    required this.group,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.onChanged,
    required this.onApplySubtype,
    required this.onAcceptSuggestions,
    required this.onApplySimilar,
    required this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    final status = group.pending > 0
        ? ReviewVisualStatus.pending
        : group.suggested > 0
            ? ReviewVisualStatus.suggested
            : ReviewVisualStatus.ok;
    final icon = _iconForSubtype(group.title);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: status.borderColor.withValues(alpha: 0.35),
          width: status == ReviewVisualStatus.pending ? 1.4 : 1.0,
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
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
        trailing: ReviewStatusPill(status: status, label: status.label(group)),
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
                  return ReviewThumbCard(
                    item: item,
                    onTap: () async {
                      await onEditItem(item);
                      onChanged();
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
                label: const Text(
                  'Aplicar ao subtipo',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (group.suggested > 0)
                OutlinedButton.icon(
                  onPressed: onAcceptSuggestions,
                  icon: const Icon(Icons.task_alt_outlined, size: 16),
                  label: const Text(
                    'Aceitar sugestões',
                    style: TextStyle(fontSize: 12),
                  ),
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
                  label: const Text(
                    'Aplicar aos semelhantes',
                    style: TextStyle(fontSize: 12),
                  ),
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

class ReviewThumbCard extends StatelessWidget {
  final InspectionReviewEditableCapture item;
  final VoidCallback onTap;

  const ReviewThumbCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = item.status == InspectionReviewPhotoStatus.pending
        ? ReviewVisualStatus.pending
        : item.status == InspectionReviewPhotoStatus.suggested
            ? ReviewVisualStatus.suggested
            : ReviewVisualStatus.ok;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 122,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      child: ReviewCaptureThumbnail(filePath: item.filePath),
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
            ReviewStatusPill(status: status, label: status.shortLabel),
            const SizedBox(height: 4),
            Text(
              item.shortDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewCaptureThumbnail extends StatelessWidget {
  final String filePath;

  const ReviewCaptureThumbnail({super.key, required this.filePath});

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
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image_outlined, size: 28)),
      ),
    );
  }
}

class ReviewEditorDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const ReviewEditorDropdown({
    super.key,
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

class ReviewStatusPill extends StatelessWidget {
  final ReviewVisualStatus status;
  final String label;

  const ReviewStatusPill({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
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

enum ReviewVisualStatus { ok, suggested, pending }

extension ReviewVisualStatusX on ReviewVisualStatus {
  Color get borderColor => this == ReviewVisualStatus.ok
      ? Colors.green
      : this == ReviewVisualStatus.suggested
          ? Colors.amber
          : Colors.orange;
  Color get iconBackground => this == ReviewVisualStatus.ok
      ? Colors.green.shade50
      : this == ReviewVisualStatus.suggested
          ? Colors.amber.shade50
          : Colors.orange.shade50;
  Color get iconColor => this == ReviewVisualStatus.ok
      ? Colors.green.shade700
      : this == ReviewVisualStatus.suggested
          ? Colors.amber.shade800
          : Colors.orange.shade700;
  Color get subtitleColor => this == ReviewVisualStatus.ok
      ? Colors.green.shade700
      : this == ReviewVisualStatus.suggested
          ? Colors.amber.shade800
          : Colors.orange.shade700;
  Color get pillBackground => this == ReviewVisualStatus.ok
      ? Colors.green.shade50
      : this == ReviewVisualStatus.suggested
          ? Colors.amber.shade50
          : Colors.orange.shade50;
  Color get pillBorder => this == ReviewVisualStatus.ok
      ? Colors.green.shade100
      : this == ReviewVisualStatus.suggested
          ? Colors.amber.shade100
          : Colors.orange.shade200;
  Color get pillText => this == ReviewVisualStatus.ok
      ? Colors.green.shade700
      : this == ReviewVisualStatus.suggested
          ? Colors.amber.shade800
          : Colors.orange.shade700;
  IconData get icon => this == ReviewVisualStatus.ok
      ? Icons.check_circle_outline
      : this == ReviewVisualStatus.suggested
          ? Icons.auto_awesome_outlined
          : Icons.warning_amber_rounded;
  String get shortLabel => this == ReviewVisualStatus.ok
      ? 'OK'
      : this == ReviewVisualStatus.suggested
          ? 'Sug.'
          : 'Pend.';

  String label(InspectionReviewNodeGroup group) {
    switch (this) {
      case ReviewVisualStatus.ok:
        return 'OK';
      case ReviewVisualStatus.suggested:
        return 'Revisar';
      case ReviewVisualStatus.pending:
        final source = group.items.firstWhere(
          (item) => item.status == InspectionReviewPhotoStatus.pending,
          orElse: () => group.items.first,
        );
        return source.elemento?.trim().isNotEmpty == true
            ? source.elemento!
            : 'Pendente';
    }
  }

  String subtitle(InspectionReviewNodeGroup group) {
    switch (this) {
      case ReviewVisualStatus.ok:
        return 'Tudo revisado e pronto para finalizar';
      case ReviewVisualStatus.suggested:
        return 'Existem sugestões automáticas para revisar';
      case ReviewVisualStatus.pending:
        final source = group.items.firstWhere(
          (item) => item.status == InspectionReviewPhotoStatus.pending,
          orElse: () => group.items.first,
        );
        return source.elemento?.trim().isNotEmpty == true
            ? source.elemento!
            : 'Classificação incompleta';
    }
  }
}
