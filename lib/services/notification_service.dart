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
    
    // Guess local timezone from system offset to avoid using flutter_timezone plugin
    final int offsetMilliseconds = DateTime.now().timeZoneOffset.inMilliseconds;
    
    // Default to the first location (e.g., Africa/Abidjan) if nothing matches
    String bestLocation = tz.timeZoneDatabase.locations.keys.first;

    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.currentTimeZone.offset == offsetMilliseconds) {
        bestLocation = loc.name;
        if (bestLocation.contains('Cairo') || bestLocation.contains('Riyadh') || bestLocation.contains('Dubai')) {
            break; // shortcut for MENA region
        }
      }
    }
    tz.setLocalLocation(tz.getLocation(bestLocation));
  }

  Future<void> schedulePrayerNotifications({
    required PrayerTimes prayerTimes, 
    required String azanSound, 
    required Map<String, bool> enabledPrayers
  }) async {
    // Clear all pending notifications
    await flutterLocalNotificationsPlugin.cancelAll();

    final prayers = [
      {'name': 'الفجر', 'time': prayerTimes.fajr, 'isAzkar': false},
      {'name': 'أذكار الصباح', 'time': prayerTimes.fajr.add(const Duration(minutes: 45)), 'isAzkar': true},
      {'name': 'الظهر', 'time': prayerTimes.dhuhr, 'isAzkar': false},
      {'name': 'العصر', 'time': prayerTimes.asr, 'isAzkar': false},
      {'name': 'أذكار المساء', 'time': prayerTimes.asr.add(const Duration(minutes: 30)), 'isAzkar': true},
      {'name': 'المغرب', 'time': prayerTimes.maghrib, 'isAzkar': false},
      {'name': 'العشاء', 'time': prayerTimes.isha, 'isAzkar': false},
    ];

    for (var i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final String prayerName = prayer['name'] as String;
      
      if (!(enabledPrayers[prayerName] ?? true)) continue;

      final DateTime time = prayer['time'] as DateTime;
      final bool isAzkar = (prayer['isAzkar'] as bool?) ?? false;

      if (time.isAfter(DateTime.now())) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: i,
          title: isAzkar ? prayerName : 'حان الآن موعد صلاة $prayerName',
          body: isAzkar ? 'لا تنس ذكر الله' : 'أقم صلاتك يا عبد الله',
          scheduledDate: tz.TZDateTime.from(time, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              isAzkar ? 'azkar_channel' : 'prayer_channel_${azanSound.split('.').first}_v3',
              isAzkar ? 'تنبيهات الأذكار' : 'تنبيهات الصلاة',
              channelDescription: isAzkar ? 'تنبيهات أذكار الصباح والمساء' : 'تنبيهات مواقيت الصلاة والأذان',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              sound: isAzkar ? null : RawResourceAndroidNotificationSound(azanSound.split('.').first),
              audioAttributesUsage: AudioAttributesUsage.alarm,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }
}
