import 'production_readiness_item.dart';

class ProductionReadinessSummary {
  final List<ProductionReadinessItem> items;

  const ProductionReadinessSummary({
    required this.items,
  });

  int get total => items.length;
  int get doneCount => items.where((item) => item.done).length;
  int get pendingCount => items.where((item) => !item.done).length;
  int get blockingCount => items.where((item) => item.isBlocking).length;

  bool get readyForProduction => blockingCount == 0;
}
