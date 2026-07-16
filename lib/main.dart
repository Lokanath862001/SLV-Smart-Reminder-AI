import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/ads/ad_service.dart';
import 'core/alarms/alarm_manager.dart';
import 'core/database/hive_database.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/tts/tts_service.dart';
import 'presentation/pages/main_container.dart';
import 'presentation/state/settings_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone settings
  tz.initializeTimeZones();
  
  // Local Database init
  await HiveDatabase.init();
  
  // Local Notifications init
  await NotificationService.init();
  
  // Alarm reschedulers init
  await AlarmManagerService.init();
  
  // TTS init
  await TtsService.init();
  
  // Google Ads init
  await AdService.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    ThemeMode getThemeMode(String mode) {
      switch (mode) {
        case 'Light':
          return ThemeMode.light;
        case 'Dark':
        case 'OLED':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    }

    return MaterialApp(
      title: 'SLV Smart Reminder AI',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.getTheme(
        themeMode: 'Light',
        themeColor: settings.themeColor,
        fontSize: settings.fontSize,
      ),
      darkTheme: AppThemes.getTheme(
        themeMode: settings.themeMode == 'OLED' ? 'OLED' : 'Dark',
        themeColor: settings.themeColor,
        fontSize: settings.fontSize,
      ),
      themeMode: getThemeMode(settings.themeMode),
      home: const MainContainer(),
    );
  }
}
