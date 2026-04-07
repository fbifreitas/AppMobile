import 'package:flutter/material.dart';

import '../models/center_status_item.dart';

class AppStatusOverviewCard extends StatelessWidget {
  final List<CenterStatusItem> items;

  const AppStatusOverviewCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
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
            'Visão geral da integração',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$available de ${items.length} centrais principais estão disponíveis.',
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
