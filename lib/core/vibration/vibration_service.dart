import 'package:vibration/vibration.dart';

class VibrationService {
  static Future<void> vibrateAlarm() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasCustom = await Vibration.hasCustomVibrationsSupport();
      if (hasCustom == true) {
        // Vibrate with pattern: wait 500ms, vibrate 1000ms, wait 500ms, vibrate 1000ms...
        Vibration.vibrate(
          pattern: [500, 1000, 500, 1000, 500, 1000],
          repeat: 0, // repeat from start
        );
      } else {
        Vibration.vibrate(duration: 2000);
      }
    }
  }

  static Future<void> vibrateQuick() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 100);
    }
  }

  static Future<void> cancel() async {
    Vibration.cancel();
  }
}
