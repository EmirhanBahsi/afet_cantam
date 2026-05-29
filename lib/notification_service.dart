import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // Android'in kendi varsayılan uygulama ikonunu otomatik bulması için ayarlandı
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final int delayInMilliseconds = scheduledDate.difference(DateTime.now()).inMilliseconds;
    if (delayInMilliseconds <= 0) return;

    Future.delayed(Duration(milliseconds: delayInMilliseconds), () async {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'afet_canta_channel',
            'Afet Çantası Uyarıları',
            channelDescription: 'Son kullanma tarihi yaklaşan ürünlerin bildirimleri',
            importance: Importance.max,
            priority: Priority.high,
            // İKON HATASINI ÇÖZEN KRİTİK AYARLAR:
            // Eğer mipmap içinde bulamazsa Android'in kendi varsayılan ikon kütüphanesine paslar
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}