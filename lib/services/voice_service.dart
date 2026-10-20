import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      print('Speech init error: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Function()? onDone,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) return;

    _isListening = true;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          _isListening = false;
          onDone?.call();
        } else {
          onPartialResult?.call(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  void dispose() {
    _speech.cancel();
  }
}

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Voice listening state
final isListeningProvider = StateProvider<bool>((ref) => false);
final partialTextProvider = StateProvider<String>((ref) => '');
