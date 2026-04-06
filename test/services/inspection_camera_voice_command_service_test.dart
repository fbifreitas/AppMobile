import 'package:appmobile/services/inspection_camera_voice_command_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionCameraVoiceCommandService.instance;

  test('identifies capture command and selector commands', () {
    expect(service.isCaptureCommand('capturar_foto'), isTrue);
    expect(service.isCaptureCommand('abrir_local'), isFalse);
    expect(service.selectorLevelForCommand('abrir_area'), 'macroLocal');
    expect(service.selectorLevelForCommand('abrir_local'), 'ambiente');
    expect(service.selectorLevelForCommand('abrir_estado'), 'estado');
    expect(service.selectorLevelForCommand('desconhecido'), isNull);
  });
}
