import '../models/operational_center_entry.dart';

class OperationalCenterRegistryService {
  const OperationalCenterRegistryService();

  List<OperationalCenterEntry> entries() {
    return const <OperationalCenterEntry>[
      OperationalCenterEntry(
        id: 'field_ops',
        title: 'Operação de campo',
        description: 'Fila, retomada, sincronização e resiliência operacional.',
        routeName: '/field-operations',
        category: 'Operação',
        enabled: true,
      ),
      OperationalCenterEntry(
        id: 'assistive',
        title: 'IA assistiva',
        description: 'Sugestões contextuais e aprendizado local.',
        routeName: '/assistive-center',
        category: 'Assistiva',
        enabled: true,
      ),
      OperationalCenterEntry(
        id: 'quality',
        title: 'Qualidade e estabilidade',
        description: 'Gate de qualidade e checks de promoção.',
        routeName: '/quality-center',
        category: 'Qualidade',
        enabled: true,
      ),
      OperationalCenterEntry(
        id: 'observability',
        title: 'Observabilidade e suporte',
        description: 'Logs locais, métricas e apoio ao diagnóstico.',
        routeName: '/observability-center',
        category: 'Suporte',
        enabled: true,
      ),
      OperationalCenterEntry(
        id: 'governance',
        title: 'Governança local',
        description: 'Retenção, limpeza e governança de dados locais.',
        routeName: '/governance-center',
        category: 'Governança',
        enabled: true,
      ),
      OperationalCenterEntry(
        id: 'production',
        title: 'Produção e saída operacional',
        description: 'Prontidão para produção e checklist de saída.',
        routeName: '/production-readiness',
        category: 'Produção',
        enabled: true,
      ),
      OperationalCenterEntry(
        id: 'admin',
        title: 'Administração e config remota',
        description: 'Catálogo administrativo e parâmetros remotos.',
        routeName: '/admin-remote-config',
        category: 'Administração',
        enabled: true,
      ),
    ];
  }
}
