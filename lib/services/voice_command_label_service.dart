import 'voice_context_keys.dart';

class VoiceCommandLabelService {
  const VoiceCommandLabelService();

  String labelFor(String commandId, {String? context}) {
    final normalizedContext = context ?? '';
    final byContext = _labelsByContext[normalizedContext];
    if (byContext != null && byContext.containsKey(commandId)) {
      return byContext[commandId]!;
    }
    return _globalLabels[commandId] ?? commandId;
  }

  Map<String, String> labelsForContext(String context) {
    return {
      ..._globalLabels,
      ...(_labelsByContext[context] ?? const <String, String>{}),
    };
  }

  static const Map<String, String> _globalLabels = <String, String>{
    'capturar_foto': 'Capturar foto',
    'abrir_area': 'Abrir área',
    'abrir_local': 'Abrir local',
    'abrir_elemento': 'Abrir elemento',
    'abrir_material': 'Abrir material',
    'abrir_estado': 'Abrir estado',
    'finalizar_vistoria': 'Finalizar vistoria',
    'aceitar_sugestoes': 'Aceitar sugestões',
    'aplicar_ao_subtipo': 'Aplicar ao subtipo',
    'aplicar_aos_semelhantes': 'Aplicar aos semelhantes',
    'abrir_subtipo': 'Abrir subtipo',
    'cliente_presente_sim': 'Cliente presente',
    'cliente_presente_nao': 'Cliente ausente',
    'tipo_urbano': 'Tipo urbano',
    'tipo_rural': 'Tipo rural',
    'tipo_comercial': 'Tipo comercial',
    'tipo_industrial': 'Tipo industrial',
    'inicio_area_externa': 'Iniciar área externa',
    'inicio_area_interna': 'Iniciar área interna',
  };

  static const Map<String, Map<String, String>> _labelsByContext =
      <String, Map<String, String>>{
    VoiceContextKeys.camera: <String, String>{
      'capturar_foto': 'Capturar foto na câmera',
      'abrir_area': 'Abrir área da foto',
      'abrir_local': 'Abrir local da foto',
      'abrir_elemento': 'Abrir elemento fotografado',
      'abrir_material': 'Abrir material',
      'abrir_estado': 'Abrir estado',
    },
    VoiceContextKeys.review: <String, String>{
      'finalizar_vistoria': 'Finalizar vistoria',
      'aceitar_sugestoes': 'Aceitar sugestões',
      'aplicar_ao_subtipo': 'Aplicar ao subtipo atual',
      'aplicar_aos_semelhantes': 'Aplicar aos semelhantes',
      'abrir_subtipo': 'Abrir subtipo',
    },
    VoiceContextKeys.checkinStep1: <String, String>{
      'cliente_presente_sim': 'Cliente está presente',
      'cliente_presente_nao': 'Cliente está ausente',
      'tipo_urbano': 'Selecionar imóvel urbano',
      'tipo_rural': 'Selecionar imóvel rural',
      'tipo_comercial': 'Selecionar imóvel comercial',
      'tipo_industrial': 'Selecionar imóvel industrial',
      'inicio_area_externa': 'Começar pela área externa',
      'inicio_area_interna': 'Começar pela área interna',
    },
  };
}
