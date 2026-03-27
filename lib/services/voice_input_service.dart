import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputConfig {
  final String localeId;
  final Duration listenFor;
  final Duration pauseFor;

  const VoiceInputConfig({
    this.localeId = 'pt_BR',
    this.listenFor = const Duration(seconds: 45),
    this.pauseFor = const Duration(seconds: 8),
  });

  static const VoiceInputConfig quick = VoiceInputConfig(
    listenFor: Duration(seconds: 20),
    pauseFor: Duration(seconds: 4),
  );

  static const VoiceInputConfig standard = VoiceInputConfig(
    listenFor: Duration(seconds: 45),
    pauseFor: Duration(seconds: 8),
  );

  static const VoiceInputConfig long = VoiceInputConfig(
    listenFor: Duration(seconds: 60),
    pauseFor: Duration(seconds: 10),
  );
}

class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;

    _initialized = await _speech.initialize(
      onStatus: (status) => debugPrint('speech_status: $status'),
      onError: (error) => debugPrint('speech_error: ${error.errorMsg}'),
      debugLogging: false,
    );

    return _initialized;
  }

  bool get isListening => _speech.isListening;

  Future<String?> listenOnce({
    String localeId = 'pt_BR',
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 8),
  }) async {
    final ok = await initialize();
    if (!ok) return null;

    String recognized = '';

    await _speech.listen(
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      listenOptions: SpeechListenOptions(
        partialResults: true,
      ),
      onResult: (SpeechRecognitionResult result) {
        recognized = result.recognizedWords;
      },
    );

    while (_speech.isListening) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final output = recognized.trim();
    return output.isEmpty ? null : output;
  }

  Future<String?> listenWithConfig(VoiceInputConfig config) {
    return listenOnce(
      localeId: config.localeId,
      listenFor: config.listenFor,
      pauseFor: config.pauseFor,
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }

  void dispose() {
    _speech.stop();
    _speech.cancel();
  }
}
