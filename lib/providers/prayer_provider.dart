import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../services/notification_service.dart';
import '../models/tracker_model.dart';
import 'package:intl/intl.dart';

enum IslamicSeason { normal, ramadan, eidFitr, hajj }

class PrayerProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final PrayerService _prayerService = PrayerService();
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();

  Position? _currentPosition;
  PrayerTimes? _prayerTimes;
  TrackerModel? _tracker;
  List<TrackerModel> _history = [];
  bool _isLoading = false;
  Locale _locale = const Locale('ar');

  int _currentStreak = 0;
  int _longestStreak = 0;
  IslamicSeason _season = IslamicSeason.normal;

  // Brand palette (Default)
  static const Color brandBg        = Color(0xFF061026);
  static const Color brandGold      = Color(0xFFC5A35E);
  static const Color brandGoldFaint = Color(0x33C5A35E); // rgba(197,163,94,0.2)
  static const Color brandText      = Color(0xFFE2D1A8);
  static const Color brandSlate     = Color(0xFF64748B);

  // Settings
  double _fontSizeMultiplier = 1.0;
  String _selectedAzanSound = 'makah.mp3';
  Map<String, bool> _notifMap = {
    'الفجر': true,
    'الظهر': true,
    'العصر': true,
    'المغرب': true,
    'العشاء': true,
    'أذكار الصباح': true,
    'أذكار المساء': true,
  };
  Color _primaryColor = brandGold;
  final Color _accentColor  = brandGold;

  // Getters
  Position? get currentPosition => _currentPosition;
  PrayerTimes? get prayerTimes => _prayerTimes;
  TrackerModel? get tracker => _tracker;
  List<TrackerModel> get history => _history;
  bool get isLoading => _isLoading;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  String get selectedAzanSound => _selectedAzanSound;
  Map<String, bool> get notifMap => _notifMap;
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  Locale get locale => _locale;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  IslamicSeason get season => _season;

  // Seasonal Helpers
  Color get themePrimary => _primaryColor;
  
  List<Color> get themeBackground {
    switch (_season) {
      case IslamicSeason.ramadan:
        return [const Color(0xFF1A0B2E), const Color(0xFF061026)]; // Deep Purple/Navy
      case IslamicSeason.eidFitr:
        return [const Color(0xFF063B2F), const Color(0xFF061026)]; // Emerald Green
      case IslamicSeason.hajj:
        return [const Color(0xFF2E241A), const Color(0xFF061026)]; // Sandy Dark
      case IslamicSeason.normal:
        return [const Color(0xFF061026), const Color(0xFF0D1B3E)];
    }
  }

  IconData get seasonIcon {
    switch (_season) {
      case IslamicSeason.ramadan: return Icons.nightlight_round;
      case IslamicSeason.eidFitr: return Icons.celebration_rounded;
      case IslamicSeason.hajj:    return Icons.mosque_rounded;
      case IslamicSeason.normal:  return Icons.star_rounded;
    }
  }

  String? errorMessage;

  Future<void> init() async {
    _isLoading = true;
    errorMessage = null;
    _detectSeason();
    notifyListeners();

    try {
      await _notificationService.init();
      await loadSettings();
      await refreshPrayerTimes();
      await loadTracker();
    } catch (e, st) {
      errorMessage = "$e\n$st";
      print(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    final settings = await _storageService.getSettings();
    if (settings.isNotEmpty) {
      _fontSizeMultiplier = settings['fontSize'] ?? 1.0;
      _selectedAzanSound = settings['azanSound'] ?? 'makah.mp3';
      if (settings['notifMap'] != null) {
        _notifMap = Map<String, bool>.from(settings['notifMap']);
        if (!_notifMap.containsKey('أذكار الصباح')) _notifMap['أذكار الصباح'] = true;
        if (!_notifMap.containsKey('أذكار المساء')) _notifMap['أذكار المساء'] = true;
      }
      if (settings['primaryColor'] != null) {
        _primaryColor = Color(settings['primaryColor']);
      }
      if (settings['locale'] != null) {
        _locale = Locale(settings['locale']);
      }
    }
  }

  Future<void> saveSettings() async {
    await _storageService.saveSettings({
      'fontSize': _fontSizeMultiplier,
      'azanSound': _selectedAzanSound,
      'notifMap': _notifMap,
      'primaryColor': _primaryColor.value,
      'locale': _locale.languageCode,
    });
    if (_prayerTimes != null) {
      await _notificationService.schedulePrayerNotifications(
        prayerTimes: _prayerTimes!,
        azanSound: _selectedAzanSound,
        enabledPrayers: _notifMap,
      );
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await saveSettings();
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSizeMultiplier = size;
    await saveSettings();
    notifyListeners();
  }

  Future<void> setAzanSound(String sound) async {
    _selectedAzanSound = sound;
    await saveSettings();
    notifyListeners();
  }

  Future<void> togglePrayerNotif(String name) async {
    _notifMap[name] = !(_notifMap[name] ?? true);
    await saveSettings();
    notifyListeners();
  }

  Future<void> refreshPrayerTimes() async {
    _detectSeason();
    _currentPosition = await _locationService.getCurrentLocation();
    if (_currentPosition != null) {
      _prayerTimes = _prayerService.getPrayerTimes(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      await _notificationService.schedulePrayerNotifications(
        prayerTimes: _prayerTimes!,
        azanSound: _selectedAzanSound,
        enabledPrayers: _notifMap,
      );
    }
    notifyListeners();
  }

  Future<void> testPrayerNotification() async {
    await _notificationService.testSchedule(10, _selectedAzanSound);
  }

  void _detectSeason() {
    final hijri = HijriCalendar.now();
    // Ramadan: Month 9
    if (hijri.hMonth == 9) {
      _season = IslamicSeason.ramadan;
    } 
    // Eid al-Fitr: Shawwal (Month 10), first 3 days
    else if (hijri.hMonth == 10 && hijri.hDay <= 3) {
      _season = IslamicSeason.eidFitr;
    }
    // Hajj / Eid al-Adha: Dhul Hijjah (Month 12), first 13 days
    else if (hijri.hMonth == 12 && hijri.hDay <= 13) {
      _season = IslamicSeason.hajj;
    }
    else {
      _season = IslamicSeason.normal;
    }
  }

  Future<void> loadTracker() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _history = await _storageService.getHistory();
    
    int index = _history.indexWhere((h) => h.date == todayStr);
    if (index >= 0) {
      _tracker = _history[index];
    } else {
      _tracker = TrackerModel(
        date: todayStr,
        prayerStatus: {'الفجر': false, 'الظهر': false, 'العصر': false, 'المغرب': false, 'العشاء': false},
      );
      await _storageService.saveTracker(_tracker!);
      _history.insert(0, _tracker!);
    }
    _calculateStreaks();
    notifyListeners();
  }

  void _calculateStreaks() {
    if (_history.isEmpty) {
      _currentStreak = 0;
      _longestStreak = 0;
      return;
    }

    // History is sorted 0: newest to oldest
    int longest = 0;
    int temp = 0;

    // Current streak (starting from today or yesterday)
    bool isStillCurrent = true;
    DateTime today = DateTime.now();
    String todayStr = DateFormat('yyyy-MM-dd').format(today);

    for (int i = 0; i < _history.length; i++) {
      final h = _history[i];
      final allDone = h.prayerStatus.values.every((v) => v);

      if (allDone) {
        temp++;
        if (temp > longest) longest = temp;
      } else {
        // Only break current streak if it's NOT today (today might be in progress)
        // OR if it's today and we already missed a prayer that passed.
        // For simplicity: if yesterday was broken, current streak is 0 or 1 (depending on today).
        if (isStillCurrent) {
           if (h.date != todayStr) {
             isStillCurrent = false;
           } else {
             // If today is not all done but yesterday was, we don't break yet? 
             // Actually, if today is not all done, current streak only counts if yesterday was all done.
           }
        }
        temp = 0;
      }
    }

    // Accurate current streak calculation
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    while (true) {
      final dateStr = DateFormat('yyyy-MM-dd').format(checkDate);
      final index = _history.indexWhere((h) => h.date == dateStr);
      
      if (index == -1) {
        // If we missing a day in history, streak breaks
        // UNLESS it's today and we haven't finished yet.
        if (dateStr == todayStr) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }

      final h = _history[index];
      final allDone = h.prayerStatus.values.every((v) => v);

      if (allDone) {
        streak++;
      } else {
        // If today is not finished, we continue to check yesterday to see if the streak is still alive
        if (dateStr == todayStr) {
           // Streak is still alive if yesterday was done
           checkDate = checkDate.subtract(const Duration(days: 1));
           continue;
        }
        break;
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    _currentStreak = streak;
    _longestStreak = longest;
  }

  Future<void> togglePrayer(String prayerName) async {
    if (_tracker != null) {
      _tracker!.prayerStatus[prayerName] = !(_tracker!.prayerStatus[prayerName] ?? false);
      await _storageService.saveTracker(_tracker!);
      _calculateStreaks();
      notifyListeners();
    }
  }

  Prayer get nextPrayer {
    if (_prayerTimes == null) return Prayer.none;
    return _prayerTimes!.nextPrayer();
  }

  Duration? get timeUntilNextPrayer {
    if (_prayerTimes == null || _currentPosition == null) return null;
    
    final next = nextPrayer;
    if (next != Prayer.none) {
      final time = _prayerTimes!.timeForPrayer(next);
      if (time == null) return null;
      return time.difference(DateTime.now());
    } else {
      // It's past Isha, let's get tomorrow's Fajr
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowPrayerTimes = PrayerTimes(
        Coordinates(_currentPosition!.latitude, _currentPosition!.longitude),
        DateComponents.from(tomorrow),
        CalculationMethod.muslim_world_league.getParameters(),
      );
      return tomorrowPrayerTimes.fajr.difference(DateTime.now());
    }
  }
}
