import 'package:flutter/material.dart';

import 'voice_text_field.dart';
import '../services/voice_input_service.dart';

class TechnicalJustificationCard extends StatelessWidget {
  final TextEditingController controller;
  final VoiceInputService voiceService;
  final ValueChanged<String>? onChanged;

  const TechnicalJustificationCard({
    super.key,
    required this.controller,
    required this.voiceService,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Justificativa técnica',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Preencha a justificativa quando houver pendências técnicas não bloqueantes ou necessidade de contextualização normativa.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          VoiceTextField(
            controller: controller,
            labelText: 'Justificativa técnica',
            minLines: 3,
            maxLines: 5,
            voiceService: voiceService,
            helperText: 'Você pode ditar a justificativa pelo microfone.',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
