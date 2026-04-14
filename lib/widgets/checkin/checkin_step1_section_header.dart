import 'package:flutter/material.dart';

class CheckinStep1SectionHeader extends StatelessWidget {
  const CheckinStep1SectionHeader({
    super.key,
    required this.answered,
    required this.total,
    required this.isDone,
    required this.expanded,
    required this.statusColor,
    required this.statusBackground,
    required this.onTap,
  });

  final int answered;
  final int total;
  final bool isDone;
  final bool expanded;
  final Color statusColor;
  final Color statusBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'ETAPA 1 CHECK-IN $answered/$total ${isDone ? 'OK' : 'NOK'}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }
}
