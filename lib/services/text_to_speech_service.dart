import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  static FlutterTts flutterTts = FlutterTts();

  static Future<void> speak(String text) async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(text);
    } catch (e) {
      print('Error in TextToSpeechService.speak: $e');
    }
  }
}
