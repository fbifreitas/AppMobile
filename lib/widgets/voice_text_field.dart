import 'package:flutter/material.dart';

import '../services/voice_input_service.dart';

class VoiceTextField extends StatefulWidget {
  final TextEditingController controller;
  final VoiceInputService voiceService;
  final String labelText;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onTranscriptAccepted;

  const VoiceTextField({
    super.key,
    required this.controller,
    required this.voiceService,
    required this.labelText,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.onTranscriptAccepted,
  });

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  bool _busy = false;

  Future<void> _handleVoiceInput() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final text = await widget.voiceService.listenOnce();
      if (!mounted) return;
      if (text == null || text.isEmpty) return;

      final current = widget.controller.text.trim();
      widget.controller.text = current.isEmpty ? text : '$current $text';
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
      widget.onTranscriptAccepted?.call(text);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
        isDense: true,
        suffixIcon: IconButton(
          tooltip: _busy ? 'Ouvindo...' : 'Ditado por voz',
          onPressed: _busy ? null : _handleVoiceInput,
          icon: Icon(_busy ? Icons.mic : Icons.mic_none_outlined),
        ),
      ),
    );
  }
}
