import 'package:flutter/material.dart';

import '../models/remote_config_item.dart';

class RemoteConfigListCard extends StatelessWidget {
  final List<RemoteConfigItem> items;

  const RemoteConfigListCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
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
            'Catálogo de configuração remota',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(item.description, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('Chave: ${item.key}', style: const TextStyle(fontSize: 11)),
                  Text('Valor: ${item.value}', style: const TextStyle(fontSize: 11)),
                  Text('Categoria: ${item.category}', style: const TextStyle(fontSize: 11)),
                  Text(
                    item.editable ? 'Editável' : 'Somente leitura',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: item.editable ? Colors.green.shade700 : Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
