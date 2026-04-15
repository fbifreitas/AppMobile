import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/voice_command_usage_stat.dart';
import '../models/voice_usage_entry.dart';
import '../services/voice_command_insights_service.dart';
import '../services/voice_command_parser_service.dart';
import '../services/voice_input_service.dart';
import '../services/voice_usage_history_service.dart';
import 'voice_recent_usage_card.dart';
import 'voice_top_commands_card.dart';

class VoiceActionBar extends StatefulWidget {
  final VoiceInputService voiceService;
  final VoiceCommandParserService parserService;
  final List<VoiceCommandDefinition> commands;
  final Future<void> Function(VoiceCommandMatch match) onCommand;
  final String title;
  final String subtitle;
  final String contextKey;
  final bool showRecentHistory;
  final bool showTopCommands;
  final String Function(String commandId)? commandLabelBuilder;

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
    this.showTopCommands = true,
    this.commandLabelBuilder,
  });

  @override
  State<VoiceActionBar> createState() => _VoiceActionBarState();
}

class _VoiceActionBarState extends State<VoiceActionBar> {
  final VoiceUsageHistoryService _historyService = const VoiceUsageHistoryService();
  final VoiceCommandInsightsService _insightsService = const VoiceCommandInsightsService();

  bool _listening = false;
  String? _lastTranscript;
  List<VoiceUsageEntry> _recent = const <VoiceUsageEntry>[];
  Map<String, int> _topCommands = const <String, int>{};

  @override
  void initState() {
    super.initState();
    _loadPanels();
  }

  Future<void> _loadPanels() async {
    final recent = await _historyService.recentByContext(widget.contextKey);
    final top = await _insightsService.commandCountMap(widget.contextKey);

    if (!mounted) return;
    setState(() {
      _recent = recent;
      _topCommands = top;
    });
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
    await _loadPanels();

    if (match == null) {
      if (!mounted) return;
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.tr(
              'Nenhum comando reconhecido em: $transcript',
              'No command recognized in: $transcript',
            ),
          ),
        ),
      );
      return;
    }

    await widget.onCommand(match);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final rankedStats = _topCommands.entries
        .map((item) => VoiceCommandUsageStat(
              context: widget.contextKey,
              commandId: item.key,
              count: item.value,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

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
            strings.tr(widget.title, widget.title),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.tr(widget.subtitle, widget.subtitle),
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
                label: Text(
                  _listening
                      ? strings.tr('Ouvindo...', 'Listening...')
                      : strings.tr('Falar comando', 'Speak command'),
                ),
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
              title: strings.tr('Uso recente da voz', 'Recent voice usage'),
              items: _recent,
            ),
          if (widget.showTopCommands)
            VoiceTopCommandsCard(
              title: strings.tr('Comandos mais usados', 'Most used commands'),
              stats: rankedStats,
              labelBuilder: widget.commandLabelBuilder,
            ),
        ],
      ),
    );
  }
}
