import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/observability_logger_service.dart';
import '../services/observability_metrics_service.dart';
import '../widgets/observability_log_list.dart';
import '../widgets/observability_status_card.dart';

class ObservabilitySupportCenterScreen extends StatefulWidget {
  const ObservabilitySupportCenterScreen({super.key});

  @override
  State<ObservabilitySupportCenterScreen> createState() => _ObservabilitySupportCenterScreenState();
}

class _ObservabilitySupportCenterScreenState extends State<ObservabilitySupportCenterScreen> {
  final ObservabilityMetricsService _metrics = const ObservabilityMetricsService();
  final ObservabilityLoggerService _logger = const ObservabilityLoggerService();

  bool _loading = true;
  dynamic _snapshot;
  List<dynamic> _logs = const [];

  @override
  void initState() {
    super.initState();
    _seedAndLoad();
  }

  Future<void> _seedAndLoad() async {
    await _logger.info('sync', 'Monitoramento de sincronizacao disponivel.');
    await _logger.info('voice', 'Monitoramento da camada de voz disponivel.');
    await _logger.info('technical', 'Monitoramento tecnico disponivel.');
    await _logger.info('assistive', 'Monitoramento da camada assistiva disponivel.');
    final snapshot = await _metrics.buildSnapshot();
    final logs = await _metrics.recent();

    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (_loading || _snapshot == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('Observabilidade e suporte', 'Observability and support')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ObservabilityStatusCard(snapshot: _snapshot),
          const SizedBox(height: 12),
          ObservabilityLogList(items: _logs.cast()),
        ],
      ),
    );
  }
}
