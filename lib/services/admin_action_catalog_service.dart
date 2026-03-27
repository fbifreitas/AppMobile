import '../models/admin_action_item.dart';

class AdminActionCatalogService {
  const AdminActionCatalogService();

  List<AdminActionItem> items() {
    return const <AdminActionItem>[
      AdminActionItem(
        id: 'rebuild_local_indexes',
        title: 'Reconstruir índices locais',
        description: 'Reprocessa catálogos locais de apoio ao fluxo.',
        category: 'Manutenção',
        available: true,
      ),
      AdminActionItem(
        id: 'clear_assistive_learning',
        title: 'Limpar aprendizado assistivo',
        description: 'Remove eventos de aprendizado local da IA assistiva.',
        category: 'IA assistiva',
        available: true,
      ),
      AdminActionItem(
        id: 'clear_observability_logs',
        title: 'Limpar logs locais',
        description: 'Remove o histórico local de observabilidade.',
        category: 'Observabilidade',
        available: true,
      ),
      AdminActionItem(
        id: 'export_operational_snapshot',
        title: 'Exportar snapshot operacional',
        description: 'Prepara um resumo interno de operação para suporte.',
        category: 'Suporte',
        available: true,
      ),
      AdminActionItem(
        id: 'refresh_remote_config',
        title: 'Atualizar configuração remota',
        description: 'Placeholder para atualização futura de parâmetros remotos.',
        category: 'Configuração remota',
        available: true,
      ),
    ];
  }
}
