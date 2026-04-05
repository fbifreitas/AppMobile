import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/permissions_onboarding_service.dart';
import '../state/auth_state.dart';
import '../theme/app_colors.dart';

class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  State<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends State<PermissionsOnboardingScreen> {
  final PermissionsOnboardingService _permissionsService =
      const PermissionsOnboardingService();

  bool _loading = false;
  PermissionsOnboardingStatus? _status;

  Future<void> _requestPermissions() async {
    setState(() => _loading = true);
    final status = await _permissionsService.requestAll();
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
          content: Text('Permissões essenciais concedidas com sucesso.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ainda faltam permissões essenciais. Conceda para continuar.',
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
      appBar: AppBar(title: const Text('Permissões essenciais')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Antes de usar o app em campo, conceda as permissões operacionais obrigatórias.',
            ),
            const SizedBox(height: 16),
            _permissionTile(
              title: 'Câmera',
              description: 'Necessária para captura técnica da vistoria.',
              granted: current?.cameraGranted ?? false,
            ),
            _permissionTile(
              title: 'Localização',
              description: 'Necessária para validação operacional em campo.',
              granted: current?.locationGranted ?? false,
            ),
            _permissionTile(
              title: 'Microfone',
              description: 'Necessário para recursos de voz operacionais.',
              granted: current?.microphoneGranted ?? false,
            ),
            const Spacer(),
            SizedBox(
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
                    : const Text('Conceder permissões e continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
