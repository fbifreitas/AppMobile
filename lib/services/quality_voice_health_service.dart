import '../models/stability_check_result.dart';

class QualityVoiceHealthService {
  const QualityVoiceHealthService();

  List<StabilityCheckResult> build({
    required bool voiceServiceAvailable,
    required bool commandBarAvailable,
    required bool recentHistoryAvailable,
    required bool rankingAvailable,
  }) {
    return <StabilityCheckResult>[
      StabilityCheckResult(
        id: 'voice_service',
        title: 'Base de voz disponível',
        description: voiceServiceAvailable
            ? 'O serviço de entrada por voz está presente.'
            : 'O serviço de entrada por voz não foi localizado.',
        severity: StabilityCheckSeverity.blocking,
        passed: voiceServiceAvailable,
        category: 'voice',
      ),
      StabilityCheckResult(
        id: 'voice_action_bar',
        title: 'Barra de comandos por voz disponível',
        description: commandBarAvailable
            ? 'A barra de comandos por voz está pronta para uso.'
            : 'A barra de comandos por voz não está disponível.',
        severity: StabilityCheckSeverity.warning,
        passed: commandBarAvailable,
        category: 'voice',
      ),
      StabilityCheckResult(
        id: 'voice_history',
        title: 'Histórico recente da voz disponível',
        description: recentHistoryAvailable
            ? 'O histórico recente da voz está ativo.'
            : 'O histórico recente da voz não foi encontrado.',
        severity: StabilityCheckSeverity.warning,
        passed: recentHistoryAvailable,
        category: 'voice',
      ),
      StabilityCheckResult(
        id: 'voice_ranking',
        title: 'Ranking de comandos disponível',
        description: rankingAvailable
            ? 'O ranking de comandos por contexto está ativo.'
            : 'O ranking de comandos por contexto não foi encontrado.',
        severity: StabilityCheckSeverity.info,
        passed: rankingAvailable,
        category: 'voice',
      ),
    ];
  }
}
