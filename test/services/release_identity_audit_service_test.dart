import 'package:appmobile/services/release_identity_audit_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('documents canonical Compass release identity', () {
    final items = const ReleaseIdentityAuditService().items();
    final scopes = items.map((item) => item.scope).toSet();

    expect(scopes, contains('android:compass'));
    expect(scopes, contains('firebase:compass'));

    final compassAndroid = items.singleWhere(
      (item) => item.scope == 'android:compass',
    );
    expect(compassAndroid.currentValue, contains('com.compass.avaliacoes'));
    expect(compassAndroid.currentValue, contains('lib/main_compass.dart'));

    final compassFirebase = items.singleWhere(
      (item) => item.scope == 'firebase:compass',
    );
    expect(compassFirebase.currentValue, 'FIREBASE_APP_ID_ANDROID_COMPASS');
  });
}
