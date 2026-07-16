import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/models/reminder_model.dart';
import '../database/hive_database.dart';

class BackupService {
  // Export all reminders to a JSON file in the App documents directory
  static Future<String> exportToJson(List<ReminderModel> reminders) async {
    final List<Map<String, dynamic>> maps = reminders.map((r) => r.toMap()).toList();
    final jsonString = json.encode(maps);
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/slv_reminders_backup.json');
    await file.writeAsString(jsonString);
    return file.path;
  }

  // Import reminders from a JSON string or file content
  static Future<List<ReminderModel>> importFromJson(String jsonContent) async {
    final List<dynamic> decoded = json.decode(jsonContent);
    final List<ReminderModel> reminders = [];
    final box = HiveDatabase.remindersBox;
    
    for (var item in decoded) {
      if (item is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        final reminder = ReminderModel.fromMap(map);
        reminders.add(reminder);
        // Save to Hive database
        await box.put(reminder.id, reminder.toMap());
      }
    }
    return reminders;
  }

  // Export reminders to a CSV format and save it
  static Future<String> exportToCsv(List<ReminderModel> reminders) async {
    final buffer = StringBuffer();
    // Headers
    buffer.writeln('ID,Title,Subtitle,Description,Category,Priority,DateTime,RepeatOption,VoiceMessage,IsCompleted,IsMissed,Notes');
    
    for (var r in reminders) {
      // Escape strings containing commas or quotes
      String escape(String value) {
        final cleanVal = value.replaceAll('"', '""');
        if (cleanVal.contains(',') || cleanVal.contains('\n') || cleanVal.contains('"')) {
          return '"$cleanVal"';
        }
        return cleanVal;
      }

      buffer.writeln([
        r.id,
        escape(r.title),
        escape(r.subtitle),
        escape(r.description),
        escape(r.category),
        r.priority,
        r.dateTime.toIso8601String(),
        r.repeatOption,
        escape(r.voiceMessage),
        r.isCompleted.toString(),
        r.isMissed.toString(),
        escape(r.notes),
      ].join(','));
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/slv_reminders_backup.csv');
    await file.writeAsString(buffer.toString());
    return file.path;
  }
}
