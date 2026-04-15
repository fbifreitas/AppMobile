import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/voice_input_service.dart';

class VoiceIconButton extends StatefulWidget {
  final VoiceInputService voiceService;
  final Future<void> Function(String transcript) onTranscribed;
  final String localeId;
  final String tooltip;
  final IconData icon;
  final Duration listenFor;
  final Duration pauseFor;

  const VoiceIconButton({
    super.key,
    required this.voiceService,
    required this.onTranscribed,
    this.localeId = 'pt_BR',
    this.tooltip = 'Preencher por voz',
    this.icon = Icons.mic_none,
    this.listenFor = const Duration(seconds: 20),
    this.pauseFor = const Duration(seconds: 4),
  });

  @override
  State<VoiceIconButton> createState() => _VoiceIconButtonState();
}

class _VoiceIconButtonState extends State<VoiceIconButton> {
  bool _isListening = false;

  Future<void> _start() async {
    if (_isListening) return;
    setState(() => _isListening = true);

    final text = await widget.voiceService.listenOnce(
      localeId: widget.localeId,
      listenFor: widget.listenFor,
      pauseFor: widget.pauseFor,
    );

    if (!mounted) return;
    setState(() => _isListening = false);

    if (text == null || text.trim().isEmpty) return;
    await widget.onTranscribed(text);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return IconButton(
      tooltip: _isListening ? strings.tr('Ouvindo...', 'Listening...') : strings.tr(widget.tooltip, widget.tooltip),
      onPressed: _start,
      icon: Icon(_isListening ? Icons.mic : widget.icon),
    );
  }
}
