import '../../core/database/hive_database.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../models/reminder_model.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  @override
  Future<List<ReminderModel>> getAllReminders() async {
    final box = HiveDatabase.remindersBox;
    final List<ReminderModel> reminders = [];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        // Safe cast from Map to Map<String, dynamic>
        final Map<String, dynamic> map = Map<String, dynamic>.from(data);
        reminders.add(ReminderModel.fromMap(map));
      }
    }
    return reminders;
  }

  @override
  Future<ReminderModel?> getReminderById(String id) async {
    final box = HiveDatabase.remindersBox;
    final data = box.get(id);
    if (data == null) return null;
    return ReminderModel.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> saveReminder(ReminderModel reminder) async {
    final box = HiveDatabase.remindersBox;
    await box.put(reminder.id, reminder.toMap());
  }

  @override
  Future<void> deleteReminder(String id) async {
    final box = HiveDatabase.remindersBox;
    await box.delete(id);
  }

  @override
  Future<void> clearAllReminders() async {
    final box = HiveDatabase.remindersBox;
    await box.clear();
  }
}
