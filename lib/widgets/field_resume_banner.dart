import 'package:flutter/material.dart';

class FieldResumeBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onResume;
  final VoidCallback? onDismiss;

  const FieldResumeBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onResume,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton(
                onPressed: onResume,
                child: const Text('Retomar'),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Descartar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
