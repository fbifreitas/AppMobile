class InspectionCameraVoiceCommandService {
  const InspectionCameraVoiceCommandService();

  static const InspectionCameraVoiceCommandService instance =
      InspectionCameraVoiceCommandService();

  bool isCaptureCommand(String commandId) => commandId == 'capturar_foto';

  String? selectorLevelForCommand(String commandId) {
    switch (commandId) {
      case 'abrir_area':
        return 'macroLocal';
      case 'abrir_local':
        return 'ambiente';
      case 'abrir_elemento':
        return 'elemento';
      case 'abrir_material':
        return 'material';
      case 'abrir_estado':
        return 'estado';
    }
    return null;
  }
}
