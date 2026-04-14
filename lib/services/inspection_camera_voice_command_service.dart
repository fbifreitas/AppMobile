class InspectionCameraVoiceCommandService {
  const InspectionCameraVoiceCommandService();

  static const InspectionCameraVoiceCommandService instance =
      InspectionCameraVoiceCommandService();

  bool isCaptureCommand(String commandId) =>
      commandId == 'capturar_foto' || commandId == 'capture_photo';

  String? selectorLevelForCommand(String commandId) {
    switch (commandId) {
      case 'open_capture_context':
      case 'abrir_area':
        return 'macroLocal';
      case 'open_target_item':
      case 'abrir_local':
        return 'ambiente';
      case 'open_target_qualifier':
      case 'abrir_elemento':
        return 'elemento';
      case 'open_material_attribute':
      case 'abrir_material':
        return 'material';
      case 'open_condition_state':
      case 'abrir_estado':
        return 'estado';
    }
    return null;
  }

  String? canonicalSelectorLevelForCommand(String commandId) {
    switch (selectorLevelForCommand(commandId)) {
      case 'macroLocal':
        return 'captureContext';
      case 'ambiente':
        return 'targetItem';
      case 'elemento':
        return 'targetQualifier';
      case 'material':
        return 'materialAttribute';
      case 'estado':
        return 'conditionState';
    }
    return null;
  }
}
