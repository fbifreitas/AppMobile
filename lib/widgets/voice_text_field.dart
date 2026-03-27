import 'package:flutter/material.dart';

import '../services/voice_input_service.dart';

class VoiceTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final int minLines;
  final int maxLines;
  final VoiceInputService voiceService;
  final String localeId;
  final String? helperText;

  const VoiceTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.voiceService,
    this.minLines = 1,
    this.maxLines = 3,
    this.localeId = 'pt_BR',
    this.helperText,
  });

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  bool _isListening = false;

  Future<void> _dictate() async {
    if (_isListening) return;
    setState(() => _isListening = true);

    final text = await widget.voiceService.listenOnce(localeId: widget.localeId);

    if (!mounted) return;
    setState(() => _isListening = false);

    if (text == null || text.trim().isEmpty) return;

    final current = widget.controller.text.trim();
    widget.controller.text = current.isEmpty ? text : '$current $text';
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: widget.helperText,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
        isDense: true,
        suffixIcon: IconButton(
          tooltip: _isListening ? 'Ouvindo...' : 'Preencher por voz',
          onPressed: _dictate,
          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
    );
  }
}
