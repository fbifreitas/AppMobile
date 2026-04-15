import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../theme/app_colors.dart';

class AwaitingApprovalScreen extends StatelessWidget {
  const AwaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 44,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                strings.tr('Cadastro em analise', 'Registration under review'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                strings.tr(
                  'Seu cadastro foi recebido e esta sendo verificado pela nossa equipe. Voce sera notificado assim que a aprovacao for concluida.',
                  'Your registration has been received and is being reviewed by our team. You will be notified as soon as approval is completed.',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              OutlinedButton.icon(
                key: const Key('check_status_button'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        strings.tr(
                          'Status verificado. Aguarde a aprovacao do backoffice.',
                          'Status checked. Please wait for backoffice approval.',
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: Text(strings.tr('Verificar status', 'Check status')),
              ),
              if (!kReleaseMode) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  key: const Key('simulate_approval_button'),
                  onPressed: () => authState.activateAccount(),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    strings.tr('[Dev] Simular aprovacao', '[Dev] Simulate approval'),
                  ),
                ),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await context.read<AppState>().resetSessionAfterLogout();
                  await authState.logout();
                },
                icon: const Icon(Icons.logout, size: 16),
                label: Text(strings.tr('Sair da conta', 'Sign out')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
