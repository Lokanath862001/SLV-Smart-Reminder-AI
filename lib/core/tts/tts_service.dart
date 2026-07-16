import 'package:flutter_tts/flutter_tts.dart';
import '../database/hive_database.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    
    // Set default engine/language
    await _flutterTts.setLanguage("en-US");
    
    // Retrieve custom TTS settings from settings box
    final box = HiveDatabase.settingsBox;
    final double pitch = box.get('tts_pitch', defaultValue: 1.0);
    final double speed = box.get('tts_speed', defaultValue: 0.5); // 0.5 is usually standard in flutter_tts
    final double volume = box.get('tts_volume', defaultValue: 1.0);
    
    await _flutterTts.setPitch(pitch);
    await _flutterTts.setSpeechRate(speed);
    await _flutterTts.setVolume(volume);
    
    _isInitialized = true;
  }

  static Future<void> speak(String text) async {
    await init();
    if (text.trim().isEmpty) return;
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
  }

  static Future<void> updateSettings({
    required double pitch,
    required double speed,
    required double volume,
    String? language,
  }) async {
    await init();
    
    final box = HiveDatabase.settingsBox;
    await box.put('tts_pitch', pitch);
    await box.put('tts_speed', speed);
    await box.put('tts_volume', volume);
    
    await _flutterTts.setPitch(pitch);
    await _flutterTts.setSpeechRate(speed);
    await _flutterTts.setVolume(volume);

    if (language != null) {
      await box.put('tts_language', language);
      await _flutterTts.setLanguage(language);
    }
  }

  static Future<List<String>> getLanguages() async {
    try {
      final List<dynamic>? languages = await _flutterTts.getLanguages;
      if (languages != null) {
        return languages.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return ['en-US'];
  }
}
