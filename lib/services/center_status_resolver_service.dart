import '../models/center_status_item.dart';

class CenterStatusResolverService {
  const CenterStatusResolverService();

  List<CenterStatusItem> build() {
    return const <CenterStatusItem>[
      CenterStatusItem(
        id: 'field_ops',
        title: 'Operação de campo',
        status: 'Integrada',
        available: true,
        description: 'Fila, retry, conflito e retomada disponíveis.',
      ),
      CenterStatusItem(
        id: 'assistive',
        title: 'IA assistiva',
        status: 'Integrada',
        available: true,
        description: 'Sugestões, aprendizado e central assistiva disponíveis.',
      ),
      CenterStatusItem(
        id: 'quality',
        title: 'Qualidade',
        status: 'Integrada',
        available: true,
        description: 'Gate de qualidade e estabilidade disponíveis.',
      ),
      CenterStatusItem(
        id: 'observability',
        title: 'Observabilidade',
        status: 'Integrada',
        available: true,
        description: 'Logs e métricas locais disponíveis.',
      ),
      CenterStatusItem(
        id: 'governance',
        title: 'Governança',
        status: 'Integrada',
        available: true,
        description: 'Retenção, limpeza e itens sensíveis disponíveis.',
      ),
      CenterStatusItem(
        id: 'production',
        title: 'Produção',
        status: 'Integrada',
        available: true,
        description: 'Checklist e prontidão de release disponíveis.',
      ),
      CenterStatusItem(
        id: 'admin',
        title: 'Administração',
        status: 'Integrada',
        available: true,
        description: 'Catálogo administrativo e configuração remota disponíveis.',
      ),
    ];
  }
}
