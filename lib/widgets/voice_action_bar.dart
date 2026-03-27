import 'package:flutter/material.dart';

import '../models/voice_usage_entry.dart';
import '../services/voice_command_parser_service.dart';
import '../services/voice_input_service.dart';
import '../services/voice_usage_history_service.dart';
import 'voice_recent_usage_card.dart';

class VoiceActionBar extends StatefulWidget {
  final VoiceInputService voiceService;
  final VoiceCommandParserService parserService;
  final List<VoiceCommandDefinition> commands;
  final Future<void> Function(VoiceCommandMatch match) onCommand;
  final String title;
  final String subtitle;
  final String contextKey;
  final bool showRecentHistory;

  const VoiceActionBar({
    super.key,
    required this.voiceService,
    required this.parserService,
    required this.commands,
    required this.onCommand,
    required this.contextKey,
    this.title = 'Comandos por voz',
    this.subtitle = 'Toque no microfone e fale um comando curto.',
    this.showRecentHistory = true,
  });

  @override
  State<VoiceActionBar> createState() => _VoiceActionBarState();
}

class _VoiceActionBarState extends State<VoiceActionBar> {
  final VoiceUsageHistoryService _historyService = VoiceUsageHistoryService();
  bool _listening = false;
  String? _lastTranscript;
  List<VoiceUsageEntry> _recent = const <VoiceUsageEntry>[];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await _historyService.recentByContext(widget.contextKey);
    if (!mounted) return;
    setState(() => _recent = recent);
  }

  Future<void> _listen() async {
    if (_listening) return;
    setState(() => _listening = true);

    final transcript = await widget.voiceService.listenOnce();

    if (!mounted) return;
    setState(() {
      _listening = false;
      _lastTranscript = transcript;
    });

    if (transcript == null || transcript.trim().isEmpty) return;

    final match = widget.parserService.match(
      transcript: transcript,
      commands: widget.commands,
    );

    await _historyService.add(
      VoiceUsageEntry(
        transcript: transcript,
        context: widget.contextKey,
        createdAt: DateTime.now(),
        matched: match != null,
        commandId: match?.commandId,
      ),
    );
    await _loadRecent();

    if (match == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhum comando reconhecido em: $transcript')),
      );
      return;
    }

    await widget.onCommand(match);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _listen,
                icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                label: Text(_listening ? 'Ouvindo...' : 'Falar comando'),
              ),
              if (_lastTranscript != null && _lastTranscript!.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                  ),
                  child: Text(
                    _lastTranscript!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (widget.showRecentHistory)
            VoiceRecentUsageCard(
              title: 'Uso recente da voz',
              items: _recent,
            ),
        ],
      ),
    );
  }
}
