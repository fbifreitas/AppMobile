import '../models/inspection_camera_selector_section.dart';
import '../models/inspection_capture_context.dart';
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
    required InspectionCaptureFlowState flowState,
    required List<String> macroLocais,
    required List<String> ambientes,
    required List<String> elementos,
    required List<String> materiais,
    required List<String> estados,
  }) {
    final sections = <InspectionCameraSelectorSection>[];
    final current = flowState.current;

    for (final levelId in levelOrder) {
      if (!levelPresentationService.isLevelEnabled(
        levelOrder: levelOrder,
        levelId: levelId,
      )) {
        continue;
      }

      switch (levelId) {
        case 'macroLocal':
          if (macroLocais.isEmpty && current.macroLocal == null) {
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
                  macroLocais.isNotEmpty
                      ? macroLocais
                      : <String>[if (current.macroLocal != null) current.macroLocal!],
              selected: current.macroLocal,
            ),
          );
          break;
        case 'ambiente':
          if (current.macroLocal == null) {
            continue;
          }
          sections.add(
            InspectionCameraSelectorSection(
              levelId: levelId,
              title: levelPresentationService.labelForLevel(
                levelId: levelId,
                labelsByLevel: labelsByLevel,
              ),
              values: ambientes,
              selected: current.ambiente,
              allowVoiceSelection:
                  current.ambiente != null && ambientes.isNotEmpty,
              allowDuplicate:
                  current.ambiente != null &&
                  current.ambiente!.trim().isNotEmpty,
              duplicateLabel:
                  contextActionsService.duplicateActionLabelFor(
                    current.ambiente,
                  ) ??
                  'Novo ambiente',
            ),
          );
          break;
        case 'elemento':
          if (current.ambiente == null || elementos.isEmpty) {
            continue;
          }
          sections.add(
            InspectionCameraSelectorSection(
              levelId: levelId,
              title: levelPresentationService.labelForLevel(
                levelId: levelId,
                labelsByLevel: labelsByLevel,
              ),
              values: elementos,
              selected: current.elemento,
            ),
          );
          break;
        case 'material':
          if (current.elemento == null || materiais.isEmpty) {
            continue;
          }
          sections.add(
            InspectionCameraSelectorSection(
              levelId: levelId,
              title: levelPresentationService.labelForLevel(
                levelId: levelId,
                labelsByLevel: labelsByLevel,
              ),
              values: materiais,
              selected: current.material,
            ),
          );
          break;
        case 'estado':
          if (current.elemento == null ||
              (materiais.isNotEmpty && current.material == null)) {
            continue;
          }
          sections.add(
            InspectionCameraSelectorSection(
              levelId: levelId,
              title: levelPresentationService.labelForLevel(
                levelId: levelId,
                labelsByLevel: labelsByLevel,
              ),
              values: estados,
              selected: current.estado,
            ),
          );
          break;
      }
    }

    return sections;
  }
}
