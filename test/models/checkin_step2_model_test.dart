import 'package:appmobile/config/checkin_step2_config.dart';
import 'package:appmobile/models/checkin_step2_model.dart';
import 'package:appmobile/models/inspection_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CheckinStep2Model captures photo and reports it as captured', () {
    final model = CheckinStep2Model.empty(TipoImovel.urbano);
    final geoPoint = GeoPointData(
      latitude: -23.55052,
      longitude: -46.633308,
      accuracy: 5.0,
      capturedAt: DateTime.utc(2026, 3, 29),
    );

    final updated = model.setPhoto(
      fieldId: 'fachada',
      titulo: 'Fachada',
      imagePath: '/tmp/fachada.jpg',
      geoPoint: geoPoint,
    );

    expect(updated.isPhotoCaptured('fachada'), isTrue);
    expect(updated.fotos['fachada']?.imagePath, '/tmp/fachada.jpg');
    expect(updated.fotos['fachada']?.geoPoint, geoPoint);
  });

  test('CheckinStep2Model removes photo capture correctly', () {
    final model = CheckinStep2Model.empty(TipoImovel.urbano);
    final geoPoint = GeoPointData(
      latitude: -23.55052,
      longitude: -46.633308,
      accuracy: 5.0,
      capturedAt: DateTime.utc(2026, 3, 29),
    );

    final updated = model.setPhoto(
      fieldId: 'logradouro',
      titulo: 'Logradouro',
      imagePath: '/tmp/logradouro.jpg',
      geoPoint: geoPoint,
    );

    final cleared = updated.removePhoto('logradouro');

    expect(cleared.isPhotoCaptured('logradouro'), isFalse);
    expect(cleared.fotos['logradouro']?.imagePath, isEmpty);
    expect(cleared.fotos['logradouro']?.geoPoint, isNull);
  });

  test('CheckinStep2Model round-trips through map serialization', () {
    final original = CheckinStep2Model.empty(TipoImovel.urbano);
    final serialized = original.toMap();
    final deserialized = CheckinStep2Model.fromMap(serialized);

    expect(deserialized.tipoImovel, original.tipoImovel);
    expect(deserialized.fotos.length, original.fotos.length);
    expect(deserialized.respostas.length, original.respostas.length);
  });
}
