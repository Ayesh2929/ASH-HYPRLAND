import 'package:flutter_local_notifications/flutter_local_notifications.dart';
class NotificationService {
  final plugin = FlutterLocalNotificationsPlugin();
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(android: android));
  }
}
