import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';
import 'quote_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final StreamController<String?> onNotificationReceived =
      StreamController<String?>.broadcast();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationReceived.add(response.payload);
      },
    );
    tz.initializeTimeZones();

    // Guess local timezone from system offset to avoid using flutter_timezone plugin
    final int offsetMilliseconds = DateTime.now().timeZoneOffset.inMilliseconds;

    // Default to the first location (e.g., Africa/Abidjan) if nothing matches
    String bestLocation = tz.timeZoneDatabase.locations.keys.first;

    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.currentTimeZone.offset == offsetMilliseconds) {
        bestLocation = loc.name;
        if (bestLocation.contains('Cairo') ||
            bestLocation.contains('Riyadh') ||
            bestLocation.contains('Dubai')) {
          break; // shortcut for MENA region
        }
      }
    }
    tz.setLocalLocation(tz.getLocation(bestLocation));
  }

  Future<void> testSchedule(int seconds, String azanSound) async {
    final DateTime scheduledTime = DateTime.now().add(Duration(seconds: seconds));
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 888, // Unique ID for test
      title: 'تجربة تنبيه الصلاة (DND Bypass)',
      body: 'هذا التنبيه مصنف كمنبه (Alarm) لتخطي وضع الصامت',
      payload: 'Test Prayer High',
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel_v5',
          'تنبيهات التجربة القصوى',
          channelDescription: 'قناة اختبار لتخطي وضع الصامت والـ DND',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(azanSound.split('.').first),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    
    // For in-app testing: also trigger the stream after X seconds if the app is open
    Timer(Duration(seconds: seconds), () {
       onNotificationReceived.add('Test Prayer High');
    });
  }

  Future<void> schedulePrayerNotifications({
    required PrayerTimes prayerTimes,
    required String azanSound,
    required Map<String, bool> enabledPrayers,
  }) async {
    // Clear all pending notifications
    await flutterLocalNotificationsPlugin.cancelAll();

    final prayers = [
      {'name': 'الفجر', 'time': prayerTimes.fajr, 'isAzkar': false},
      {
        'name': 'أذكار الصباح',
        'time': prayerTimes.fajr.add(const Duration(minutes: 45)),
        'isAzkar': true,
      },
      {'name': 'الظهر', 'time': prayerTimes.dhuhr, 'isAzkar': false},
      {'name': 'العصر', 'time': prayerTimes.asr, 'isAzkar': false},
      {
        'name': 'أذكار المساء',
        'time': prayerTimes.asr.add(const Duration(minutes: 30)),
        'isAzkar': true,
      },
      {'name': 'المغرب', 'time': prayerTimes.maghrib, 'isAzkar': false},
      {'name': 'العشاء', 'time': prayerTimes.isha, 'isAzkar': false},
    ];

    // Schedule Prayer & Azkar Notifications
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
          payload: isAzkar ? 'Azkar' : prayerName,
          scheduledDate: tz.TZDateTime.from(time, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              isAzkar
                  ? 'azkar_channel'
                  : 'prayer_channel_${azanSound.split('.').first}_v3',
              isAzkar ? 'تنبيهات الأذكار' : 'تنبيهات الصلاة',
              channelDescription: isAzkar
                  ? 'تنبيهات أذكار الصباح والمساء'
                  : 'تنبيهات مواقيت الصلاة والأذان',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              sound: isAzkar
                  ? null
                  : RawResourceAndroidNotificationSound(
                      azanSound.split('.').first,
                    ),
              audioAttributesUsage: AudioAttributesUsage.alarm,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        // Also setup a timer if foreground
        final diff = time.difference(DateTime.now());
        Timer(diff, () {
          onNotificationReceived.add(isAzkar ? 'Azkar' : prayerName);
        });
      }
    }

    // Schedule Daily Ayah/Hadith Notification at 9:00 AM
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 9, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final dailyQuote = QuoteService.getDailyQuote();
    // Default to Arabic for notification body since it's the primary language
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 999, // Unique ID for daily quote
      title: 'آية اليوم',
      body: dailyQuote.textAr,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_quote_channel',
          'آية أو حديث اليوم',
          channelDescription: 'تنبيهات يومية بآيات قرآنية وأحاديث نبوية',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
