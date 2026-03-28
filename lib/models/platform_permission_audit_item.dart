class PlatformPermissionAuditItem {
  final String platform;
  final String permission;
  final bool declared;
  final String description;

  const PlatformPermissionAuditItem({
    required this.platform,
    required this.permission,
    required this.declared,
    required this.description,
  });
}
