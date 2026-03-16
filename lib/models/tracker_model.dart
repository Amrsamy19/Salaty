import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrackerModel {
  final Map<String, bool> prayerStatus;
  final String date;

  TrackerModel({required this.prayerStatus, required this.date});

  Map<String, dynamic> toJson() => {
    'prayerStatus': prayerStatus,
    'date': date,
  };

  factory TrackerModel.fromJson(Map<String, dynamic> json) {
    return TrackerModel(
      prayerStatus: Map<String, bool>.from(json['prayerStatus']),
      date: json['date'],
    );
  }
}

class StorageService {
  static const String _keyTracker = 'prayer_tracker_history';
  static const String _keySettings = 'app_settings';

  Future<void> saveTracker(TrackerModel tracker) async {
    final prefs = await SharedPreferences.getInstance();
    List<TrackerModel> history = await getHistory();
    
    // Update existing day or add new
    int index = history.indexWhere((h) => h.date == tracker.date);
    if (index >= 0) {
      history[index] = tracker;
    } else {
      history.insert(0, tracker);
    }
    
    // Limit history to 30 days
    if (history.length > 30) history = history.sublist(0, 30);

    final data = history.map((t) => t.toJson()).toList();
    await prefs.setString(_keyTracker, jsonEncode(data));
  }

  Future<List<TrackerModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyTracker);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((j) => TrackerModel.fromJson(j)).toList();
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySettings, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keySettings);
    if (data == null) return {};
    return jsonDecode(data);
  }
}
