import 'package:flutter_test/flutter_test.dart';
import 'package:slv_smart_reminder_ai/data/models/reminder_model.dart';

void main() {
  group('ReminderModel Tests', () {
    test('Should correctly convert model to and from Map', () {
      final now = DateTime.now();
      final reminder = ReminderModel(
        id: 'test-id-123',
        title: 'Drink Water',
        subtitle: '1 Glass',
        description: 'Stay hydrated throughout the day',
        category: 'Water',
        priority: 'High',
        dateTime: now,
        repeatOption: 'Daily',
        iconCodePoint: 12345,
        colorValue: 0xFFFFFFFF,
        emoji: '💧',
        voiceMessage: 'Drink a glass of water now.',
        soundEnabled: true,
        vibrationEnabled: true,
        flashEnabled: false,
        isCompleted: false,
        isMissed: false,
        snoozeCount: 0,
        createdAt: now,
        notes: 'Cold water preferred',
      );

      final map = reminder.toMap();
      final restored = ReminderModel.fromMap(map);

      expect(restored.id, 'test-id-123');
      expect(restored.title, 'Drink Water');
      expect(restored.subtitle, '1 Glass');
      expect(restored.priority, 'High');
      expect(restored.repeatOption, 'Daily');
      expect(restored.emoji, '💧');
      expect(restored.notes, 'Cold water preferred');
      expect(restored.dateTime.toIso8601String(), now.toIso8601String());
    });

    test('Should support copyWith updates', () {
      final now = DateTime.now();
      final reminder = ReminderModel(
        id: 'test-id-123',
        title: 'Drink Water',
        subtitle: '1 Glass',
        description: 'Stay hydrated',
        category: 'Water',
        priority: 'High',
        dateTime: now,
        repeatOption: 'Once',
        iconCodePoint: 12345,
        colorValue: 0xFFFFFFFF,
        emoji: '💧',
        voiceMessage: 'Drink water',
        soundEnabled: true,
        vibrationEnabled: true,
        flashEnabled: false,
        isCompleted: false,
        isMissed: false,
        snoozeCount: 0,
        createdAt: now,
        notes: '',
      );

      final updated = reminder.copyWith(
        title: 'Drink Cold Water',
        isCompleted: true,
      );

      expect(updated.title, 'Drink Cold Water');
      expect(updated.isCompleted, true);
      expect(updated.id, 'test-id-123'); // Unchanged
    });
  });
}
