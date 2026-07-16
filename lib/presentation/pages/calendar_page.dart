import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/ads/ad_service.dart';
import '../../data/models/reminder_model.dart';
import '../state/reminder_state.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/reminder_card.dart';
import 'add_edit_reminder_page.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  // Generates 14 days around the selected date (7 days before, 7 days after)
  List<DateTime> _generateDayStrip() {
    final List<DateTime> list = [];
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 4));
    for (int i = 0; i < 14; i++) {
      list.add(start.add(Duration(days: i)));
    }
    return list;
  }

  Future<void> _selectCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(reminderProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Filter agenda reminders for selected date
    final agendaReminders = reminders.where((r) {
      final rDateStr = DateFormat('yyyy-MM-dd').format(r.dateTime);
      return rDateStr == selectedDateStr;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar Agenda"),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectCustomDate,
            tooltip: "Choose custom date",
          )
        ],
      ),
      body: Column(
        children: [
          // Selected Month Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMM').format(_selectedDate),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal day strip selector
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 14,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final date = _generateDayStrip()[index];
                final isSelected = DateFormat('yyyy-MM-dd').format(date) == selectedDateStr;
                
                // Count events for this strip day
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final eventCount = reminders.where((r) => DateFormat('yyyy-MM-dd').format(r.dateTime) == dateStr).length;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? theme.colorScheme.surface : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date)[0], // M, T, W, T...
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (eventCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : theme.colorScheme.secondary,
                            ),
                          )
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),

          // Agenda Details List
          Expanded(
            child: agendaReminders.isEmpty
                ? _emptyAgendaState(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: agendaReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = agendaReminders[index];
                      return ReminderCard(
                        reminder: reminder,
                        onToggleComplete: () => ref.read(reminderProvider.notifier).toggleComplete(reminder.id),
                        onDelete: () {
                          ref.read(reminderProvider.notifier).deleteReminder(reminder.id);
                          AdService.forceShowInterstitial();
                        },
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEditReminderPage(reminder: reminder),
                            ),
                          ).then((_) {
                            AdService.forceShowInterstitial();
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: const AdBannerWidget(),
    );
  }

  Widget _emptyAgendaState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "Clear Day!",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No reminders scheduled for this date.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
