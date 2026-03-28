import '../models/go_live_check_item.dart';
import '../models/go_live_summary.dart';

class GoLiveChecklistService {
  const GoLiveChecklistService();

  GoLiveSummary build({
    required bool analyzeOk,
    required bool testsOk,
    required bool mainFlowOk,
    required bool syncFlowOk,
    required bool voiceFlowOk,
    required bool technicalFlowOk,
    required bool platformReady,
    required bool accessibilityReviewed,
  }) {
    final items = <GoLiveCheckItem>[
      GoLiveCheckItem(
        id: 'analyze',
        title: 'Analyzer sem erros',
        description: analyzeOk
            ? 'O projeto está sem erros no flutter analyze.'
            : 'Ainda existem erros no flutter analyze.',
        severity: GoLiveCheckSeverity.blocking,
        done: analyzeOk,
      ),
      GoLiveCheckItem(
        id: 'tests',
        title: 'Testes básicos executados',
        description: testsOk
            ? 'Os testes básicos executaram com sucesso.'
            : 'Os testes básicos ainda não foram executados com sucesso.',
        severity: GoLiveCheckSeverity.blocking,
        done: testsOk,
      ),
      GoLiveCheckItem(
        id: 'main_flow',
        title: 'Fluxo principal validado',
        description: mainFlowOk
            ? 'Check-in, câmera e revisão final foram validados.'
            : 'O fluxo principal ainda não foi validado integralmente.',
        severity: GoLiveCheckSeverity.blocking,
        done: mainFlowOk,
      ),
      GoLiveCheckItem(
        id: 'sync_flow',
        title: 'Operação de campo validada',
        description: syncFlowOk
            ? 'Fila, retry e monitoramento operacional foram validados.'
            : 'A operação de campo ainda não foi validada integralmente.',
        severity: GoLiveCheckSeverity.warning,
        done: syncFlowOk,
      ),
      GoLiveCheckItem(
        id: 'voice_flow',
        title: 'Camada de voz validada',
        description: voiceFlowOk
            ? 'Entrada por voz, comandos e histórico foram validados.'
            : 'A camada de voz ainda não foi validada integralmente.',
        severity: GoLiveCheckSeverity.warning,
        done: voiceFlowOk,
      ),
      GoLiveCheckItem(
        id: 'technical_flow',
        title: 'Camada técnica/NBR validada',
        description: technicalFlowOk
            ? 'Resumo técnico, pendências e justificativas foram validados.'
            : 'A camada técnica ainda não foi validada integralmente.',
        severity: GoLiveCheckSeverity.warning,
        done: technicalFlowOk,
      ),
      GoLiveCheckItem(
        id: 'platform',
        title: 'Plataformas e permissões revisadas',
        description: platformReady
            ? 'Android/iOS e identidade de release foram revisados.'
            : 'Plataformas e permissões ainda precisam de revisão final.',
        severity: GoLiveCheckSeverity.warning,
        done: platformReady,
      ),
      GoLiveCheckItem(
        id: 'accessibility',
        title: 'Acessibilidade básica revisada',
        description: accessibilityReviewed
            ? 'Componentes críticos receberam revisão básica de acessibilidade.'
            : 'A revisão básica de acessibilidade ainda não foi concluída.',
        severity: GoLiveCheckSeverity.info,
        done: accessibilityReviewed,
      ),
    ];

    return GoLiveSummary(items: items);
  }
}
