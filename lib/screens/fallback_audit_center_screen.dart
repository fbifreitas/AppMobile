import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fallback_audit_report.dart';
import '../services/inspection_fallback_audit_service.dart';
import '../state/app_state.dart';

class FallbackAuditCenterScreen extends StatefulWidget {
  const FallbackAuditCenterScreen({super.key});

  @override
  State<FallbackAuditCenterScreen> createState() => _FallbackAuditCenterScreenState();
}

class _FallbackAuditCenterScreenState extends State<FallbackAuditCenterScreen> {
  final InspectionFallbackAuditService _service =
      const InspectionFallbackAuditService();

  late FallbackAuditReport _report;

  @override
  void initState() {
    super.initState();
    _report = _service.build(
      draft: context.read<AppState>().inspectionRecoveryDraft,
    );
  }

  void _refresh() {
    setState(() {
      _report = _service.build(
        draft: context.read<AppState>().inspectionRecoveryDraft,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria de fallback'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar relatorio',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(report: _report),
          const SizedBox(height: 12),
          ..._report.checks.map(
            (check) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CheckCard(check: check),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final FallbackAuditReport report;

  @override
  Widget build(BuildContext context) {
    final statusColor = report.isHealthy ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.isHealthy
                ? 'Fluxo de fallback consistente'
                : 'Foram encontradas pendencias no fallback',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text('Etapa atual: ${report.stageLabel} (${report.stageKey})'),
          Text('Rota atual: ${report.routeName}'),
          const SizedBox(height: 6),
          Text('Checks: ${report.totalChecks} | Falhas: ${report.failedChecks} | Alertas: ${report.warningChecks}'),
          const SizedBox(height: 6),
          Text(
            'Gerado em: ${report.generatedAtIso}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({required this.check});

  final FallbackAuditCheck check;

  @override
  Widget build(BuildContext context) {
    final icon = check.passed
        ? Icons.check_circle_outline
        : (check.warning ? Icons.warning_amber_outlined : Icons.error_outline);
    final color = check.passed
        ? Colors.green
        : (check.warning ? Colors.orange : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text('Etapa: ${check.stage}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(check.detail, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
