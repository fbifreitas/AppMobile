import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart';

class PermissionsOnboardingStatus {
  final bool cameraGranted;
  final bool locationGranted;
  final bool microphoneGranted;

  const PermissionsOnboardingStatus({
    required this.cameraGranted,
    required this.locationGranted,
    required this.microphoneGranted,
  });

  bool get allGranted => cameraGranted && locationGranted && microphoneGranted;
}

class PermissionsOnboardingService {
  const PermissionsOnboardingService();

  Future<PermissionsOnboardingStatus> requestAll() async {
    final cameraGranted = await _requestCamera();
    final locationGranted = await _requestLocation();
    final microphoneGranted = await _requestMicrophone();
    return PermissionsOnboardingStatus(
      cameraGranted: cameraGranted,
      locationGranted: locationGranted,
      microphoneGranted: microphoneGranted,
    );
  }

  Future<bool> _requestCamera() async {
    try {
      await availableCameras();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _requestLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      final permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _requestMicrophone() async {
    try {
      final speech = SpeechToText();
      return await speech.initialize();
    } catch (_) {
      return false;
    }
  }
}
