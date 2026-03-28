import '../models/platform_permission_audit_item.dart';

class PlatformPermissionAuditService {
  const PlatformPermissionAuditService();

  List<PlatformPermissionAuditItem> items() {
    return const <PlatformPermissionAuditItem>[
      PlatformPermissionAuditItem(
        platform: 'Android',
        permission: 'CAMERA',
        declared: true,
        description: 'Necessária para captura e classificação por câmera.',
      ),
      PlatformPermissionAuditItem(
        platform: 'Android',
        permission: 'RECORD_AUDIO',
        declared: true,
        description: 'Necessária para entrada por voz.',
      ),
      PlatformPermissionAuditItem(
        platform: 'Android',
        permission: 'ACCESS_FINE_LOCATION',
        declared: true,
        description: 'Necessária para localização operacional.',
      ),
      PlatformPermissionAuditItem(
        platform: 'iOS',
        permission: 'NSCameraUsageDescription',
        declared: true,
        description: 'Necessária para captura por câmera no iOS.',
      ),
      PlatformPermissionAuditItem(
        platform: 'iOS',
        permission: 'NSMicrophoneUsageDescription',
        declared: true,
        description: 'Necessária para entrada por voz.',
      ),
      PlatformPermissionAuditItem(
        platform: 'iOS',
        permission: 'NSSpeechRecognitionUsageDescription',
        declared: true,
        description: 'Necessária para reconhecimento de fala.',
      ),
      PlatformPermissionAuditItem(
        platform: 'iOS',
        permission: 'NSLocationWhenInUseUsageDescription',
        declared: true,
        description: 'Necessária para localização operacional.',
      ),
    ];
  }
}
