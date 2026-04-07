import 'package:flutter/material.dart';

import '../services/assistive_review_helper_service.dart';
import '../services/assistive_suggestion_engine.dart';
import '../services/assistive_visual_classification_placeholder_service.dart';
import '../widgets/assistive_review_help_card.dart';
import '../widgets/assistive_suggestion_card.dart';
import '../models/assistive_suggestion.dart';

class AssistiveIntelligenceCenterScreen extends StatefulWidget {
  const AssistiveIntelligenceCenterScreen({super.key});

  @override
  State<AssistiveIntelligenceCenterScreen> createState() => _AssistiveIntelligenceCenterScreenState();
}

class _AssistiveIntelligenceCenterScreenState extends State<AssistiveIntelligenceCenterScreen> {
  final AssistiveSuggestionEngine _engine = const AssistiveSuggestionEngine();
  final AssistiveReviewHelperService _reviewHelper = const AssistiveReviewHelperService();
  final AssistiveVisualClassificationPlaceholderService _visualPlaceholder =
      const AssistiveVisualClassificationPlaceholderService();

  bool _loading = true;
  List<String> _hints = const <String>[];
  Map<String, dynamic> _groups = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reviewSuggestions = await _engine.buildForContext('review');
    final cameraSuggestions = await _engine.buildForContext('camera');
    final checkinSuggestions = await _engine.buildForContext('checkin_step1');

    final hints = _reviewHelper.buildReviewHints(
      totalFotos: 0,
      totalPendencias: 0,
      totalBloqueiosTecnicos: 0,
      totalJustificativasPendentes: 0,
    );

    if (!mounted) return;
    setState(() {
      _groups = <String, dynamic>{
        'review': reviewSuggestions,
        'camera': cameraSuggestions,
        'checkin': checkinSuggestions,
      };
      _hints = hints;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
      final reviewSuggestions = List<AssistiveSuggestion>.from(
        _groups['review'] as List? ?? const [],
      );

      final cameraSuggestions = List<AssistiveSuggestion>.from(
        _groups['camera'] as List? ?? const [],
      );

      final checkinSuggestions = List<AssistiveSuggestion>.from(
        _groups['checkin'] as List? ?? const [],
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de IA assistiva'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AssistiveReviewHelpCard(
                  title: 'Ajuda automática de revisão',
                  hints: _hints,
                ),
                const SizedBox(height: 12),
                AssistiveSuggestionCard(
                  title: 'Sugestões para revisão final',
                  suggestions: reviewSuggestions,
                ),
                const SizedBox(height: 12),
                AssistiveSuggestionCard(
                  title: 'Sugestões para câmera',
                  suggestions: cameraSuggestions,
                ),
                const SizedBox(height: 12),
                AssistiveSuggestionCard(
                  title: 'Sugestões para check-in',
                  suggestions: checkinSuggestions,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
                  ),
                  child: Text(_visualPlaceholder.statusMessage),
                ),
              ],
            ),
    );
  }
}
