import '../models/flow_selection.dart';
import '../models/inspection_camera_flow_request.dart';

class CameraRecoveryState {
  const CameraRecoveryState({
    required this.title,
    required this.tipoImovel,
    required this.subtipoImovel,
    required this.singleCaptureMode,
    required this.cameFromCheckinStep1,
    required this.selection,
  });

  final String title;
  final String tipoImovel;
  final String subtipoImovel;
  final bool singleCaptureMode;
  final bool cameFromCheckinStep1;
  final FlowSelection selection;
}

class InspectionRecoveryRouteService {
  const InspectionRecoveryRouteService();

  static const InspectionRecoveryRouteService instance =
      InspectionRecoveryRouteService();

  Map<String, dynamic> buildCameraStagePayload({
    required String title,
    required String tipoImovel,
    required String subtipoImovel,
    required bool singleCaptureMode,
    required bool cameFromCheckinStep1,
    required FlowSelection selection,
  }) {
    return <String, dynamic>{
      'title': title,
      'tipoImovel': tipoImovel,
      'subtipoImovel': subtipoImovel,
      'singleCaptureMode': singleCaptureMode,
      'cameFromCheckinStep1': cameFromCheckinStep1,
      'selection': selection.toMap(includeCanonical: true, includeLegacy: true),
    };
  }

  CameraRecoveryState? readCameraState(Map<String, dynamic> payload) {
    final raw = payload['cameraStage'];
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw.map((key, value) => MapEntry('$key', value)));
    final title = '${map['title'] ?? ''}'.trim();
    final tipoImovel = '${map['tipoImovel'] ?? ''}'.trim();
    final subtipoImovel = '${map['subtipoImovel'] ?? ''}'.trim();
    if (title.isEmpty || tipoImovel.isEmpty || subtipoImovel.isEmpty) {
      return null;
    }

    final rawSelection = map['selection'];
    final selection =
        rawSelection is Map
            ? FlowSelection.fromMap(
              Map<String, dynamic>.from(
                rawSelection.map((key, value) => MapEntry('$key', value)),
              ),
            )
            : FlowSelection.empty;

    return CameraRecoveryState(
      title: title,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      singleCaptureMode: map['singleCaptureMode'] == true,
      cameFromCheckinStep1: map['cameFromCheckinStep1'] == true,
      selection: selection,
    );
  }

  InspectionCameraFlowRequest? buildCameraRequestFromRecovery(
    Map<String, dynamic> payload,
  ) {
    final state = readCameraState(payload);
    if (state == null) return null;

    return InspectionCameraFlowRequest.bootstrap(
      title: state.title,
      tipoImovel: state.tipoImovel,
      subtipoImovel: state.subtipoImovel,
      singleCaptureMode: state.singleCaptureMode,
      cameFromCheckinStep1: state.cameFromCheckinStep1,
      initialSelection: state.selection,
      preferInitialSelection: true,
    );
  }
}
