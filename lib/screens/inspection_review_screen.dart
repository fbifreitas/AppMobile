import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/inspection_state.dart';
import '../models/inspection_session_model.dart';
import '../models/inspection_template_model.dart';
import 'camera_flow_screen.dart';

class InspectionReviewScreen extends StatelessWidget {
  const InspectionReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InspectionState>(
      builder: (context, inspectionState, _) {
        final session = inspectionState.session;

        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('Nenhuma vistoria ativa.')),
          );
        }

        final issues = inspectionState.reviewIssues;
        final blockingIssues = issues.where((item) => item.blocking).toList();
        final nonBlockingIssues = issues.where((item) => !item.blocking).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Revisão da Vistoria'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCard(session: session),
                const SizedBox(height: 20),
                if (blockingIssues.isNotEmpty) ...[
                  Text(
                    'Pendências obrigatórias',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...blockingIssues.map(
                    (issue) => _IssueCard(
                      issue: issue,
                      onEdit: () {
                        inspectionState.selectEnvironment(issue.ambienteId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CameraFlowScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (nonBlockingIssues.isNotEmpty) ...[
                  Text(
                    'Ajustes recomendados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...nonBlockingIssues.map(
                    (issue) => _IssueCard(
                      issue: issue,
                      onEdit: () {
                        inspectionState.selectEnvironment(issue.ambienteId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CameraFlowScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Ambientes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ...session.ambientes.map(
                  (ambiente) => _ReviewEnvironmentCard(
                    ambiente: ambiente,
                    template: session.template.getEnvironmentById(ambiente.ambienteId),
                    onEdit: () {
                      inspectionState.selectEnvironment(ambiente.ambienteId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CameraFlowScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: session.canFinalize
                        ? () {
                            inspectionState.finalizeInspection();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vistoria finalizada com sucesso.'),
                              ),
                            );
                          }
                        : null,
                    child: const Text('Finalizar vistoria'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final InspectionSession session;

  const _SummaryCard({
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (session.progressPercent * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${session.tipoImovel} • ${session.subtipoImovel}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text('Início: ${session.startedAt}'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: percent / 100),
          const SizedBox(height: 8),
          Text('$percent% concluído'),
          const SizedBox(height: 8),
          Text(
            session.gpsEnabled ? 'GPS ativo' : 'GPS desligado',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final ReviewIssue issue;
  final VoidCallback onEdit;

  const _IssueCard({
    required this.issue,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: issue.blocking
              ? theme.colorScheme.error.withOpacity(0.35)
              : theme.dividerColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            issue.blocking ? Icons.error_outline : Icons.info_outline,
            color: issue.blocking ? theme.colorScheme.error : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(issue.description),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }
}

class _ReviewEnvironmentCard extends StatelessWidget {
  final InspectionEnvironmentProgress ambiente;
  final EnvironmentTemplate? template;
  final VoidCallback onEdit;

  const _ReviewEnvironmentCard({
    required this.ambiente,
    required this.template,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final mandatoryElements = template?.elementos
            .where((e) => e.obrigatorioParaConclusao)
            .toList() ??
        const <ElementTemplate>[];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ambiente.ambienteNome,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: const Text('Editar'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${ambiente.totalFotos}/${ambiente.minFotos} foto(s) mínimas'),
          const SizedBox(height: 10),
          if (mandatoryElements.isNotEmpty) ...[
            Text(
              'Elementos obrigatórios',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mandatoryElements.map((element) {
                final covered = ambiente.evidencias.any(
                  (e) => e.elementoId == element.id,
                );

                return Chip(
                  label: Text(element.nome),
                  avatar: Icon(
                    covered ? Icons.check_circle_outline : Icons.pending_outlined,
                    size: 18,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}