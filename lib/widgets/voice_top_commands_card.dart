import 'package:flutter/material.dart';

import '../models/voice_command_usage_stat.dart';

class VoiceTopCommandsCard extends StatelessWidget {
  final String title;
  final List<VoiceCommandUsageStat> stats;
  final String Function(String commandId)? labelBuilder;

  const VoiceTopCommandsCard({
    super.key,
    required this.title,
    required this.stats,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
        ),
        child: Text(
          '$title: ainda não há comandos suficientes para montar o ranking.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          ...stats.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final label = labelBuilder?.call(item.commandId) ?? item.commandId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.blueGrey.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      '${item.count}x',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.blueGrey.shade700,
                      ),
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
