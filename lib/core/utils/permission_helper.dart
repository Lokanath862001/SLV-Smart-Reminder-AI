import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  static Future<bool> requestBatteryOptimizationPermission() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  static Future<bool> requestOverlayPermission() async {
    final status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }

  static Future<bool> checkAllPermissions() async {
    final notification = await Permission.notification.isGranted;
    final alarm = await Permission.scheduleExactAlarm.isGranted;
    return notification && alarm;
  }

  static Future<void> requestAll() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();
    await Permission.systemAlertWindow.request();
  }
}
