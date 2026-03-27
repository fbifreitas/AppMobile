import '../models/data_retention_policy.dart';

class DataRetentionPolicyService {
  const DataRetentionPolicyService();

  List<DataRetentionPolicy> defaultPolicies() {
    return const <DataRetentionPolicy>[
      DataRetentionPolicy(
        scope: DataRetentionScope.voiceHistory,
        maxEntries: 50,
        maxAgeDays: 30,
        sensitive: true,
        description: 'Histórico de voz deve ser mantido com retenção curta.',
      ),
      DataRetentionPolicy(
        scope: DataRetentionScope.observabilityLogs,
        maxEntries: 300,
        maxAgeDays: 30,
        sensitive: false,
        description: 'Logs locais devem ser limitados para evitar crescimento indefinido.',
      ),
      DataRetentionPolicy(
        scope: DataRetentionScope.syncQueue,
        maxEntries: 500,
        maxAgeDays: 90,
        sensitive: true,
        description: 'Fila de sincronização deve permanecer disponível até envio seguro.',
      ),
      DataRetentionPolicy(
        scope: DataRetentionScope.resumeState,
        maxEntries: 100,
        maxAgeDays: 15,
        sensitive: true,
        description: 'Estados de retomada devem expirar automaticamente.',
      ),
      DataRetentionPolicy(
        scope: DataRetentionScope.assistiveLearning,
        maxEntries: 200,
        maxAgeDays: 45,
        sensitive: true,
        description: 'Aprendizado local deve ser mantido com janela limitada.',
      ),
    ];
  }
}
