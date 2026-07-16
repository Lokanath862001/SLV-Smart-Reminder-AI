import 'dart:convert';

class ReminderModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime dateTime;
  final String repeatOption; // 'Once', 'Daily', 'Weekly', 'Monthly', 'Yearly', 'Weekdays', 'Weekends', 'Interval'
  final int repeatIntervalValue; // Number of minutes/hours/days if repeatOption is 'Interval'
  final String repeatIntervalUnit; // 'Minutes', 'Hours', 'Days'
  final int iconCodePoint;
  final int colorValue;
  final String emoji;
  final String voiceMessage;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool flashEnabled;
  final bool isCompleted;
  final bool isMissed;
  final int snoozeCount;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String notes;

  ReminderModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.priority,
    required this.dateTime,
    required this.repeatOption,
    this.repeatIntervalValue = 0,
    this.repeatIntervalUnit = 'Days',
    required this.iconCodePoint,
    required this.colorValue,
    required this.emoji,
    required this.voiceMessage,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.flashEnabled,
    required this.isCompleted,
    required this.isMissed,
    required this.snoozeCount,
    required this.createdAt,
    this.completedAt,
    required this.notes,
  });

  ReminderModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? category,
    String? priority,
    DateTime? dateTime,
    String? repeatOption,
    int? repeatIntervalValue,
    String? repeatIntervalUnit,
    int? iconCodePoint,
    int? colorValue,
    String? emoji,
    String? voiceMessage,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? flashEnabled,
    bool? isCompleted,
    bool? isMissed,
    int? snoozeCount,
    DateTime? createdAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dateTime: dateTime ?? this.dateTime,
      repeatOption: repeatOption ?? this.repeatOption,
      repeatIntervalValue: repeatIntervalValue ?? this.repeatIntervalValue,
      repeatIntervalUnit: repeatIntervalUnit ?? this.repeatIntervalUnit,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      emoji: emoji ?? this.emoji,
      voiceMessage: voiceMessage ?? this.voiceMessage,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      isMissed: isMissed ?? this.isMissed,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'category': category,
      'priority': priority,
      'dateTime': dateTime.toIso8601String(),
      'repeatOption': repeatOption,
      'repeatIntervalValue': repeatIntervalValue,
      'repeatIntervalUnit': repeatIntervalUnit,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'emoji': emoji,
      'voiceMessage': voiceMessage,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'flashEnabled': flashEnabled,
      'isCompleted': isCompleted,
      'isMissed': isMissed,
      'snoozeCount': snoozeCount,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? 'Medium',
      dateTime: DateTime.parse(map['dateTime']),
      repeatOption: map['repeatOption'] ?? 'Once',
      repeatIntervalValue: map['repeatIntervalValue'] ?? 0,
      repeatIntervalUnit: map['repeatIntervalUnit'] ?? 'Days',
      iconCodePoint: map['iconCodePoint'] ?? 0xe1b2, // default alarm icon
      colorValue: map['colorValue'] ?? 0xFF6200EE,
      emoji: map['emoji'] ?? '⏰',
      voiceMessage: map['voiceMessage'] ?? '',
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      flashEnabled: map['flashEnabled'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
      isMissed: map['isMissed'] ?? false,
      snoozeCount: map['snoozeCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ReminderModel.fromJson(String source) => ReminderModel.fromMap(json.decode(source));
}
