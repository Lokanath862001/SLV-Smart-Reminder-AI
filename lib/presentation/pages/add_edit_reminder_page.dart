import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/reminder_model.dart';
import '../state/reminder_state.dart';

class AddEditReminderPage extends ConsumerStatefulWidget {
  final ReminderModel? reminder;
  const AddEditReminderPage({super.key, this.reminder});

  @override
  ConsumerState<AddEditReminderPage> createState() => _AddEditReminderPageState();
}

class _AddEditReminderPageState extends ConsumerState<AddEditReminderPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _descriptionController;
  late TextEditingController _voiceMsgController;
  late TextEditingController _notesController;
  
  late String _selectedCategory;
  late String _selectedPriority;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _repeatOption;
  late int _repeatIntervalValue;
  late String _repeatIntervalUnit;
  late String _selectedEmoji;
  late int _selectedColorValue;
  late bool _soundEnabled;
  late bool _vibrationEnabled;
  late bool _flashEnabled;

  final List<String> _categories = [
    'General', 'Wake Up', 'Sleep', 'Medicine', 'Water', 'Exercise', 'Yoga', 'Meditation', 
    'Prayer', 'Food', 'Study', 'Office', 'Meeting', 'Birthday', 'Shopping', 'Travel', 'Bills'
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  final List<String> _repeatOptions = [
    'Once', 'Daily', 'Weekly', 'Monthly', 'Yearly', 'Weekdays', 'Weekends', 'Interval'
  ];

  final List<String> _intervalUnits = ['Minutes', 'Hours', 'Days'];

  final Map<String, String> _categoryEmojis = {
    'General': '⏰',
    'Wake Up': '🌅',
    'Sleep': '🌙',
    'Medicine': '💊',
    'Water': '💧',
    'Exercise': '🏋️',
    'Yoga': '🧘',
    'Meditation': '🧘',
    'Prayer': '🙏',
    'Food': '🍽️',
    'Study': '📚',
    'Office': '💼',
    'Meeting': '🤝',
    'Birthday': '🎂',
    'Shopping': '🛒',
    'Travel': '✈️',
    'Bills': '💳',
  };

  final List<int> _colors = [
    0xFF9C27B0, // Purple
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFFFB300, // Amber
    0xFFFF5722, // Deep Orange
    0xFFE91E63, // Pink
    0xFF009688, // Teal
    0xFF607D8B, // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    
    _titleController = TextEditingController(text: r?.title ?? '');
    _subtitleController = TextEditingController(text: r?.subtitle ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _voiceMsgController = TextEditingController(text: r?.voiceMessage ?? '');
    _notesController = TextEditingController(text: r?.notes ?? '');

    _selectedCategory = r?.category ?? 'General';
    _selectedPriority = r?.priority ?? 'Medium';
    _selectedDate = r?.dateTime ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(r?.dateTime ?? DateTime.now());
    _repeatOption = r?.repeatOption ?? 'Once';
    _repeatIntervalValue = r?.repeatIntervalValue ?? 1;
    _repeatIntervalUnit = r?.repeatIntervalUnit ?? 'Days';
    _selectedEmoji = r?.emoji ?? '⏰';
    _selectedColorValue = r?.colorValue ?? 0xFF9C27B0;
    _soundEnabled = r?.soundEnabled ?? true;
    _vibrationEnabled = r?.vibrationEnabled ?? true;
    _flashEnabled = r?.flashEnabled ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _voiceMsgController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _onCategoryChanged(String? val) {
    if (val != null) {
      setState(() {
        _selectedCategory = val;
        _selectedEmoji = _categoryEmojis[val] ?? '⏰';
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final targetDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // If targetDateTime is in past for single alarm, automatically adjust to today/tomorrow
    var alarmTime = targetDateTime;
    if (_repeatOption == 'Once' && alarmTime.isBefore(DateTime.now())) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final id = widget.reminder?.id ?? const Uuid().v4();
    final newReminder = ReminderModel(
      id: id,
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      dateTime: alarmTime,
      repeatOption: _repeatOption,
      repeatIntervalValue: _repeatIntervalValue,
      repeatIntervalUnit: _repeatIntervalUnit,
      iconCodePoint: Icons.alarm.codePoint,
      colorValue: _selectedColorValue,
      emoji: _selectedEmoji,
      voiceMessage: _voiceMsgController.text.trim().isNotEmpty
          ? _voiceMsgController.text.trim()
          : "Attention: ${_titleController.text.trim()} is starting now.",
      soundEnabled: _soundEnabled,
      vibrationEnabled: _vibrationEnabled,
      flashEnabled: _flashEnabled,
      isCompleted: widget.reminder?.isCompleted ?? false,
      isMissed: false,
      snoozeCount: 0,
      createdAt: widget.reminder?.createdAt ?? DateTime.now(),
      notes: _notesController.text.trim(),
    );

    if (widget.reminder == null) {
      ref.read(reminderProvider.notifier).addReminder(newReminder);
    } else {
      ref.read(reminderProvider.notifier).updateReminder(newReminder);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? "Create Reminder" : "Edit Reminder"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title input
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
            ),
            const SizedBox(height: 16),

            // Subtitle input
            TextFormField(
              controller: _subtitleController,
              decoration: InputDecoration(
                labelText: "Subtitle (e.g. 1 Tablet)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.subtitles),
              ),
            ),
            const SizedBox(height: 16),

            // Category & Priority Grid/Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: _categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text("${_categoryEmojis[c] ?? '⏰'} $c"),
                    )).toList(),
                    onChanged: _onCategoryChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: InputDecoration(
                      labelText: "Priority",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: _priorities.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPriority = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date & Time Selectors
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.38)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                          Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.38)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedTime.format(context)),
                          Icon(Icons.access_time, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Repeat Configuration
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Recurrence Schedule", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _repeatOption,
                      decoration: InputDecoration(
                        labelText: "Repeat Pattern",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _repeatOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _repeatOption = val);
                      },
                    ),
                    if (_repeatOption == 'Interval') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _repeatIntervalValue.toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Every (value)",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _repeatIntervalValue = int.tryParse(val) ?? 1;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _repeatIntervalUnit,
                              decoration: InputDecoration(
                                labelText: "Unit",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _intervalUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _repeatIntervalUnit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color Swatch Selection
            Text("Card Accent Color", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final colorVal = _colors[index];
                  final isSelected = _selectedColorValue == colorVal;
                  return InkWell(
                    onTap: () => setState(() => _selectedColorValue = colorVal),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: isSelected ? BorderSide(color: isDark ? Colors.white : Colors.black, width: 3) : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // TTS customized spoken message
            TextFormField(
              controller: _voiceMsgController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Custom Spoken Message (Offline TTS)",
                hintText: "E.g. Good morning, please drink a fresh glass of water now.",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.record_voice_over),
              ),
            ),
            const SizedBox(height: 16),

            // Haptics and Alarm settings
            SwitchListTile(
              title: const Text("Alarm Sound"),
              subtitle: const Text("Play default alarm notification sound"),
              value: _soundEnabled,
              onChanged: (val) => setState(() => _soundEnabled = val),
            ),
            SwitchListTile(
              title: const Text("Intense Alarm Vibration"),
              subtitle: const Text("Vibrate device when reminder alarms trigger"),
              value: _vibrationEnabled,
              onChanged: (val) => setState(() => _vibrationEnabled = val),
            ),
            const SizedBox(height: 16),

            // Description / Notes
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Notes & Tasks",
                hintText: "Add task items, descriptions or attachments info here",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 36),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _save,
              child: Text(
                widget.reminder == null ? "Schedule Reminder" : "Update Schedule",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
