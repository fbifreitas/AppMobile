import '../models/remote_config_item.dart';

class RemoteConfigCatalogService {
  const RemoteConfigCatalogService();

  List<RemoteConfigItem> items() {
    return const <RemoteConfigItem>[
      RemoteConfigItem(
        key: 'inspection.minimum_photos_enabled',
        title: 'Cobertura mínima habilitada',
        value: 'true',
        category: 'Regras técnicas',
        editable: true,
        description: 'Controla a ativação da validação de cobertura mínima por subtipo.',
      ),
      RemoteConfigItem(
        key: 'voice.command_bar_enabled',
        title: 'Barra de comandos por voz',
        value: 'true',
        category: 'Voz',
        editable: true,
        description: 'Controla a exibição da barra de comandos por voz nas telas suportadas.',
      ),
      RemoteConfigItem(
        key: 'field.sync.auto_retry',
        title: 'Retry automático de sync',
        value: 'true',
        category: 'Operação de campo',
        editable: true,
        description: 'Controla a tentativa automática de novo envio em falhas operacionais.',
      ),
      RemoteConfigItem(
        key: 'assistive.suggestions_enabled',
        title: 'Sugestões assistivas habilitadas',
        value: 'true',
        category: 'IA assistiva',
        editable: true,
        description: 'Controla a exibição das sugestões contextuais assistivas.',
      ),
      RemoteConfigItem(
        key: 'observability.local_logs_enabled',
        title: 'Logs locais habilitados',
        value: 'true',
        category: 'Observabilidade',
        editable: false,
        description: 'Define se o armazenamento local de logs operacionais está ativo.',
      ),
    ];
  }
}
