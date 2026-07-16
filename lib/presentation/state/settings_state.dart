import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/hive_database.dart';
import '../../core/tts/tts_service.dart';

class SettingsState {
  final String themeMode;
  final String themeColor;
  final String fontSize;
  final String locale;
  final double ttsPitch;
  final double ttsSpeed;
  final double ttsVolume;
  final int snoozeDurationMinutes;
  final int completionStreak;
  final String? lastCompletionDate;
  final int dailyGoal;

  SettingsState({
    required this.themeMode,
    required this.themeColor,
    required this.fontSize,
    required this.locale,
    required this.ttsPitch,
    required this.ttsSpeed,
    required this.ttsVolume,
    required this.snoozeDurationMinutes,
    required this.completionStreak,
    this.lastCompletionDate,
    required this.dailyGoal,
  });

  SettingsState copyWith({
    String? themeMode,
    String? themeColor,
    String? fontSize,
    String? locale,
    double? ttsPitch,
    double? ttsSpeed,
    double? ttsVolume,
    int? snoozeDurationMinutes,
    int? completionStreak,
    String? lastCompletionDate,
    int? dailyGoal,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
      fontSize: fontSize ?? this.fontSize,
      locale: locale ?? this.locale,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      ttsVolume: ttsVolume ?? this.ttsVolume,
      snoozeDurationMinutes: snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      completionStreak: completionStreak ?? this.completionStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          themeMode: 'System',
          themeColor: 'Purple',
          fontSize: 'Medium',
          locale: 'en',
          ttsPitch: 1.0,
          ttsSpeed: 0.5,
          ttsVolume: 1.0,
          snoozeDurationMinutes: 5,
          completionStreak: 0,
          lastCompletionDate: null,
          dailyGoal: 3,
        )) {
    loadSettings();
  }

  void loadSettings() {
    final box = HiveDatabase.settingsBox;
    state = SettingsState(
      themeMode: box.get('themeMode', defaultValue: 'System'),
      themeColor: box.get('themeColor', defaultValue: 'Purple'),
      fontSize: box.get('fontSize', defaultValue: 'Medium'),
      locale: box.get('locale', defaultValue: 'en'),
      ttsPitch: box.get('tts_pitch', defaultValue: 1.0),
      ttsSpeed: box.get('tts_speed', defaultValue: 0.5),
      ttsVolume: box.get('tts_volume', defaultValue: 1.0),
      snoozeDurationMinutes: box.get('snoozeDurationMinutes', defaultValue: 5),
      completionStreak: box.get('completionStreak', defaultValue: 0),
      lastCompletionDate: box.get('lastCompletionDate'),
      dailyGoal: box.get('dailyGoal', defaultValue: 3),
    );
  }

  Future<void> updateThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    await HiveDatabase.settingsBox.put('themeMode', mode);
  }

  Future<void> updateThemeColor(String color) async {
    state = state.copyWith(themeColor: color);
    await HiveDatabase.settingsBox.put('themeColor', color);
  }

  Future<void> updateFontSize(String size) async {
    state = state.copyWith(fontSize: size);
    await HiveDatabase.settingsBox.put('fontSize', size);
  }

  Future<void> updateLocale(String locale) async {
    state = state.copyWith(locale: locale);
    await HiveDatabase.settingsBox.put('locale', locale);
  }

  Future<void> updateTtsSettings({
    double? pitch,
    double? speed,
    double? volume,
  }) async {
    final newPitch = pitch ?? state.ttsPitch;
    final newSpeed = speed ?? state.ttsSpeed;
    final newVolume = volume ?? state.ttsVolume;
    
    state = state.copyWith(
      ttsPitch: newPitch,
      ttsSpeed: newSpeed,
      ttsVolume: newVolume,
    );

    await TtsService.updateSettings(
      pitch: newPitch,
      speed: newSpeed,
      volume: newVolume,
    );
  }

  Future<void> updateSnoozeDuration(int minutes) async {
    state = state.copyWith(snoozeDurationMinutes: minutes);
    await HiveDatabase.settingsBox.put('snoozeDurationMinutes', minutes);
  }

  Future<void> incrementStreak() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (state.lastCompletionDate == todayStr) return; // Already updated today

    int nextStreak = 1;
    if (state.lastCompletionDate != null) {
      final lastDate = DateTime.parse(state.lastCompletionDate!);
      final difference = DateTime.now().difference(lastDate).inDays;
      if (difference == 1) {
        nextStreak = state.completionStreak + 1;
      }
    }

    state = state.copyWith(
      completionStreak: nextStreak,
      lastCompletionDate: todayStr,
    );

    await HiveDatabase.settingsBox.put('completionStreak', nextStreak);
    await HiveDatabase.settingsBox.put('lastCompletionDate', todayStr);
  }

  Future<void> updateDailyGoal(int goal) async {
    state = state.copyWith(dailyGoal: goal);
    await HiveDatabase.settingsBox.put('dailyGoal', goal);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
