import 'voice_command_parser_service.dart';

class VoiceCommandCatalogService {
  const VoiceCommandCatalogService();

  List<VoiceCommandDefinition> checkinStep1Commands() {
    return const [
      VoiceCommandDefinition(
        id: 'cliente_presente_sim',
        phrases: ['cliente presente', 'cliente esta presente', 'sim'],
      ),
      VoiceCommandDefinition(
        id: 'cliente_presente_nao',
        phrases: ['cliente ausente', 'cliente nao esta presente', 'nao'],
      ),
      VoiceCommandDefinition(
        id: 'tipo_urbano',
        phrases: ['tipo urbano', 'imovel urbano', 'urbano'],
      ),
      VoiceCommandDefinition(
        id: 'tipo_rural',
        phrases: ['tipo rural', 'imovel rural', 'rural'],
      ),
      VoiceCommandDefinition(
        id: 'tipo_comercial',
        phrases: ['tipo comercial', 'imovel comercial', 'comercial'],
      ),
      VoiceCommandDefinition(
        id: 'tipo_industrial',
        phrases: ['tipo industrial', 'imovel industrial', 'industrial'],
      ),
      VoiceCommandDefinition(
        id: 'inicio_area_externa',
        phrases: ['comecar area externa', 'iniciar area externa', 'area externa'],
      ),
      VoiceCommandDefinition(
        id: 'inicio_area_interna',
        phrases: ['comecar area interna', 'iniciar area interna', 'area interna'],
      ),
    ];
  }

  List<VoiceCommandDefinition> cameraCommands() {
    return const [
      VoiceCommandDefinition(
        id: 'capturar_foto',
        phrases: ['capturar foto', 'tirar foto', 'fotografar'],
      ),
      VoiceCommandDefinition(
        id: 'abrir_area',
        phrases: ['selecionar area', 'abrir area', 'area da foto'],
        entities: {
          'area': ['Área externa', 'Área interna', 'Área comum', 'Acesso', 'Entorno'],
        },
      ),
      VoiceCommandDefinition(
        id: 'abrir_local',
        phrases: ['selecionar local', 'abrir local', 'local da foto'],
      ),
      VoiceCommandDefinition(
        id: 'abrir_elemento',
        phrases: ['selecionar elemento', 'abrir elemento', 'elemento fotografado'],
      ),
      VoiceCommandDefinition(
        id: 'abrir_material',
        phrases: ['selecionar material', 'abrir material'],
      ),
      VoiceCommandDefinition(
        id: 'abrir_estado',
        phrases: ['selecionar estado', 'abrir estado'],
      ),
    ];
  }

  List<VoiceCommandDefinition> reviewCommands() {
    return const [
      VoiceCommandDefinition(
        id: 'finalizar_vistoria',
        phrases: ['finalizar vistoria', 'encerrar vistoria', 'concluir vistoria'],
      ),
      VoiceCommandDefinition(
        id: 'aceitar_sugestoes',
        phrases: ['aceitar sugestoes', 'aceitar sugestões'],
      ),
      VoiceCommandDefinition(
        id: 'aplicar_ao_subtipo',
        phrases: ['aplicar ao subtipo', 'copiar para subtipo'],
      ),
      VoiceCommandDefinition(
        id: 'aplicar_aos_semelhantes',
        phrases: ['aplicar aos semelhantes', 'copiar aos semelhantes'],
      ),
      VoiceCommandDefinition(
        id: 'abrir_subtipo',
        phrases: ['abrir subtipo', 'abrir grupo', 'abrir no de coleta'],
        entities: {
          'subtipo': [
            'Fachada',
            'Logradouro',
            'Acesso ao imóvel',
            'Entorno',
            'Sala',
            'Sala de Estar',
            'Dormitório',
            'Cozinha',
            'Banheiro',
            'Área de serviço',
            'Áreas Comuns',
            'Garagem',
          ],
        },
      ),
    ];
  }
}
