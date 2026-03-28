import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class ProposalsSection extends StatelessWidget {
  const ProposalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final propostas = const [
      {
        'valor': 'R\$ 150,00',
        'resumo': '2.5 km • Apto padrão',
        'tempo': '00:45',
      },
      {
        'valor': 'R\$ 220,00',
        'resumo': '4.1 km • Casa',
        'tempo': '01:10',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOVAS PROPOSTAS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ...propostas.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['valor']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      item['resumo']!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Expira em ${item['tempo']}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
