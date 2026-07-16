import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../state/reminder_state.dart';
import '../state/settings_state.dart';
import '../widgets/ad_banner_widget.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(reminderProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalCount = reminders.length;
    final completedCount = reminders.where((r) => r.isCompleted).length;
    final missedCount = reminders.where((r) => r.isMissed && !r.isCompleted).length;
    final pendingCount = reminders.where((r) => !r.isCompleted && !r.isMissed).length;

    // Calculate Completion Rate
    final completionRate = totalCount > 0 
        ? ((completedCount / totalCount) * 100).toStringAsFixed(1) 
        : "0.0";

    // Completed Today Count
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final completedToday = reminders.where((r) {
      if (r.completedAt == null) return false;
      return DateFormat('yyyy-MM-dd').format(r.completedAt!) == todayStr;
    }).length;

    // Goals progress
    final goalPercent = settings.dailyGoal > 0 
        ? (completedToday / settings.dailyGoal).clamp(0.0, 1.0) 
        : 0.0;

    // Group items by category to display distribution list
    final Map<String, int> categoryCounts = {};
    for (var r in reminders) {
      categoryCounts[r.category] = (categoryCounts[r.category] ?? 0) + 1;
    }
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics & Progress"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Completion rate circular summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Completion Rate",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You completed $completedCount out of $totalCount reminders total.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text("🔥", style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            "${settings.completionStreak} Day Streak",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                // Ring progress chart
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: totalCount > 0 ? completedCount / totalCount : 0.0,
                        strokeWidth: 10,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      "$completionRate%",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Daily Goal progress card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Daily Completion Goal",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "$completedToday / ${settings.dailyGoal}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: goalPercent,
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completedToday >= settings.dailyGoal ? Colors.green : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    completedToday >= settings.dailyGoal 
                        ? "🎉 Congratulations! You achieved today's reminder goal!"
                        : "Almost there! Complete ${settings.dailyGoal - completedToday} more to reach your goal.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Numeric Grid Stats
          Row(
            children: [
              _statGridCell(context, "Completed", "$completedCount", Colors.green),
              const SizedBox(width: 12),
              _statGridCell(context, "Missed", "$missedCount", Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statGridCell(context, "Pending", "$pendingCount", theme.colorScheme.primary),
              const SizedBox(width: 12),
              _statGridCell(context, "Total Saved", "$totalCount", Colors.purple),
            ],
          ),

          const SizedBox(height: 24),

          // Category distribution section
          Text(
            "Category Distribution",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (sortedCategories.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                "Create reminders to view category metrics",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            )
          else
            ...sortedCategories.map((entry) {
              final cat = entry.key;
              final count = entry.value;
              final percent = totalCount > 0 ? count / totalCount : 0.0;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _getCategoryEmoji(cat),
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cat, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                              Text("$count reminders", style: theme.textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          
          const SizedBox(height: 80),
        ],
      ),
      bottomSheet: const AdBannerWidget(),
    );
  }

  Widget _statGridCell(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'General': return '⏰';
      case 'Wake Up': return '🌅';
      case 'Sleep': return '🌙';
      case 'Medicine': return '💊';
      case 'Water': return '💧';
      case 'Exercise': return '🏋️';
      case 'Yoga': return '🧘';
      case 'Meditation': return '🧘';
      case 'Prayer': return '🙏';
      case 'Food': return '🍽️';
      case 'Study': return '📚';
      case 'Office': return '💼';
      case 'Meeting': return '🤝';
      case 'Birthday': return '🎂';
      case 'Shopping': return '🛒';
      case 'Travel': return '✈️';
      case 'Bills': return '💳';
      default: return '⏰';
    }
  }
}
