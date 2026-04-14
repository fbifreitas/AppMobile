import '../models/inspection_camera_selector_section.dart';
import '../models/flow_selection.dart';
import 'inspection_camera_level_presentation_service.dart';
import 'inspection_context_actions_service.dart';

class InspectionCameraSelectorSectionService {
  const InspectionCameraSelectorSectionService({
    this.levelPresentationService =
        InspectionCameraLevelPresentationService.instance,
    this.contextActionsService = InspectionContextActionsService.instance,
  });

  static const InspectionCameraSelectorSectionService instance =
      InspectionCameraSelectorSectionService();

  final InspectionCameraLevelPresentationService levelPresentationService;
  final InspectionContextActionsService contextActionsService;

  List<InspectionCameraSelectorSection> buildSections({
    required List<String> levelOrder,
    required Map<String, String> labelsByLevel,
    required FlowSelectionState selectionState,
    required List<String> macroLocais,
    required List<String> ambientes,
    required List<String> elementos,
    required List<String> materiais,
    required List<String> estados,
  }) {
    return buildSectionsCanonical(
      levelOrder: levelOrder,
      labelsByLevel: labelsByLevel,
      selectionState: selectionState,
      captureContexts: macroLocais,
      targetItems: ambientes,
      targetQualifiers: elementos,
      materialAttributes: materiais,
      conditionStates: estados,
    );
  }

  List<InspectionCameraSelectorSection> buildSectionsCanonical({
    required List<String> levelOrder,
    required Map<String, String> labelsByLevel,
    required FlowSelectionState selectionState,
    required List<String> captureContexts,
    required List<String> targetItems,
    required List<String> targetQualifiers,
    required List<String> materialAttributes,
    required List<String> conditionStates,
  }) {
    final sections = <InspectionCameraSelectorSection>[];
    final current = selectionState.currentSelection;
    final selectedMaterial = current.attributeText('inspection.material');

    for (final levelId in levelOrder) {
      if (!levelPresentationService.isLevelEnabled(
        levelOrder: levelOrder,
        levelId: levelId,
      )) {
        continue;
      }

      switch (levelId) {
        case 'macroLocal':
          if (captureContexts.isEmpty && current.subjectContext == null) {
            continue;
          }
          sections.add(
            InspectionCameraSelectorSection(
              levelId: levelId,
              title: levelPresentationService.labelForLevel(
                levelId: levelId,
                labelsByLevel: labelsByLevel,
              ),
              values:
                  captureContexts.isNotEmpty
                      ? captureContexts
                      : <String>[
                        if (current.subjectContext != null)
                          current.subjectContext!,
                      ],
              selected: current.subjectContext,
            ),
          );
          break;
        case 'ambiente':
          if (current.subjectContext == null) {
            continue;
          }
          final ambienteValues = <String>[
            ...targetItems,
            if (current.targetItem != null &&
                current.targetItem!.trim().isNotEmpty &&
                !targetItems.contains(current.targetItem))
              current.targetItem!,
          ];
          sections.add(
            InspectionCameraSelectorSection(
              levelId: levelId,
              title: levelPresentationService.labelForLevel(
                levelId: levelId,
                labelsByLevel: labelsByLevel,
              ),
              values: ambienteValues,
              selected: current.targetItem,
              allowVoiceSelection:
                  current.targetItem != null && ambienteValues.isNotEmpty,
              allowDuplicate:
                  current.targetItem != null &&
                  current.targetItem!.trim().isNotEmpty,
              duplicateLabel:
                  contextActionsService.duplicateActionLabelFor(
                    current.targetItem,
                  ) ??
                  'Novo ambiente',
            ),
          );
          break;
        case 'elemento':
          if (current.targetItem == null || targetQualifiers.isEmpty) {
            continue;
          }
          final elementoValues = <String>[
            ...targetQualifiers,
            if (current.targetQualifier != null &&
                current.targetQualifier!.trim().isNotEmpty &&
                !targetQualifiers.contains(current.targetQualifier))
              current.targetQualifier!,
          ];
          sections.add(
            InspectionCameraSelectorSection(
              levelId: levelId,
              title: levelPresentationService.labelForLevel(
                levelId: levelId,
                labelsByLevel: labelsByLevel,
              ),
              values: elementoValues,
              selected: current.targetQualifier,
            ),
          );
          break;
        case 'material':
          if (current.targetQualifier == null || materialAttributes.isEmpty) {
            continue;
          }
          final materialValues = <String>[
            ...materialAttributes,
            if (selectedMaterial != null &&
                selectedMaterial.trim().isNotEmpty &&
                !materialAttributes.contains(selectedMaterial))
              selectedMaterial,
          ];
          sections.add(
            InspectionCameraSelectorSection(
              levelId: levelId,
              title: levelPresentationService.labelForLevel(
                levelId: levelId,
                labelsByLevel: labelsByLevel,
              ),
              values: materialValues,
              selected: selectedMaterial,
            ),
          );
          break;
        case 'estado':
          if (current.targetQualifier == null ||
              (materialAttributes.isNotEmpty && selectedMaterial == null)) {
            continue;
          }
          sections.add(
            InspectionCameraSelectorSection(
              levelId: levelId,
              title: levelPresentationService.labelForLevel(
                levelId: levelId,
                labelsByLevel: labelsByLevel,
              ),
              values: <String>[
                ...conditionStates,
                if (current.targetCondition != null &&
                    current.targetCondition!.trim().isNotEmpty &&
                    !conditionStates.contains(current.targetCondition))
                  current.targetCondition!,
              ],
              selected: current.targetCondition,
            ),
          );
          break;
      }
    }

    return sections;
  }
}
