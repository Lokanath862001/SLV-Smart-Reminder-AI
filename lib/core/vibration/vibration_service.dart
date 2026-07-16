import 'package:flutter/services.dart';

class VibrationService {
  static const _channel = MethodChannel('com.slv.reminder/vibration');

  static Future<void> vibrateAlarm() async {
    try {
      await _channel.invokeMethod('vibrateAlarm');
    } catch (_) {}
  }

  static Future<void> vibrateQuick() async {
    try {
      await _channel.invokeMethod('vibrateQuick');
    } catch (_) {}
  }

  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } catch (_) {}
  }
}
