import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/alarms/alarm_manager.dart';
import '../../core/backup/backup_service.dart';
import '../../core/notifications/notification_service.dart';
import '../../data/models/reminder_model.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/repositories/reminder_repository.dart';
import 'settings_state.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl();
});

class ReminderNotifier extends StateNotifier<List<ReminderModel>> {
  final ReminderRepository _repository;
  final Ref _ref;

  ReminderNotifier(this._repository, this._ref) : super([]) {
    loadReminders();
  }

  Future<void> loadReminders() async {
    final list = await _repository.getAllReminders();
    // Sort: earliest date first
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    state = list;
  }

  Future<void> addReminder(ReminderModel reminder) async {
    await _repository.saveReminder(reminder);
    await AlarmManagerService.scheduleAlarm(reminder);
    await loadReminders();
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    // Cancel old alarm
    await AlarmManagerService.cancelAlarm(reminder.id);
    await _repository.saveReminder(reminder);
    // Schedule updated alarm
    await AlarmManagerService.scheduleAlarm(reminder);
    await loadReminders();
  }

  Future<void> deleteReminder(String id) async {
    await AlarmManagerService.cancelAlarm(id);
    await NotificationService.cancel(id);
    await _repository.deleteReminder(id);
    await loadReminders();
  }

  Future<void> toggleComplete(String id) async {
    final reminder = state.firstWhere((r) => r.id == id);
    final isNowCompleted = !reminder.isCompleted;
    
    final updated = reminder.copyWith(
      isCompleted: isNowCompleted,
      isMissed: false,
      completedAt: isNowCompleted ? DateTime.now() : null,
    );

    // Cancel current notification/alarm
    await AlarmManagerService.cancelAlarm(id);
    await NotificationService.cancel(id);

    await _repository.saveReminder(updated);

    if (isNowCompleted) {
      // Increment completion streak
      await _ref.read(settingsProvider.notifier).incrementStreak();
    } else {
      // If unmarked, reschedule if not in the past
      if (updated.dateTime.isAfter(DateTime.now())) {
        await AlarmManagerService.scheduleAlarm(updated);
      }
    }
    await loadReminders();
  }

  Future<void> snoozeReminder(String id, int minutes) async {
    final reminder = state.firstWhere((r) => r.id == id);
    final snoozedTime = DateTime.now().add(Duration(minutes: minutes));
    
    final updated = reminder.copyWith(
      dateTime: snoozedTime,
      isMissed: false,
      snoozeCount: reminder.snoozeCount + 1,
    );

    await AlarmManagerService.cancelAlarm(id);
    await NotificationService.cancel(id);
    await _repository.saveReminder(updated);
    await AlarmManagerService.scheduleAlarm(updated);
    await loadReminders();
  }

  Future<void> clearAll() async {
    for (var r in state) {
      await AlarmManagerService.cancelAlarm(r.id);
      await NotificationService.cancel(r.id);
    }
    await _repository.clearAllReminders();
    state = [];
  }

  Future<void> importBackup(String jsonContent) async {
    await BackupService.importFromJson(jsonContent);
    await loadReminders();
    // Reschedule all imported reminders
    for (var r in state) {
      if (!r.isCompleted && r.dateTime.isAfter(DateTime.now())) {
        await AlarmManagerService.scheduleAlarm(r);
      }
    }
  }
}

final reminderProvider = StateNotifierProvider<ReminderNotifier, List<ReminderModel>>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return ReminderNotifier(repo, ref);
});
