import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/ads/ad_service.dart';
import '../../data/models/reminder_model.dart';
import '../state/reminder_state.dart';
import '../state/settings_state.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/animated_background.dart';
import '../widgets/reminder_card.dart';
import 'add_edit_reminder_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _countdownTimer;
  String _countdownText = "No upcoming reminders";
  ReminderModel? _nextReminder;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (!mounted) return;
    final reminders = ref.read(reminderProvider);
    final now = DateTime.now();

    // Find nearest incomplete future reminder
    final futureReminders = reminders
        .where((r) => !r.isCompleted && r.dateTime.isAfter(now))
        .toList();

    if (futureReminders.isEmpty) {
      if (_nextReminder != null || _countdownText != "No upcoming reminders") {
        setState(() {
          _nextReminder = null;
          _countdownText = "No upcoming reminders";
        });
      }
      return;
    }

    // Sort to find nearest
    futureReminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final next = futureReminders.first;
    final diff = next.dateTime.difference(now);

    String text;
    if (diff.inDays > 0) {
      text = "${diff.inDays}d ${diff.inHours % 24}h remaining";
    } else if (diff.inHours > 0) {
      text = "${diff.inHours}h ${diff.inMinutes % 60}m remaining";
    } else if (diff.inMinutes > 0) {
      text = "${diff.inMinutes}m ${diff.inSeconds % 60}s remaining";
    } else {
      text = "${diff.inSeconds}s remaining";
    }

    setState(() {
      _nextReminder = next;
      _countdownText = text;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else if (hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(reminderProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // Grouping reminders
    final todayReminders = reminders.where((r) {
      final rDateStr = DateFormat('yyyy-MM-dd').format(r.dateTime);
      return rDateStr == todayStr;
    }).toList();

    final upcomingReminders = reminders.where((r) {
      return r.dateTime.isAfter(now) && !r.isCompleted && DateFormat('yyyy-MM-dd').format(r.dateTime) != todayStr;
    }).toList();

    final completedCount = reminders.where((r) => r.isCompleted).length;
    final missedReminders = reminders.where((r) => r.isMissed && !r.isCompleted).toList();

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Welcome header + countdown
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onBackground.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              "Reminder Hub",
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Streak icon
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Text("🔥", style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 4),
                              Text(
                                "${settings.completionStreak} Days",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Countdown glass card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.85),
                            theme.colorScheme.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.alarm, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "NEXT UPCOMING REMINDER",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white70,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nextReminder?.title ?? "No Alarms Scheduled",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _countdownText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Metrics overview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _metricCard(
                      context, 
                      "Completed", 
                      "$completedCount", 
                      Colors.green,
                      Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 12),
                    _metricCard(
                      context, 
                      "Missed", 
                      "${missedReminders.length}", 
                      Colors.red,
                      Icons.error_outline,
                    ),
                    const SizedBox(width: 12),
                    _metricCard(
                      context, 
                      "Total Active", 
                      "${reminders.where((r) => !r.isCompleted).length}", 
                      theme.colorScheme.primary,
                      Icons.notifications_active_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Reminders list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (missedReminders.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "Missed / Overdue",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...missedReminders.map((r) => ReminderCard(
                        reminder: r,
                        onToggleComplete: () => ref.read(reminderProvider.notifier).toggleComplete(r.id),
                        onDelete: () {
                          ref.read(reminderProvider.notifier).deleteReminder(r.id);
                          AdService.forceShowInterstitial(); // Show ad on delete
                        },
                        onTap: () => _navigateToEdit(context, r),
                      )),
                    ],

                    const SizedBox(height: 16),
                    Text(
                      "Today's Schedule",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (todayReminders.isEmpty)
                      _emptyStateWidget(context, "No reminders for today. Enjoy your day!")
                    else
                      ...todayReminders.map((r) => ReminderCard(
                        reminder: r,
                        onToggleComplete: () => ref.read(reminderProvider.notifier).toggleComplete(r.id),
                        onDelete: () {
                          ref.read(reminderProvider.notifier).deleteReminder(r.id);
                          AdService.forceShowInterstitial(); // Show ad on delete
                        },
                        onTap: () => _navigateToEdit(context, r),
                      )),

                    const SizedBox(height: 16),
                    Text(
                      "Upcoming Schedule",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (upcomingReminders.isEmpty)
                      _emptyStateWidget(context, "No other upcoming reminders.")
                    else
                      ...upcomingReminders.map((r) => ReminderCard(
                        reminder: r,
                        onToggleComplete: () => ref.read(reminderProvider.notifier).toggleComplete(r.id),
                        onDelete: () {
                          ref.read(reminderProvider.notifier).deleteReminder(r.id);
                          AdService.forceShowInterstitial();
                        },
                        onTap: () => _navigateToEdit(context, r),
                      )),
                      
                    const SizedBox(height: 80), // bottom spacing for FAB and bottom nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _navigateToAdd(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.add),
      ),
      bottomSheet: const AdBannerWidget(), // persistent bottom banner ad
    );
  }

  Widget _metricCard(BuildContext context, String label, String value, Color color, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyStateWidget(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditReminderPage(),
      ),
    ).then((_) {
      AdService.forceShowInterstitial(); // Show Interstitial ad after reminder creation page closes!
    });
  }

  void _navigateToEdit(BuildContext context, ReminderModel reminder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditReminderPage(reminder: reminder),
      ),
    ).then((_) {
      AdService.forceShowInterstitial(); // Show Interstitial ad after edit closes
    });
  }
}
