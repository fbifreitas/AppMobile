import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/clean_code_maturity_item.dart';

class CleanCodeMaturityCard extends StatelessWidget {
  final List<CleanCodeMaturityItem> items;

  const CleanCodeMaturityCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr('Plano para chegar perto de 9/10', 'Plan to get close to 9/10'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    strings.tr(
                      'Atual: ${item.currentLevel} • Alvo: ${item.targetLevel}',
                      'Current: ${item.currentLevel} • Target: ${item.targetLevel}',
                    ),
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(item.action, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
