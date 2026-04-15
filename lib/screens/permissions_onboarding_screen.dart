import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/permissions_onboarding_service.dart';
import '../state/auth_state.dart';
import '../theme/app_colors.dart';

class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({
    super.key,
    this.permissionsService = const PermissionsOnboardingService(),
  });

  final PermissionsOnboardingService permissionsService;

  @override
  State<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends State<PermissionsOnboardingScreen> {
  bool _loading = false;
  PermissionsOnboardingStatus? _status;

  Future<void> _requestPermissions() async {
    final strings = AppStrings.of(context);
    setState(() => _loading = true);
    final status = await widget.permissionsService.requestAll();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = status;
    });

    if (status.allGranted) {
      await context.read<AuthState>().completePermissionsOnboarding();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.tr(
              'Permissoes essenciais conferidas com sucesso.',
              'Essential permissions validated successfully.',
            ),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.tr(
            'Ainda faltam permissoes essenciais. Revise cada item e tente novamente.',
            'Some essential permissions are still missing. Review each item and try again.',
          ),
        ),
      ),
    );
  }

  Widget _permissionTile({
    required String title,
    required String description,
    required bool granted,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        granted ? Icons.check_circle_outline : Icons.error_outline,
        color: granted ? Colors.green : Colors.orange,
      ),
      title: Text(title),
      subtitle: Text(description),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _status;
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(strings.tr('Permissoes essenciais', 'Essential permissions'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.tr(
                'Antes de usar o app em campo, valide as permissoes essenciais. Se alguma ja estiver aprovada no Android, vamos apenas confirmar e continuar.',
                'Before using the app in the field, validate the essential permissions. If any of them are already granted on Android, we will just confirm and continue.',
              ),
            ),
            const SizedBox(height: 16),
            _permissionTile(
              title: strings.tr('Camera', 'Camera'),
              description: strings.tr(
                'Necessaria para captura tecnica da vistoria.',
                'Required for technical inspection capture.',
              ),
              granted: current?.cameraGranted ?? false,
            ),
            _permissionTile(
              title: strings.tr('Localizacao', 'Location'),
              description: strings.tr(
                'Necessaria para validacao operacional em campo.',
                'Required for field operational validation.',
              ),
              granted: current?.locationGranted ?? false,
            ),
            _permissionTile(
              title: strings.tr('Microfone', 'Microphone'),
              description: strings.tr(
                'Necessario para recursos de voz operacionais.',
                'Required for operational voice features.',
              ),
              granted: current?.microphoneGranted ?? false,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _loading ? null : _requestPermissions,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    strings.tr(
                      'Validar permissoes e continuar',
                      'Validate permissions and continue',
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
