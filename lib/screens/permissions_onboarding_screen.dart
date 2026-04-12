import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        const SnackBar(
          content: Text('Permissoes essenciais conferidas com sucesso.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ainda faltam permissoes essenciais. Revise cada item e tente novamente.',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Permissoes essenciais')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Antes de usar o app em campo, valide as permissoes essenciais. Se alguma ja estiver aprovada no Android, vamos apenas confirmar e continuar.',
            ),
            const SizedBox(height: 16),
            _permissionTile(
              title: 'Camera',
              description: 'Necessaria para captura tecnica da vistoria.',
              granted: current?.cameraGranted ?? false,
            ),
            _permissionTile(
              title: 'Localizacao',
              description: 'Necessaria para validacao operacional em campo.',
              granted: current?.locationGranted ?? false,
            ),
            _permissionTile(
              title: 'Microfone',
              description: 'Necessario para recursos de voz operacionais.',
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
                : const Text('Validar permissoes e continuar'),
          ),
        ),
      ),
    );
  }
}
