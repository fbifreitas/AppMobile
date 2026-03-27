import '../models/voice_command_usage_stat.dart';
import 'voice_usage_history_service.dart';

class VoiceCommandInsightsService {
  final VoiceUsageHistoryService historyService;

  VoiceCommandInsightsService({
    VoiceUsageHistoryService? historyService,
  }) : historyService = historyService ?? VoiceUsageHistoryService();

  Future<List<VoiceCommandUsageStat>> topCommandsByContext(
    String context, {
    int limit = 5,
    bool matchedOnly = true,
  }) async {
    final entries = await historyService.load();

    final filtered = entries.where((entry) {
      if (entry.context != context) return false;
      if (matchedOnly && !entry.matched) return false;
      return entry.commandId != null && entry.commandId!.trim().isNotEmpty;
    });

    final counts = <String, int>{};
    for (final entry in filtered) {
      final commandId = entry.commandId!;
      counts.update(commandId, (value) => value + 1, ifAbsent: () => 1);
    }

    final result = counts.entries
        .map((item) => VoiceCommandUsageStat(
              context: context,
              commandId: item.key,
              count: item.value,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return result.take(limit).toList();
  }

  Future<Map<String, int>> commandCountMap(String context) async {
    final stats = await topCommandsByContext(context, limit: 50);
    return {for (final item in stats) item.commandId: item.count};
  }
}
