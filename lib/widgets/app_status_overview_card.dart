import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/center_status_item.dart';

class AppStatusOverviewCard extends StatelessWidget {
  final List<CenterStatusItem> items;

  const AppStatusOverviewCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final available = items.where((item) => item.available).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr('Visao geral da integracao', 'Integration overview'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              '$available de ${items.length} centrais principais estao disponiveis.',
              '$available of ${items.length} main centers are available.',
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    item.available ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.title}: ${item.status}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
