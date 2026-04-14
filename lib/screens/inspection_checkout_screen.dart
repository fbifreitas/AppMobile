import 'package:flutter/material.dart';

import '../models/overlay_camera_capture_result.dart';
import 'inspection_review_screen.dart';

@Deprecated('Use InspectionReviewScreen as the unified final step.')
class InspectionCheckoutScreen extends StatelessWidget {
  final List<OverlayCameraCaptureResult> captureResults;
  final String assetType;

  const InspectionCheckoutScreen({
    super.key,
    required List<OverlayCameraCaptureResult> captures,
    required String tipoImovel,
  }) : captureResults = captures,
       assetType = tipoImovel;

  @override
  Widget build(BuildContext context) {
    return InspectionReviewScreen(
      captures: captureResults,
      tipoImovel: assetType,
    );
  }
}
