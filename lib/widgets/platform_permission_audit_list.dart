import 'package:flutter/material.dart';

import '../models/platform_permission_audit_item.dart';

class PlatformPermissionAuditList extends StatelessWidget {
  final List<PlatformPermissionAuditItem> items;

  const PlatformPermissionAuditList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.declared ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.platform} • ${item.permission}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(item.description, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
