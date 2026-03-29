import '../models/operational_hub_item.dart';

class OperationalHubRegistryService {
  const OperationalHubRegistryService();

  List<OperationalHubItem> items() {
    return const <OperationalHubItem>[
      OperationalHubItem(
        id: 'checkin',
        title: 'Check-in',
        description: 'Abrir o fluxo principal da vistoria.',
        category: 'Fluxo',
        iconKey: 'task',
        highlighted: true,
      ),
      OperationalHubItem(
        id: 'field_ops',
        title: 'Operação de campo',
        description: 'Monitorar fila, conflito e sincronização.',
        category: 'Operação',
        iconKey: 'sync',
      ),
      OperationalHubItem(
        id: 'assistive',
        title: 'IA assistiva',
        description: 'Acessar sugestões, aprendizado e apoio automático.',
        category: 'Assistiva',
        iconKey: 'spark',
      ),
      OperationalHubItem(
        id: 'quality',
        title: 'Qualidade',
        description: 'Verificar checks de estabilidade e promoção.',
        category: 'Qualidade',
        iconKey: 'shield',
      ),
      OperationalHubItem(
        id: 'observability',
        title: 'Observabilidade',
        description: 'Inspecionar logs e métricas locais.',
        category: 'Suporte',
        iconKey: 'chart',
      ),
      OperationalHubItem(
        id: 'governance',
        title: 'Governança',
        description: 'Revisar retenção, limpeza e itens sensíveis.',
        category: 'Governança',
        iconKey: 'lock',
      ),
      OperationalHubItem(
        id: 'production',
        title: 'Prontidão para produção',
        description: 'Conferir checklist final de release.',
        category: 'Release',
        iconKey: 'rocket',
      ),
      OperationalHubItem(
        id: 'admin',
        title: 'Administração',
        description: 'Acessar catálogo administrativo e configuração remota.',
        category: 'Admin',
        iconKey: 'admin',
      ),
      OperationalHubItem(
        id: 'clean_code',
        title: 'Auditoria de clean code',
        description: 'Revisar achados técnicos estruturais do projeto.',
        category: 'Qualidade',
        iconKey: 'code',
      ),
      OperationalHubItem(
        id: 'export',
        title: 'Saída operacional',
        description: 'Gerar snapshot operacional consolidado.',
        category: 'Release',
        iconKey: 'export',
        highlighted: true,
      ),
      OperationalHubItem(
        id: 'mock_data',
        title: 'Painel de dados mock',
        description: 'Gerenciar cenários de vistoria para QA e homologação.',
        category: 'Dev',
        iconKey: 'admin',
        highlighted: true,
      ),
    ];
  }
}
