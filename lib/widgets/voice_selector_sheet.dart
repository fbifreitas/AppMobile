import 'package:flutter/material.dart';

import '../services/voice_input_service.dart';

class VoiceSelectorSheet extends StatefulWidget {
  final VoiceInputService voiceService;
  final List<String> options;
  final String title;
  final String? currentValue;
  final String localeId;

  const VoiceSelectorSheet({
    super.key,
    required this.voiceService,
    required this.options,
    required this.title,
    this.currentValue,
    this.localeId = 'pt_BR',
  });

  static Future<String?> open(
    BuildContext context, {
    required VoiceInputService voiceService,
    required List<String> options,
    required String title,
    String? currentValue,
    String localeId = 'pt_BR',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => VoiceSelectorSheet(
        voiceService: voiceService,
        options: options,
        title: title,
        currentValue: currentValue,
        localeId: localeId,
      ),
    );
  }

  @override
  State<VoiceSelectorSheet> createState() => _VoiceSelectorSheetState();
}

class _VoiceSelectorSheetState extends State<VoiceSelectorSheet> {
  bool _isListening = false;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentValue;
  }

  String _normalize(String input) {
    const from = 'áàãâäéèêëíìîïóòõôöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    var result = input.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  Future<void> _listen() async {
    if (_isListening) return;
    setState(() => _isListening = true);

    final transcript = await widget.voiceService.listenOnce(
      localeId: widget.localeId,
    );

    if (!mounted) return;
    setState(() => _isListening = false);

    if (transcript == null || transcript.trim().isEmpty) return;

    final normalized = _normalize(transcript);
    for (final option in widget.options) {
      if (normalized.contains(_normalize(option))) {
        setState(() => _selected = option);
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nenhuma opção compatível encontrada em: $transcript')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: _isListening ? 'Ouvindo...' : 'Selecionar por voz',
                  onPressed: _listen,
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                ),
              ],
            ),
            Flexible(
              child: RadioGroup<String>(
                groupValue: _selected,
                onChanged: (value) {
                  setState(() => _selected = value);
                },
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    return RadioListTile<String>(
                      value: option,
                      title: Text(option),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
