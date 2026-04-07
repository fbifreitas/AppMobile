import 'package:flutter/material.dart';

import '../models/production_readiness_item.dart';

class ProductionReadinessList extends StatelessWidget {
  final List<ProductionReadinessItem> items;

  const ProductionReadinessList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final color = item.severity == ProductionReadinessSeverity.blocking
            ? Colors.orange
            : item.severity == ProductionReadinessSeverity.warning
                ? Colors.blueGrey
                : Colors.green;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.20)),
            color: color.withValues(alpha: 0.05),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.done ? Icons.check_circle_outline : Icons.warning_amber_rounded,
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
                    Text(item.description, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
