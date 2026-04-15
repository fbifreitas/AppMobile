import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/voice_input_service.dart';
import 'voice_text_field.dart';

class TechnicalJustificationCard extends StatelessWidget {
  final TextEditingController controller;
  final VoiceInputService voiceService;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const TechnicalJustificationCard({
    super.key,
    required this.controller,
    required this.voiceService,
    this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr('Anotacao do vistoriador', 'Inspector note'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              'Ha itens com pendencias que nao impedem a conclusao. Anote aqui o que for necessario para registro.',
              'There are pending items that do not prevent completion. Record here what is necessary for documentation.',
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          VoiceTextField(
            controller: controller,
            labelText: strings.tr('Anotacao do vistoriador', 'Inspector note'),
            minLines: 3,
            maxLines: 5,
            voiceService: voiceService,
            helperText: strings.tr(
              'Voce pode ditar a anotacao pelo microfone.',
              'You can dictate the note using the microphone.',
            ),
            onChanged: onChanged,
            focusNode: focusNode,
          ),
        ],
      ),
    );
  }
}
