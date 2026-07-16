import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import '../../data/models/reminder_model.dart';
import '../database/hive_database.dart';
import '../notifications/notification_service.dart';
import '../tts/tts_service.dart';
import '../vibration/vibration_service.dart';

class AlarmManagerService {
  static Future<void> init() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<bool> scheduleAlarm(ReminderModel reminder) async {
    final int alarmId = reminder.id.hashCode;
    
    // Ensure alarm date is in the future
    if (reminder.dateTime.isBefore(DateTime.now())) {
      // If it's in the past and not recurring, don't schedule
      if (reminder.repeatOption == 'Once') {
        return false;
      }
    }

    final targetTime = _calculateNextOccurrence(reminder.dateTime, reminder);
    
    return await AndroidAlarmManager.oneShotAt(
      targetTime,
      alarmId,
      alarmCallback,
      alarmClock: true,
      allowWhileIdle: true,
      exact: true,
      wakeup: true,
    );
  }

  static Future<bool> cancelAlarm(String reminderId) async {
    return await AndroidAlarmManager.cancel(reminderId.hashCode);
  }

  @pragma('vm:entry-point')
  static Future<void> alarmCallback(int id) async {
    WidgetsFlutterBinding.ensureInitialized();
    await HiveDatabase.init();
    await NotificationService.init();
    await TtsService.init();

    // Fetch reminder from box
    final box = HiveDatabase.remindersBox;
    ReminderModel? foundReminder;
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final r = ReminderModel.fromMap(Map<String, dynamic>.from(data));
        if (r.id.hashCode == id) {
          foundReminder = r;
          break;
        }
      }
    }

    if (foundReminder != null) {
      // 1. Vibration
      if (foundReminder.vibrationEnabled) {
        await VibrationService.vibrateAlarm();
      }

      // 2. Play TTS
      final spokenText = foundReminder.voiceMessage.isNotEmpty 
          ? foundReminder.voiceMessage 
          : "Reminder: ${foundReminder.title}. ${foundReminder.subtitle}";
      await TtsService.speak(spokenText);

      // 3. Fire local notification
      await NotificationService.showReminderNotification(
        id: foundReminder.id,
        title: foundReminder.title,
        body: foundReminder.subtitle.isNotEmpty ? foundReminder.subtitle : foundReminder.description,
        category: foundReminder.category,
      );

      // 4. Update reminder state & reschedule if recurring
      if (foundReminder.repeatOption != 'Once') {
        final nextTime = _calculateNextOccurrence(
          foundReminder.dateTime.add(const Duration(seconds: 10)), // Offset to move past current tick
          foundReminder,
        );
        final updated = foundReminder.copyWith(
          dateTime: nextTime,
          isMissed: false,
        );
        await box.put(updated.id, updated.toMap());
        // Schedule next occurrence
        await scheduleAlarm(updated);
      } else {
        // Single reminder marked as missed (meaning pending user action, e.g. Complete or Dismiss)
        final updated = foundReminder.copyWith(
          isMissed: true,
        );
        await box.put(updated.id, updated.toMap());
      }
    }
  }

  static DateTime _calculateNextOccurrence(DateTime current, ReminderModel reminder) {
    DateTime target = current;
    final now = DateTime.now();

    // Loop until we find a target in the future
    while (target.isBefore(now)) {
      switch (reminder.repeatOption) {
        case 'Once':
          return target; // Return as-is, calling logic handles if past
        case 'Daily':
          target = target.add(const Duration(days: 1));
          break;
        case 'Weekly':
          target = target.add(const Duration(days: 7));
          break;
        case 'Monthly':
          target = DateTime(target.year, target.month + 1, target.day, target.hour, target.minute);
          break;
        case 'Yearly':
          target = DateTime(target.year + 1, target.month, target.day, target.hour, target.minute);
          break;
        case 'Weekdays':
          do {
            target = target.add(const Duration(days: 1));
          } while (target.weekday == DateTime.saturday || target.weekday == DateTime.sunday);
          break;
        case 'Weekends':
          do {
            target = target.add(const Duration(days: 1));
          } while (target.weekday != DateTime.saturday && target.weekday != DateTime.sunday);
          break;
        case 'Interval':
          final val = reminder.repeatIntervalValue > 0 ? reminder.repeatIntervalValue : 1;
          if (reminder.repeatIntervalUnit == 'Minutes') {
            target = target.add(Duration(minutes: val));
          } else if (reminder.repeatIntervalUnit == 'Hours') {
            target = target.add(Duration(hours: val));
          } else {
            target = target.add(Duration(days: val));
          }
          break;
        default:
          return target;
      }
    }
    return target;
  }
}
