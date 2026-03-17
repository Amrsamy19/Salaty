import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../services/notification_service.dart';
import '../models/tracker_model.dart';
import 'package:intl/intl.dart';

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

  // Brand palette
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

  String? errorMessage;

  Future<void> init() async {
    _isLoading = true;
    errorMessage = null;
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
    notifyListeners();
  }

  Future<void> togglePrayer(String prayerName) async {
    if (_tracker != null) {
      _tracker!.prayerStatus[prayerName] = !(_tracker!.prayerStatus[prayerName] ?? false);
      await _storageService.saveTracker(_tracker!);
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
