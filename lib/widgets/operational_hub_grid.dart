import 'package:flutter/material.dart';

import '../models/operational_hub_item.dart';

class OperationalHubGrid extends StatelessWidget {
  final List<OperationalHubItem> items;
  final ValueChanged<OperationalHubItem> onTap;

  const OperationalHubGrid({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onTap(item),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: item.highlighted ? 0.32 : 0.22),
              border: Border.all(
                color: item.highlighted
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.20)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(item.iconKey), size: 22),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'task':
        return Icons.assignment_outlined;
      case 'sync':
        return Icons.sync_outlined;
      case 'spark':
        return Icons.auto_awesome_outlined;
      case 'shield':
        return Icons.verified_outlined;
      case 'chart':
        return Icons.query_stats_outlined;
      case 'lock':
        return Icons.lock_outline;
      case 'rocket':
        return Icons.rocket_launch_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'code':
        return Icons.code_outlined;
      case 'export':
        return Icons.ios_share_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }
}
