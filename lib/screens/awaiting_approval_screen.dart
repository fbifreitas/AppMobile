import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme/app_colors.dart';

class AwaitingApprovalScreen extends StatelessWidget {
  const AwaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

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
              const Text(
                'Cadastro em análise',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Seu cadastro foi recebido e está sendo verificado pela nossa equipe. '
                'Você será notificado assim que a aprovação for concluída.',
                style: TextStyle(
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
                    const SnackBar(
                      content: Text(
                        'Status verificado. Aguarde a aprovação do backoffice.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Verificar status'),
              ),
              if (!kReleaseMode) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  key: const Key('simulate_approval_button'),
                  onPressed: () => authState.activateAccount(),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('[Dev] Simular aprovação'),
                ),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: () => authState.logout(),
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Sair da conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
