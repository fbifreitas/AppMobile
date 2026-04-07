import 'package:flutter/material.dart';

import '../models/overlay_camera_capture_result.dart';
import 'inspection_review_screen.dart';

@Deprecated('Use InspectionReviewScreen as the unified final step.')
class InspectionCheckoutScreen extends StatelessWidget {
  final List<OverlayCameraCaptureResult> captures;
  final String tipoImovel;

  const InspectionCheckoutScreen({
    super.key,
    required this.captures,
    required this.tipoImovel,
  });

  @override
  Widget build(BuildContext context) {
    return InspectionReviewScreen(
      captures: captures,
      tipoImovel: tipoImovel,
    );
  }
}
