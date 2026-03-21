import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';
import 'package:permission_handler/permission_handler.dart';
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

    // Request permissions for Android 13+
    await _requestPermissions();

    tz.initializeTimeZones();

    // Guess local timezone from system offset to avoid using flutter_timezone plugin
    final Duration localOffset = DateTime.now().timeZoneOffset;

    // Default to the first location (e.g., Africa/Abidjan) if nothing matches
    String bestLocation = tz.timeZoneDatabase.locations.keys.first;

    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.currentTimeZone.offset == localOffset) {
         bestLocation = loc.name;
         // shortcut for MENA region
         if (bestLocation.contains('Cairo') || bestLocation.contains('Riyadh') || bestLocation.contains('Dubai')) {
           break; 
         }
      }
    }
    tz.setLocalLocation(tz.getLocation(bestLocation));
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Android 13+ requires explicit notification permission
      await androidImplementation?.requestNotificationsPermission();
      
      // Android 13+ also may require explicit exact alarm permission
      // This will open the settings page if it's not granted for Android 13 or 14.
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<bool> isNotificationPermissionGranted() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return true;
  }

  Future<bool> isExactAlarmPermissionGranted() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.canScheduleExactNotifications() ?? true;
    }
    return true;
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    if (Platform.isAndroid) {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    }
    return true;
  }

  Future<void> requestBatteryOptimization() async {
    if (Platform.isAndroid) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<void> requestAllPermissions() async {
    await _requestPermissions();
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
          'test_channel_v10',
          'تنبيهات التجربة القصوى',
          channelDescription: 'قناة اختبار لتخطي وضع الصامت والـ DND',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          ticker: 'تجربة تنبيه الصلاة',
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound(azanSound.split('.').first),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
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
    for (var i = 0; i < prayers.length * 2; i++) {
      // Loop twice: index 0-6 for today, 7-13 for tomorrow
      final dayOffset = i ~/ prayers.length;
      final prayerIndex = i % prayers.length;
      final prayer = prayers[prayerIndex];
      final String prayerName = prayer['name'] as String;

      if (!(enabledPrayers[prayerName] ?? true)) continue;

      DateTime time = prayer['time'] as DateTime;
      if (dayOffset > 0) {
        time = time.add(Duration(days: dayOffset));
      }
      
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
                  ? 'azkar_channel_v4'
                  : 'prayer_channel_${azanSound.split('.').first}_v12',
              isAzkar ? 'تنبيهات الأذكار' : 'تنبيهات الصلاة',
              channelDescription: isAzkar
                  ? 'تنبيهات أذكار الصباح والمساء'
                  : 'تنبيهات مواقيت الصلاة والأذان',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              ticker: 'حان وقت الصلاة',
              enableVibration: true,
              sound: isAzkar
                  ? null
                  : RawResourceAndroidNotificationSound(
                      azanSound.split('.').first,
                    ),
              audioAttributesUsage: AudioAttributesUsage.alarm,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        // Also setup a timer if foreground and it's today
        if (dayOffset == 0) {
          final diff = time.difference(DateTime.now());
          Timer(diff, () {
            onNotificationReceived.add(isAzkar ? 'Azkar' : prayerName);
          });
        }
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
