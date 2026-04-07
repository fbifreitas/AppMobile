import '../models/assistive_suggestion.dart';
import 'assistive_learning_store_service.dart';
import 'voice_command_insights_service.dart';

class AssistiveSuggestionEngine {
  final AssistiveLearningStoreService learningStore;
  final VoiceCommandInsightsService commandInsights;

  const AssistiveSuggestionEngine({
    this.learningStore = const AssistiveLearningStoreService(),
    this.commandInsights = const VoiceCommandInsightsService(),
  });

  Future<List<AssistiveSuggestion>> buildForContext(String context) async {
    final suggestions = <AssistiveSuggestion>[];

    final topCommands = await commandInsights.topCommandsByContext(context, limit: 3);
    for (final item in topCommands) {
      suggestions.add(
        AssistiveSuggestion(
          id: 'cmd_${item.commandId}',
          context: context,
          title: 'Comando frequente',
          description: 'O comando ${item.commandId} foi usado ${item.count} vez(es) neste contexto.',
          commandId: item.commandId,
          score: item.count.toDouble(),
          source: 'voice_history',
        ),
      );
    }

    final preferredSubtype = await learningStore.aggregate(
      context,
      'target_item',
    );
    final fallbackSubtype =
        preferredSubtype.isEmpty
            ? await learningStore.aggregate(context, 'subtipo')
            : const <String, int>{};
    final sortedSubtype = (preferredSubtype.isEmpty
            ? fallbackSubtype
            : preferredSubtype)
        .entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedSubtype.isNotEmpty) {
      final top = sortedSubtype.first;
      suggestions.add(
        AssistiveSuggestion(
          id: 'target_item_${top.key}',
          context: context,
          title: 'Subtipo sugerido',
          description: 'O subtipo ${top.key} aparece com maior frequência neste contexto.',
          score: top.value.toDouble(),
          source: 'learning_store',
        ),
      );
    }

    final preferredElemento = await learningStore.aggregate(
      context,
      'target_qualifier',
    );
    final fallbackElemento =
        preferredElemento.isEmpty
            ? await learningStore.aggregate(context, 'elemento')
            : const <String, int>{};
    final sortedElemento = (preferredElemento.isEmpty
            ? fallbackElemento
            : preferredElemento)
        .entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedElemento.isNotEmpty) {
      final top = sortedElemento.first;
      suggestions.add(
        AssistiveSuggestion(
          id: 'target_qualifier_${top.key}',
          context: context,
          title: 'Elemento sugerido',
          description: 'O elemento ${top.key} é o mais recorrente neste contexto.',
          score: top.value.toDouble(),
          source: 'learning_store',
        ),
      );
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(6).toList();
  }
}
