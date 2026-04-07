import 'package:flutter/material.dart';

import '../models/app_navigation_entry.dart';

class AppNavigationShortcutsCard extends StatelessWidget {
  final List<AppNavigationEntry> items;
  final ValueChanged<AppNavigationEntry> onTap;

  const AppNavigationShortcutsCard({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            'Atalhos principais',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => onTap(item),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item.title),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
