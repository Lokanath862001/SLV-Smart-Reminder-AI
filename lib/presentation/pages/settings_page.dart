import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/backup/backup_service.dart';
import '../../core/tts/tts_service.dart';
import '../../core/utils/permission_helper.dart';
import '../state/reminder_state.dart';
import '../state/settings_state.dart';
import '../widgets/ad_banner_widget.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _backupStatusMessage = "";

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Backup & Restore"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text("Export JSON Backup"),
                subtitle: const Text("Saves to App Documents"),
                onTap: () async {
                  Navigator.pop(context);
                  final list = ref.read(reminderProvider);
                  try {
                    final path = await BackupService.exportToJson(list);
                    setState(() {
                      _backupStatusMessage = "Backup saved successfully to: $path";
                    });
                  } catch (e) {
                    setState(() {
                      _backupStatusMessage = "Export failed: $e";
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload, color: Colors.blue),
                title: const Text("Restore Local Backup"),
                subtitle: const Text("Restores slv_reminders_backup.json"),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final directory = await getApplicationDocumentsDirectory();
                    final file = File('${directory.path}/slv_reminders_backup.json');
                    if (await file.exists()) {
                      final content = await file.readAsString();
                      await ref.read(reminderProvider.notifier).importBackup(content);
                      setState(() {
                        _backupStatusMessage = "Reminders successfully restored!";
                      });
                    } else {
                      setState(() {
                        _backupStatusMessage = "No backup file found at Documents folder.";
                      });
                    }
                  } catch (e) {
                    setState(() {
                      _backupStatusMessage = "Restore failed: $e";
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.orange),
                title: const Text("Export CSV File"),
                subtitle: const Text("Saves table format data"),
                onTap: () async {
                  Navigator.pop(context);
                  final list = ref.read(reminderProvider);
                  try {
                    final path = await BackupService.exportToCsv(list);
                    setState(() {
                      _backupStatusMessage = "CSV saved to: $path";
                    });
                  } catch (e) {
                    setState(() {
                      _backupStatusMessage = "CSV export failed: $e";
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }

  void _showBatteryGuide() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Battery Optimization Guide"),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "To ensure alarms trigger on time, please allow background execution:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text("1. Click the 'Request battery settings' button below."),
                Text("2. Locate 'SLV Smart Reminder AI' in the app list."),
                Text("3. Choose 'Don't Optimize' or 'Unrestricted' battery access."),
                SizedBox(height: 12),
                Text(
                  "On custom OS (Xiaomi, OnePlus, Huawei, Samsung):",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("- Enable 'Auto-start' permissions for the app."),
                Text("- Lock the app in the recent tasks view."),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                PermissionHelper.requestBatteryOptimizationPermission();
                Navigator.pop(context);
              },
              child: const Text("Request battery settings"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Dismiss"),
            ),
          ],
        );
      },
    );
  }

  void _showAboutPage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("About SLV Smart Reminder AI"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "SLV Smart Reminder AI",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 4),
              Text("Version 1.0.0"),
              SizedBox(height: 12),
              Text(
                "Your Gentle Voice Companion for Every Moment.\n"
                "Designed entirely offline with high-performance exact alarm reschedulers.",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text("Developed by SLV Tech Solutions."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Privacy Policy"),
          content: const SingleChildScrollView(
            child: Text(
              "SLV Smart Reminder AI runs 100% offline. We do not transmit or collect your reminders, notes, schedules, calendar events, or voice metrics. All configurations are stored locally on your device.\n\n"
              "Google AdMob uses basic device identifiers to serve non-personalized advertisements, which requires standard Internet access. No other data tracking is implemented.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("I Understand"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings & Preferences"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Backup message banner
          if (_backupStatusMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _backupStatusMessage,
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _backupStatusMessage = ""),
                  )
                ],
              ),
            ),
          ],

          // Theme Settings Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Appearance Theme", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: settings.themeMode,
                    decoration: InputDecoration(
                      labelText: "Mode",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['System', 'Light', 'Dark', 'OLED']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).updateThemeMode(val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: settings.themeColor,
                    decoration: InputDecoration(
                      labelText: "Accent Color",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Purple', 'Blue', 'Green', 'Pink', 'Orange']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).updateThemeColor(val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Typography Settings Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Typography & Accessibility", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: settings.fontSize,
                    decoration: InputDecoration(
                      labelText: "Text Scale Mode",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Small', 'Medium', 'Large']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).updateFontSize(val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // TTS settings card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Voice Reminder (Offline TTS)", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Pitch Slider
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text("Pitch")),
                      Expanded(
                        child: Slider(
                          value: settings.ttsPitch,
                          min: 0.5,
                          max: 2.0,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).updateTtsSettings(pitch: val);
                          },
                        ),
                      ),
                      Text(settings.ttsPitch.toStringAsFixed(1)),
                    ],
                  ),

                  // Speed Slider
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text("Speed")),
                      Expanded(
                        child: Slider(
                          value: settings.ttsSpeed,
                          min: 0.2,
                          max: 1.2,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).updateTtsSettings(speed: val);
                          },
                        ),
                      ),
                      Text(settings.ttsSpeed.toStringAsFixed(1)),
                    ],
                  ),

                  // Volume Slider
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text("Volume")),
                      Expanded(
                        child: Slider(
                          value: settings.ttsVolume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).updateTtsSettings(volume: val);
                          },
                        ),
                      ),
                      Text(settings.ttsVolume.toStringAsFixed(1)),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.volume_up),
                    label: const Text("Listen to Voice Sample"),
                    onPressed: () {
                      TtsService.speak("This is a sample voice notification from S L V Smart Reminder AI.");
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Goals & Snooze configurations
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Goals & Alarms", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: settings.snoozeDurationMinutes,
                          decoration: InputDecoration(
                            labelText: "Snooze Interval",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: [5, 10, 15, 30]
                              .map((m) => DropdownMenuItem(value: m, child: Text("$m minutes")))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(settingsProvider.notifier).updateSnoozeDuration(val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: settings.dailyGoal,
                          decoration: InputDecoration(
                            labelText: "Daily Target",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: [1, 2, 3, 5, 7, 10]
                              .map((g) => DropdownMenuItem(value: g, child: Text("$g reminders")))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(settingsProvider.notifier).updateDailyGoal(val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Actions List (Backup, Battery, Privacy, About)
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.blue),
            title: const Text("Backup & Restore Data"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showBackupDialog,
          ),
          ListTile(
            leading: const Icon(Icons.battery_alert, color: Colors.orange),
            title: const Text("Battery Optimization Guide"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showBatteryGuide,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.teal),
            title: const Text("Privacy Policy"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPrivacyPolicy,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text("About App"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAboutPage,
          ),

          const SizedBox(height: 80),
        ],
      ),
      bottomSheet: const AdBannerWidget(),
    );
  }
}
