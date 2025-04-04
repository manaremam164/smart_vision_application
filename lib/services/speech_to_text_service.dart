import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  // Callback to handle recognized text
  Function(String)? onResult;

  // Initialize speech-to-text
  Future<bool> initialize() async {
    bool available = await _speechToText.initialize();
    return available;
  }

  // Start listening continuously
  Future<void> startListening() async {
    if (!_isListening) {
      _isListening = true;
      _listen();
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speechToText.stop();
      await _speechToText.cancel();
    }
  }

  // Internal method to handle listening logic
  void _listen() async {
    if (_isListening) {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastWords = result.recognizedWords;
            if (onResult != null) {
              onResult!(_lastWords);
            }
            // Stop listening after final result
            _restartListening();
          }
        },
        listenFor: Duration(seconds: 2), // Stop after 2 seconds of inactivity
        pauseFor: Duration(seconds: 2), // Pause for 2 seconds before restarting
      );
    }
  }

  // Restart listening after a short delay
  void _restartListening() async {
    await Future.delayed(Duration(seconds: 2)); // Wait for 2 seconds
    if (_isListening) {
      _listen(); // Restart listening
    }
  }

  // Dispose resources
  void dispose() {
    _speechToText.stop();
    _isListening = false;
  }
}