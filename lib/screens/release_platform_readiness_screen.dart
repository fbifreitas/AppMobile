import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/platform_permission_audit_service.dart';
import '../services/release_branding_plan_service.dart';
import '../services/release_identity_audit_service.dart';
import '../widgets/platform_permission_audit_list.dart';
import '../widgets/release_branding_plan_card.dart';
import '../widgets/release_identity_summary_card.dart';

class ReleasePlatformReadinessScreen extends StatelessWidget {
  const ReleasePlatformReadinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final identity = const ReleaseIdentityAuditService().items();
    final permissions = const PlatformPermissionAuditService().items();
    final steps = const ReleaseBrandingPlanService().steps();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('Plataforma, permissoes e release', 'Platform, permissions and release')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReleaseIdentitySummaryCard(items: identity),
          const SizedBox(height: 12),
          PlatformPermissionAuditList(items: permissions),
          const SizedBox(height: 12),
          ReleaseBrandingPlanCard(steps: steps),
        ],
      ),
    );
  }
}
