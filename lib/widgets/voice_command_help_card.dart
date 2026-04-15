import 'package:flutter/material.dart';

import '../services/voice_command_parser_service.dart';

class VoiceCommandHelpCard extends StatelessWidget {
  final String title;
  final List<VoiceCommandDefinition> commands;

  const VoiceCommandHelpCard({
    super.key,
    required this.title,
    required this.commands,
  });

  @override
  Widget build(BuildContext context) {
    final examples = commands
        .map((command) => command.phrases.isNotEmpty ? command.phrases.first : command.id)
        .take(6)
        .toList();

    return Container(
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: examples.map((example) {
              return Chip(
                label: Text(example),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
