import 'package:flutter/material.dart';

import '../../models/inspection_camera_selector_section.dart';
import 'overlay_camera_support_widgets.dart';

class OverlayCameraSelectorPanel extends StatelessWidget {
  final List<InspectionCameraSelectorSection> sections;
  final ValueChanged<String> onSelectSubjectContext;
  final ValueChanged<String> onSelectTargetItem;
  final VoidCallback onDuplicateTargetItem;
  final ValueChanged<String> onSelectTargetQualifier;
  final ValueChanged<String> onSelectMaterial;
  final ValueChanged<String> onSelectTargetCondition;
  final Future<void> Function({
    required String title,
    required List<String> values,
    required String? selected,
    required Future<void> Function(String value) onSelect,
  })
  onVoiceSelection;

  const OverlayCameraSelectorPanel({
    super.key,
    required this.sections,
    required this.onSelectSubjectContext,
    required this.onSelectTargetItem,
    required this.onDuplicateTargetItem,
    required this.onSelectTargetQualifier,
    required this.onSelectMaterial,
    required this.onSelectTargetCondition,
    required this.onVoiceSelection,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    for (final section in sections) {
      switch (section.levelId) {
        case 'macroLocal':
          widgets.add(const SizedBox(height: 8));
          widgets.add(
            OverlayCameraCarouselCard(
              title: section.title,
              values: section.values,
              selected: section.selected,
              onSelect: onSelectSubjectContext,
              onVoiceTap: () => onVoiceSelection(
                title: section.title,
                values: section.values,
                selected: section.selected,
                onSelect: (value) async => onSelectSubjectContext(value),
              ),
            ),
          );
          break;
        case 'ambiente':
          widgets.add(const SizedBox(height: 8));
          widgets.add(
            OverlayCameraAmbienteSelectorCard(
              title: section.title,
              values: section.values,
              selected: section.selected,
              onSelect: onSelectTargetItem,
              onChange: !section.allowVoiceSelection
                  ? null
                  : () => onVoiceSelection(
                        title: section.title,
                        values: section.values,
                        selected: section.selected,
                        onSelect: (value) async => onSelectTargetItem(value),
                      ),
              onDuplicate: !section.allowDuplicate ? null : onDuplicateTargetItem,
              duplicateLabel: section.duplicateLabel ?? 'Novo ambiente',
            ),
          );
          break;
        case 'elemento':
          widgets.add(const SizedBox(height: 8));
          widgets.add(
            OverlayCameraCarouselCard(
              title: section.title,
              values: section.values,
              selected: section.selected,
              onSelect: onSelectTargetQualifier,
              onVoiceTap: () => onVoiceSelection(
                title: section.title,
                values: section.values,
                selected: section.selected,
                onSelect: (value) async => onSelectTargetQualifier(value),
              ),
            ),
          );
          break;
        case 'material':
          widgets.add(const SizedBox(height: 8));
          widgets.add(
            OverlayCameraCarouselCard(
              title: section.title,
              values: section.values,
              selected: section.selected,
              onSelect: onSelectMaterial,
              onVoiceTap: () => onVoiceSelection(
                title: section.title,
                values: section.values,
                selected: section.selected,
                onSelect: (value) async => onSelectMaterial(value),
              ),
            ),
          );
          break;
        case 'estado':
          widgets.add(const SizedBox(height: 8));
          widgets.add(
            OverlayCameraCarouselCard(
              title: section.title,
              values: section.values,
              selected: section.selected,
              onSelect: onSelectTargetCondition,
              onVoiceTap: () => onVoiceSelection(
                title: section.title,
                values: section.values,
                selected: section.selected,
                onSelect: (value) async => onSelectTargetCondition(value),
              ),
            ),
          );
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
