enum ProductionReadinessSeverity { info, warning, blocking }

class ProductionReadinessItem {
  final String id;
  final String title;
  final String description;
  final ProductionReadinessSeverity severity;
  final bool done;

  const ProductionReadinessItem({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.done,
  });

  bool get isBlocking => severity == ProductionReadinessSeverity.blocking && !done;
}
