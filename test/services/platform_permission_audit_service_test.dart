import 'dart:io';

import 'package:appmobile/services/platform_permission_audit_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('audited Android permissions are declared in manifest', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final permissions = const PlatformPermissionAuditService()
        .items()
        .where((item) => item.platform == 'Android');

    for (final item in permissions) {
      expect(
        manifest,
        contains('android.permission.${item.permission}'),
        reason: '${item.permission} must stay declared for onboarding.',
      );
    }
  });

  test('audited iOS permission descriptions are declared in Info.plist', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final permissions = const PlatformPermissionAuditService()
        .items()
        .where((item) => item.platform == 'iOS');

    for (final item in permissions) {
      expect(
        plist,
        contains('<key>${item.permission}</key>'),
        reason: '${item.permission} must stay declared for onboarding.',
      );
    }
  });
}
