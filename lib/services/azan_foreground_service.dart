import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:volume_controller/volume_controller.dart';

class AzanForegroundHandler extends TaskHandler {
  AudioPlayer? _audioPlayer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('AzanForegroundHandler started');
    _audioPlayer = AudioPlayer();
    
    // Configure audio context for background/foreground playback
    await _audioPlayer?.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
          contentType: AndroidContentType.music,
        ),
      ),
    );

    final String? azanSound = await FlutterForegroundTask.getData<String>(
      key: 'azanSound',
    );
    final double? volume = await FlutterForegroundTask.getData<double>(
      key: 'volume',
    );

    debugPrint('Foreground Task: Loading sound $azanSound at volume $volume');

    if (azanSound != null) {
      try {
        if (volume != null) {
          try {
            await VolumeController.instance.setVolume(volume);
          } catch (ve) {
            debugPrint('AB-DEBUG: VolumeController error: $ve');
          }
        }

        // Use the selected volume for both system and player for maximum effect
        await _audioPlayer?.setVolume(volume ?? 1.0);
        await _audioPlayer?.play(AssetSource('audio/$azanSound'));

        _audioPlayer?.onPlayerComplete.listen((_) {
          FlutterForegroundTask.stopService();
        });
      } catch (e) {
        FlutterForegroundTask.stopService();
      }
    } else {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Not used
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool startingBackground) async {
    debugPrint('AzanForegroundHandler destroyed');
    await _audioPlayer?.stop();
    await _audioPlayer?.dispose();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}

class AzanForegroundService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'azan_foreground_channel',
        channelName: 'خدمة الأذان (خلفية)',
        channelDescription: 'تضمن تشغيل الأذان في الوقت المحدد',
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.MAX,
        // Using default icon
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound:
            false, // Keeping this as per original, as the provided snippet is syntactically incorrect for this location.
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.once(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start(
    String azanSound, {
    double volume = 1.0,
    required String prayerName,
  }) async {
    // Ensure initialized if called from a background isolate
    init();

    await FlutterForegroundTask.saveData(key: 'azanSound', value: azanSound);
    await FlutterForegroundTask.saveData(key: 'volume', value: volume);

    if (await FlutterForegroundTask.isRunningService) {
      debugPrint('AzanForegroundService: Restarting service');
      await FlutterForegroundTask.restartService();
    } else {
      debugPrint('AzanForegroundService: Starting service for $prayerName');
      await FlutterForegroundTask.startService(
        notificationTitle: 'حان وقت صلاة $prayerName',
        notificationText: 'جاري تشغيل الأذان...',
        callback: startCallback,
      );
    }
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AzanForegroundHandler());
}

class NextPrayerCountdownHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _updateCountdown();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _updateCountdown();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool startingBackground) async {
    // No resources to dispose.
  }

  Future<void> _updateCountdown() async {
    final int? nextPrayerTimeMs =
        await FlutterForegroundTask.getData<int>(key: 'nextPrayerTimeMs');
    final String? nextPrayerName =
        await FlutterForegroundTask.getData<String>(key: 'nextPrayerName');

    if (nextPrayerTimeMs == null || nextPrayerName == null) {
      await FlutterForegroundTask.updateService(
        notificationText: 'افتح التطبيق لتحديث مواقيت الصلاة',
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = nextPrayerTimeMs - now;

    if (diff <= 0) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'حان الآن موعد الصلاة',
        notificationText: 'جاري الانتظار للتحديث...',
      );
      return;
    }

    final totalMinutes = (diff / 60000).floor();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final countdown = hours > 0 ? '$hoursس $minutesد' : '$minutesد';

    await FlutterForegroundTask.updateService(
      notificationTitle: 'الصلاة القادمة: $nextPrayerName',
      notificationText: 'متبقي: $countdown',
    );
  }
}

class NextPrayerCountdownService {
  static void init({bool autoRunOnBoot = false}) {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'next_prayer_countdown_channel',
        channelName: 'العداد القادم للصلاة',
        channelDescription: 'يعرض عدادًا للصلاة القادمة في إشعار دائم',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Update every minute
        eventAction: ForegroundTaskEventAction.repeat(60 * 1000),
        autoRunOnBoot: autoRunOnBoot,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<void> startOrUpdate({
    required int nextPrayerTimeMs,
    required String nextPrayerName,
    bool autoRunOnBoot = false,
  }) async {
    init(autoRunOnBoot: autoRunOnBoot);

    await FlutterForegroundTask.saveData(
      key: 'nextPrayerTimeMs',
      value: nextPrayerTimeMs,
    );
    await FlutterForegroundTask.saveData(
      key: 'nextPrayerName',
      value: nextPrayerName,
    );

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        callback: nextPrayerStartCallback,
      );
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'العداد القادم للصلاة',
      notificationText: 'جارٍ الحساب...',
      callback: nextPrayerStartCallback,
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

@pragma('vm:entry-point')
void nextPrayerStartCallback() {
  FlutterForegroundTask.setTaskHandler(NextPrayerCountdownHandler());
}
