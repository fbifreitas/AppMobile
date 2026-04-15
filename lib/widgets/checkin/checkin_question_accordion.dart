import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';

class CheckinQuestionAccordion extends StatelessWidget {
  const CheckinQuestionAccordion({
    super.key,
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onToggle,
    required this.onVoiceTap,
    required this.child,
  });

  final String question;
  final String? answer;
  final bool expanded;
  final VoidCallback onToggle;
  final Future<void> Function() onVoiceTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final answered = answer != null && answer!.trim().isNotEmpty;
    final borderColor = answered ? AppColors.success : AppColors.border;
    final background = answered ? AppColors.successLight : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: question,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          if (answered)
                            TextSpan(
                              text: ' [$answer]',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.tr('Selecionar por voz', 'Select by voice'),
                    onPressed: onVoiceTap,
                    icon: const Icon(Icons.mic_none, size: 18),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: answered ? AppColors.success : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
        ],
      ),
    );
  }
}
