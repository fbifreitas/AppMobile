import 'package:flutter/foundation.dart';

class VoiceCommandMatch {
  final String commandId;
  final String transcript;
  final double score;
  final Map<String, String> entities;

  const VoiceCommandMatch({
    required this.commandId,
    required this.transcript,
    required this.score,
    this.entities = const {},
  });
}

class VoiceCommandDefinition {
  final String id;
  final List<String> phrases;
  final Map<String, List<String>> entities;

  const VoiceCommandDefinition({
    required this.id,
    required this.phrases,
    this.entities = const {},
  });
}

class VoiceCommandParserService {
  String _normalize(String input) {
    const from = 'áàãâäéèêëíìîïóòõôöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    var result = input.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result.trim();
  }

  VoiceCommandMatch? match({
    required String transcript,
    required List<VoiceCommandDefinition> commands,
  }) {
    final normalizedTranscript = _normalize(transcript);
    VoiceCommandMatch? best;

    for (final command in commands) {
      for (final phrase in command.phrases) {
        final normalizedPhrase = _normalize(phrase);
        if (!normalizedTranscript.contains(normalizedPhrase)) continue;

        final entities = <String, String>{};
        var entityScore = 0.0;

        command.entities.forEach((key, values) {
          for (final value in values) {
            final normalizedValue = _normalize(value);
            if (normalizedTranscript.contains(normalizedValue)) {
              entities[key] = value;
              entityScore += 0.2;
              break;
            }
          }
        });

        final score = 1.0 + entityScore;
        final current = VoiceCommandMatch(
          commandId: command.id,
          transcript: transcript,
          score: score,
          entities: entities,
        );

        if (best == null || current.score > best.score) {
          best = current;
        }
      }
    }

    if (best != null) {
      debugPrint('voice_command_match: ${best.commandId} score=${best.score}');
    }

    return best;
  }
}
