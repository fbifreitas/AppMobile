import 'package:flutter/material.dart';

import '../models/checkin_step2_model.dart';
import '../models/inspection_camera_flow_request.dart';
import '../models/overlay_camera_capture_result.dart';
import '../screens/checkin_screen.dart';
import '../screens/camera_flow_screen.dart';
import '../screens/checkin_step2_screen.dart';
import '../screens/inspection_review_screen.dart';
import '../screens/overlay_camera_screen.dart';

abstract class InspectionFlowCoordinator {
  const InspectionFlowCoordinator();

  void openCheckin(BuildContext context, {bool silent = false});

  void openCheckinStep2(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
    bool silent = false,
  });

  Future<OverlayCameraCaptureResult?> openOverlayCamera(
    BuildContext context, {
    required InspectionCameraFlowRequest request,
  });

  void openInspectionReview(
    BuildContext context, {
    List<OverlayCameraCaptureResult> captures =
        const <OverlayCameraCaptureResult>[],
    required String tipoImovel,
    bool cameFromCheckinStep1 = false,
  });

  void restoreReviewRecoveryFlow(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
    List<OverlayCameraCaptureResult> captures =
        const <OverlayCameraCaptureResult>[],
  });

  void restoreCheckinStep2RecoveryFlow(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
  });

  void openCameraFlow(BuildContext context);
}

class DefaultInspectionFlowCoordinator implements InspectionFlowCoordinator {
  const DefaultInspectionFlowCoordinator();

  @override
  void openCheckin(BuildContext context, {bool silent = false}) {
    Navigator.of(context).push<void>(
      _buildRoute<void>((_) => const CheckinScreen(), silent: silent),
    );
  }

  @override
  void openCheckinStep2(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
    bool silent = false,
  }) {
    Navigator.of(context).push<void>(
      _buildRoute<void>(
        (_) => CheckinStep2Screen(
          tipoImovel: tipoImovel,
          initialData: initialData,
          onContinue: onContinue,
        ),
        silent: silent,
      ),
    );
  }

  @override
  Future<OverlayCameraCaptureResult?> openOverlayCamera(
    BuildContext context, {
    required InspectionCameraFlowRequest request,
  }) {
    return Navigator.of(context).push<OverlayCameraCaptureResult>(
      MaterialPageRoute<OverlayCameraCaptureResult>(
        builder:
            (_) => OverlayCameraScreen(
              title: request.title,
              tipoImovel: request.tipoImovel,
              subtipoImovel: request.subtipoImovel,
              singleCaptureMode: request.singleCaptureMode,
              cameFromCheckinStep1: request.cameFromCheckinStep1,
              initialFlowState: request.captureFlowState,
            ),
      ),
    );
  }

  @override
  void openInspectionReview(
    BuildContext context, {
    List<OverlayCameraCaptureResult> captures =
        const <OverlayCameraCaptureResult>[],
    required String tipoImovel,
    bool cameFromCheckinStep1 = false,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (_) => InspectionReviewScreen(
              captures: captures,
              tipoImovel: tipoImovel,
              cameFromCheckinStep1: cameFromCheckinStep1,
            ),
      ),
    );
  }

  @override
  void restoreReviewRecoveryFlow(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
    List<OverlayCameraCaptureResult> captures =
        const <OverlayCameraCaptureResult>[],
  }) {
    final tipoBase = _baseTipoImovel(tipoImovel);
    openCheckin(context, silent: true);
    openCheckinStep2(
      context,
      tipoImovel: tipoBase,
      initialData: initialData,
      onContinue: onContinue,
      silent: true,
    );
    openInspectionReview(context, captures: captures, tipoImovel: tipoImovel);
  }

  @override
  void restoreCheckinStep2RecoveryFlow(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
  }) {
    openCheckin(context, silent: true);
    openCheckinStep2(
      context,
      tipoImovel: _baseTipoImovel(tipoImovel),
      initialData: initialData,
      onContinue: onContinue,
    );
  }

  @override
  void openCameraFlow(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const CameraFlowScreen()),
    );
  }

  Route<T> _buildRoute<T>(WidgetBuilder builder, {required bool silent}) {
    if (silent) {
      return PageRouteBuilder<T>(
        pageBuilder: (context, _, __) => builder(context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }

    return MaterialPageRoute<T>(builder: builder);
  }

  String _baseTipoImovel(String rawTipoImovel) {
    return rawTipoImovel.split('•').first.trim();
  }
}
