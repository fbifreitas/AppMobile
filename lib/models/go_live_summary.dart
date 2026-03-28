import 'go_live_check_item.dart';

class GoLiveSummary {
  final List<GoLiveCheckItem> items;

  const GoLiveSummary({
    required this.items,
  });

  int get total => items.length;
  int get doneCount => items.where((item) => item.done).length;
  int get pendingCount => items.where((item) => !item.done).length;
  int get blockingCount => items.where((item) => item.isBlocking).length;

  bool get ready => blockingCount == 0;
}
