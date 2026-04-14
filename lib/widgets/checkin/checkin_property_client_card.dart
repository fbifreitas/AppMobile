import 'package:flutter/material.dart';

import '../../models/job.dart';
import '../../theme/app_colors.dart';

class CheckinPropertyClientCard extends StatelessWidget {
  final Job job;

  const CheckinPropertyClientCard({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DADOS IMÓVEL E CLIENTE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            job.titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            job.endereco,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cliente: ${job.nomeCliente.isEmpty ? 'Não informado' : job.nomeCliente}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Contato: ${job.telefoneCliente?.isNotEmpty == true ? job.telefoneCliente : 'Não informado'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
