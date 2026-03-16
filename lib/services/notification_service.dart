import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
    tz.initializeTimeZones();
  }

  Future<void> schedulePrayerNotifications({
    required PrayerTimes prayerTimes, 
    required String azanSound, 
    required Map<String, bool> enabledPrayers
  }) async {
    // Clear all pending notifications
    await flutterLocalNotificationsPlugin.cancelAll();

    final prayers = [
      {'name': 'الفجر', 'time': prayerTimes.fajr},
      {'name': 'الظهر', 'time': prayerTimes.dhuhr},
      {'name': 'العصر', 'time': prayerTimes.asr},
      {'name': 'المغرب', 'time': prayerTimes.maghrib},
      {'name': 'العشاء', 'time': prayerTimes.isha},
    ];

    for (var i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final String prayerName = prayer['name'] as String;
      
      if (!(enabledPrayers[prayerName] ?? true)) continue;

      final DateTime time = prayer['time'] as DateTime;
      
      if (time.isAfter(DateTime.now())) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: i,
          title: 'حان الآن موعد صلاة $prayerName',
          body: 'أقم صلاتك يا عبد الله',
          scheduledDate: tz.TZDateTime.from(time, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_channel_custom_v2',
              'تنبيهات الصلاة',
              channelDescription: 'تنبيهات مواقيت الصلاة والأذان',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              sound: RawResourceAndroidNotificationSound(azanSound.split('.').first),
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }
}
