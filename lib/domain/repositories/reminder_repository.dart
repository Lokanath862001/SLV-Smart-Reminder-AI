import '../../data/models/reminder_model.dart';

abstract class ReminderRepository {
  Future<List<ReminderModel>> getAllReminders();
  Future<ReminderModel?> getReminderById(String id);
  Future<void> saveReminder(ReminderModel reminder);
  Future<void> deleteReminder(String id);
  Future<void> clearAllReminders();
}
