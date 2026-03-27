import 'package:flutter/material.dart';

import '../models/stability_check_result.dart';

class StabilityCheckCard extends StatelessWidget {
  final StabilityCheckResult item;

  const StabilityCheckCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.severity == StabilityCheckSeverity.blocking
        ? Colors.orange
        : item.severity == StabilityCheckSeverity.warning
            ? Colors.blueGrey
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        color: color.withValues(alpha: 0.06),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.passed ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
