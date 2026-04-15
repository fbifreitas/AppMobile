import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/app_message.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings.of(context);
    final mensagens = appState.mensagens;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tr('Central de mensagens', 'Message center')),
        actions: [
          if (appState.mensagensNaoLidas > 0)
            TextButton(
              onPressed: appState.marcarTodasLidas,
              child: Text(strings.tr('Marcar todas', 'Mark all')),
            ),
        ],
      ),
      body:
          mensagens.isEmpty
              ? Center(
                child: Text(
                  strings.tr(
                    'Nenhuma mensagem no momento.',
                    'No messages at the moment.',
                  ),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: mensagens.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final msg = mensagens[index];
                  return _MessageCard(
                    msg: msg,
                    onTap: () => appState.marcarMensagemLida(msg.id),
                  );
                },
              ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.msg, required this.onTap});

  final AppMessage msg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: msg.lida ? AppColors.surface : AppColors.primaryLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: msg.lida ? AppColors.border : AppColors.primary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      msg.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (!msg.lida)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                msg.corpo,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(msg.timestamp),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m ${h}h$min';
  }
}
