import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveDatabase {
  static const String remindersBoxName = 'reminders_box';
  static const String settingsBoxName = 'settings_box';

  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(directory.path);
    
    // Open boxes
    await Hive.openBox<Map>(remindersBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<Map> get remindersBox => Hive.box<Map>(remindersBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);

  static Future<void> clearAll() async {
    await remindersBox.clear();
    await settingsBox.clear();
  }
}
