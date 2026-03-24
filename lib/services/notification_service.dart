import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'quote_service.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const platform = MethodChannel('azan_channel');
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

    // Create notification channels explicitly for better reliability
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      // Create Prayer Channels for all available sounds to be safe
      final availableSounds = ['makah', 'egypt', 'abdelbaset', 'mohamedrefaat'];
      for (final s in availableSounds) {
        await androidImplementation?.createNotificationChannel(
          AndroidNotificationChannel(
            'prayer_channel_${s}_v31',
            'تنبيهات الصلاة ($s)',
            description: 'تنبيهات مواقيت الصلاة والأذان',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(s),
            audioAttributesUsage: AudioAttributesUsage.alarm,
            enableVibration: true,
          ),
        );
      }
      
      // Test Channel
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'test_channel_v31',
          'تنبيهات التجربة القصوى',
          description: 'قناة اختبار لتخطي وضع الصامت والـ DND',
          importance: Importance.max,
          playSound: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );

      // Azkar Channel
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'azkar_channel_v11',
          'تنبيهات الأذكار',
          description: 'تنبيهات أذكار الصباح والمساء',
          importance: Importance.max,
          playSound: true,
        ),
      );
    }

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
      try {
        await androidImplementation?.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('Error requesting exact alarms: $e');
      }
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

  Future<bool> isDNDAccessGranted() async {
    if (Platform.isAndroid) {
      return await Permission.accessNotificationPolicy.isGranted;
    }
    return true;
  }

  Future<void> requestDNDAccess() async {
    if (Platform.isAndroid) {
      await Permission.accessNotificationPolicy.request();
    }
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

  /// Comprehensive check for modern Android compatibility
  Future<Map<String, bool>> checkAzanCompatibility() async {
    final bool notif = await isNotificationPermissionGranted();
    final bool alarm = await isExactAlarmPermissionGranted();
    final bool battery = await isBatteryOptimizationIgnored();
    final bool dnd = await isDNDAccessGranted();
    
    return {
      'notification_permission': notif,
      'exact_alarm_permission': alarm,
      'battery_optimization_ignored': battery,
      'dnd_access': dnd,
      'is_fully_compatible': notif && alarm,
    };
  }

  Future<void> testSchedule(int seconds, String azanSound, double azanVolume) async {
    final DateTime scheduledTime = DateTime.now().add(Duration(seconds: seconds));
    
    // Regular notification for UI
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 888, 
      title: 'تجربة تنبيه الأذان (True Alarm)',
      body: 'سيبدأ الأذان خلال لحظات عبر خدمة الخلفية',
      payload: 'Test Prayer High',
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel_v31',
          'تنبيهات التجربة القصوى',
          channelDescription: 'قناة اختبار لتخطي وضع الصامت والـ DND',
          importance: Importance.max,
          priority: Priority.max,
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

    // Also schedule the TRUE Alarm via native Android AlarmManager
    if (Platform.isAndroid) {
      await platform.invokeMethod('scheduleAzan', {
        'time': scheduledTime.millisecondsSinceEpoch,
        'sound': azanSound.split('.').first,
        'volume': azanVolume,
        'prayerName': 'تجربة الأذان',
      });
    }
    
    Timer(Duration(seconds: seconds), () {
      onNotificationReceived.add('Test Prayer High');
    });
  }

  Future<void> schedulePrayerNotifications({
    required PrayerTimes prayerTimes,
    required String azanSound,
    required double azanVolume,
    required Map<String, bool> enabledPrayers,
  }) async {
    // Clear all pending notifications
    await flutterLocalNotificationsPlugin.cancelAll();
    
    // Clear all pending alarms (only cancel a small range to avoid excessive logs)
    // Clear all pending native alarms
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('cancelAllAlarms');
      } catch (e) {
        debugPrint('Error canceling native alarms: $e');
      }
    }

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

    for (var i = 0; i < prayers.length * 2; i++) {
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
        try {
          if (isAzkar) {
            // Use local notifications for Azkar and Ayah (Simple Notification)
            await flutterLocalNotificationsPlugin.zonedSchedule(
              id: i,
              title: prayerName,
              body: 'لا تنس ذكر الله',
              payload: 'Azkar',
              scheduledDate: tz.TZDateTime.from(time, tz.local),
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'azkar_channel_v11',
                  'تنبيهات الأذكار',
                  importance: Importance.max,
                  priority: Priority.max,
                  playSound: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );
          } else if (Platform.isAndroid) {
            // 🔥 Use ONLY Native AlarmManager for Azan (Ensures Reliability)
            await platform.invokeMethod('scheduleAzan', {
              'time': time.millisecondsSinceEpoch,
              'sound': azanSound.split('.').first,
              'volume': azanVolume,
              'prayerName': prayerName,
            });
          }
        } catch (e) {
          debugPrint('Error scheduling for $prayerName: $e');
        }
      }
    }

    // Daily Ayah
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 9, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final dailyQuote = QuoteService.getDailyQuote();
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 999, 
      title: 'آية اليوم',
      body: dailyQuote.textAr,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_quote_channel',
          'آية أو حديث اليوم',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
