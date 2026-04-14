import 'package:flutter/material.dart';

class OverlayCameraGlassButton extends StatelessWidget {
  const OverlayCameraGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.black.withValues(alpha: 0.20)
              : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class OverlayCameraFinalizeButton extends StatelessWidget {
  const OverlayCameraFinalizeButton({
    super.key,
    required this.singleCaptureMode,
    required this.hasAnyCaptures,
    required this.finalizeSubtitle,
    required this.onFinalize,
    required this.onSingleCaptureClose,
  });

  final bool singleCaptureMode;
  final bool hasAnyCaptures;
  final String finalizeSubtitle;
  final VoidCallback onFinalize;
  final VoidCallback onSingleCaptureClose;

  @override
  Widget build(BuildContext context) {
    if (singleCaptureMode) {
      return _OverlayCameraCircleAction(
        icon: Icons.fact_check_outlined,
        onTap: onSingleCaptureClose,
      );
    }

    if (!hasAnyCaptures) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.20),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.fact_check_outlined,
          color: Colors.white38,
          size: 22,
        ),
      );
    }

    return GestureDetector(
      onTap: onFinalize,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE65100),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fact_check_outlined,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revisar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  finalizeSubtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class OverlayCameraHintCard extends StatelessWidget {
  const OverlayCameraHintCard({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class OverlayCameraQuickSuggestionCard extends StatelessWidget {
  const OverlayCameraQuickSuggestionCard({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            ...values.map((value) {
              final active = value == selected;
              return GestureDetector(
                onTap: () => onSelect(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: active ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class OverlayCameraCarouselCard extends StatelessWidget {
  const OverlayCameraCarouselCard({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelect,
    this.onVoiceTap,
  });

  final String title;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback? onVoiceTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (values.isNotEmpty)
                    IconButton(
                      tooltip: 'Selecionar por voz',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      icon: const Icon(
                        Icons.mic_none,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: onVoiceTap,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemCount: values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final value = values[index];
                  final active = value == selected;
                  return GestureDetector(
                    onTap: () => onSelect(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          value,
                          style: TextStyle(
                            color: active ? Colors.black87 : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OverlayCameraAmbienteSelectorCard extends StatelessWidget {
  const OverlayCameraAmbienteSelectorCard({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelect,
    required this.onChange,
    required this.onDuplicate,
    required this.duplicateLabel,
  });

  final String title;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback? onChange;
  final VoidCallback? onDuplicate;
  final String duplicateLabel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onDuplicate,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      child: Text(duplicateLabel),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onChange,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      child: const Text('Trocar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                key: const ValueKey('camera_ambiente_selector_list'),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemCount: values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final value = values[index];
                  final active = value == selected;
                  return GestureDetector(
                    onTap: () => onSelect(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          value,
                          style: TextStyle(
                            color: active ? Colors.black87 : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayCameraCircleAction extends StatelessWidget {
  const _OverlayCameraCircleAction({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
