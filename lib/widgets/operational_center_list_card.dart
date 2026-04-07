import 'package:flutter/material.dart';

import '../models/operational_center_entry.dart';
import 'unified_section_card.dart';

class OperationalCenterListCard extends StatelessWidget {
  final List<OperationalCenterEntry> items;

  const OperationalCenterListCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedSectionCard(
      title: 'Centrais operacionais mapeadas',
      subtitle: 'Base para integração operacional final e navegação unificada.',
      child: Column(
        children: items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.enabled ? Icons.hub_outlined : Icons.block_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(item.description, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('Rota: ${item.routeName}', style: const TextStyle(fontSize: 11)),
                      Text('Categoria: ${item.category}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
