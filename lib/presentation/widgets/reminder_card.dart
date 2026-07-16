import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/reminder_model.dart';

class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onTap,
  });

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFE53935); // Crimson
      case 'Medium':
        return const Color(0xFFFFB300); // Amber
      default:
        return const Color(0xFF43A047); // Emerald/Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = Color(reminder.colorValue);
    final formattedTime = DateFormat('hh:mm a').format(reminder.dateTime);
    final formattedDate = DateFormat('dd MMM yyyy').format(reminder.dateTime);

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark ? cardColor.withOpacity(0.12) : cardColor.withOpacity(0.06),
                  isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category Icon / Emoji
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    reminder.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Priority indicator dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getPriorityColor(reminder.priority),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reminder.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: reminder.isCompleted 
                                    ? TextDecoration.lineThrough 
                                    : null,
                                color: reminder.isCompleted
                                    ? theme.colorScheme.onSurface.withOpacity(0.4)
                                    : theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.subtitle.isNotEmpty ? reminder.subtitle : reminder.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Time, Date & Repeat Tags
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, 
                            size: 14, 
                            color: theme.colorScheme.primary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_month, 
                            size: 14, 
                            color: theme.colorScheme.primary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodySmall,
                          ),
                          if (reminder.repeatOption != 'Once') ...[
                            const SizedBox(width: 12),
                            Icon(Icons.loop, 
                              size: 14, 
                              color: theme.colorScheme.secondary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              reminder.repeatOption,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Done Checkbox button
                IconButton(
                  icon: Icon(
                    reminder.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: reminder.isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                    size: 28,
                  ),
                  onPressed: onToggleComplete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
