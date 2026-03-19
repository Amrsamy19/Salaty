import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../models/surah.dart';
import '../data/surah_data.dart';

class QuranProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();
  
  final List<Surah> _allSurahs = SurahData.surahs;
  final Map<int, DownloadState> _downloadStates = {};
  final Map<int, double> _downloadProgress = {};
  final Map<int, String> _localFilePaths = {};
  final Map<int, List<Ayah>> _surahAyahs = {};
  final Map<int, bool> _isFetchingAyahs = {};
  final Map<int, String> _surahAudioUrls = {};
  
  String? _errorMessage;
  bool _isDownloadingAllTexts = false;
  double _syncProgress = 0.0;
  
  int? _currentSurahNumber;
  int _activeAyahIndex = -1;
  PlayerState? _playerState;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<Surah> get allSurahs => _allSurahs;
  bool get isDownloadingAllTexts => _isDownloadingAllTexts;
  double get syncProgress => _syncProgress;
  String? get errorMessage => _errorMessage;
  Map<int, DownloadState> get downloadStates => _downloadStates;
  Map<int, double> get downloadProgress => _downloadProgress;
  Map<int, String> get localFilePaths => _localFilePaths;
  Map<int, List<Ayah>> get surahAyahs => _surahAyahs;
  bool isFetching(int? n) => _isFetchingAyahs[n] ?? false;
  int? get currentSurahNumber => _currentSurahNumber;
  int get activeAyahIndex => _activeAyahIndex;
  bool get isPlaying => _audioPlayer.playing;
  PlayerState? get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;

  QuranProvider() {
    _init();
  }

  void _init() {
    _audioPlayer.playerStateStream.listen((state) {
      _playerState = state;
      notifyListeners();
    });
    
    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      _updateActiveAyah(pos);
      notifyListeners();
    });
    
    _audioPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stopPlayback();
      }
    });

    loadDownloadedSurahs();
  }

  void _updateActiveAyah(Duration pos) {
    if (_currentSurahNumber == null) return;
    final ayahs = _surahAyahs[_currentSurahNumber];
    if (ayahs == null) return;

    final ms = pos.inMilliseconds;
    int foundIndex = -1;
    for (int i = 0; i < ayahs.length; i++) {
      if (ms >= ayahs[i].timestampFrom && ms < ayahs[i].timestampTo) {
        foundIndex = i;
        break;
      }
    }
    
    if (foundIndex != _activeAyahIndex) {
      _activeAyahIndex = foundIndex;
    }
  }

  Future<void> loadDownloadedSurahs() async {
    final directory = await getApplicationDocumentsDirectory();
    final quranDir = Directory('${directory.path}/quran');
    
    if (!await quranDir.exists()) {
      await quranDir.create(recursive: true);
    }

    for (var surah in _allSurahs) {
      final file = File('${quranDir.path}/${formatSurahNumber(surah.number)}.mp3');
      if (await file.exists()) {
        _downloadStates[surah.number] = DownloadState.downloaded;
        _localFilePaths[surah.number] = file.path;
      } else {
        _downloadStates[surah.number] = DownloadState.notDownloaded;
      }
    }
    notifyListeners();
  }

  Future<void> downloadSurah(int surahNumber) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _showError("There has to be internet to start the download");
        return;
      }
    } catch (_) {
      // If plugin fails (e.g. not linked yet), proceed anyway
    }

    _downloadStates[surahNumber] = DownloadState.downloading;
    _downloadProgress[surahNumber] = 0.0;
    notifyListeners();

    try {
      final url = getAudioUrl(surahNumber);
      final path = await getLocalPath(surahNumber);
      
      await _dio.download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress[surahNumber] = received / total;
            notifyListeners();
          }
        },
      );

      final file = File(path);
      if (await file.length() < 10240) { // 10KB check
        throw Exception("File too small");
      }

      _downloadStates[surahNumber] = DownloadState.downloaded;
      _localFilePaths[surahNumber] = path;
      
      // Also fetch and cache text for offline use
      fetchAyahs(surahNumber);
    } catch (e) {
      _downloadStates[surahNumber] = DownloadState.error;
      debugPrint("Download error: $e");
    }
    notifyListeners();
  }

  Future<void> deleteSurah(int surahNumber) async {
    final path = _localFilePaths[surahNumber];
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _downloadStates[surahNumber] = DownloadState.notDownloaded;
      _localFilePaths.remove(surahNumber);
      _downloadProgress.remove(surahNumber);
      
      if (_currentSurahNumber == surahNumber) {
        stopPlayback();
      }
      notifyListeners();
    }
  }

  Future<void> playSurah(int surahNumber) async {
    if (_currentSurahNumber == surahNumber) {
      await pauseResume();
      return;
    }

    _currentSurahNumber = surahNumber;
    final path = _localFilePaths[surahNumber];
    
    try {
      if (path != null && await File(path).exists()) {
        await _audioPlayer.setFilePath(path);
      } else {
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          if (connectivityResult.contains(ConnectivityResult.none)) {
            _showError("No internet to stream this surah");
            return;
          }
        } catch (_) {}
        
        final apiUrl = _surahAudioUrls[surahNumber];
        await _audioPlayer.setUrl(apiUrl ?? getAudioUrl(surahNumber));
      }
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Playback error: $e");
    }
    notifyListeners();
  }

  Future<void> pauseResume() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
    _currentSurahNumber = null;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String getAudioUrl(int surahNumber) {
    // This is the QDC (Quran.com) Murattal Version which usually matches the timestamps
    return "https://download.quranicaudio.com/qdc/mishari_al_afasy/murattal/$surahNumber.mp3";
  }

  String formatSurahNumber(int n) {
    return n.toString().padLeft(3, '0');
  }

  Future<String> getLocalPath(int surahNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/quran/${formatSurahNumber(surahNumber)}.mp3';
  }

  Future<String> _getSurahDataPath(int surahNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${directory.path}/quran_data');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return '${dataDir.path}/surah_$surahNumber.json';
  }

  Future<double> getTotalDownloadedSize() async {
    double totalSize = 0;
    for (var path in _localFilePaths.values) {
      final file = File(path);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }
    return totalSize / (1024 * 1024); // MB
  }

  Future<void> deleteAllDownloaded() async {
    for (var surahNumber in _localFilePaths.keys.toList()) {
      await deleteSurah(surahNumber);
    }
  }

  Future<void> downloadAllTexts() async {
    if (_isDownloadingAllTexts) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _showError("No internet to sync Quran texts");
      return;
    }

    _isDownloadingAllTexts = true;
    _syncProgress = 0.0;
    notifyListeners();

    try {
      for (int i = 1; i <= 114; i++) {
        await fetchAyahs(i);
        _syncProgress = i / 114;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error syncing all texts: $e");
    } finally {
      _isDownloadingAllTexts = false;
      notifyListeners();
    }
  }

  Future<void> fetchAyahs(int surahNumber) async {
    if (_surahAyahs.containsKey(surahNumber)) return;
    
    _isFetchingAyahs[surahNumber] = true;
    notifyListeners();
    
    try {
      final localDataPath = await _getSurahDataPath(surahNumber);
      final localFile = File(localDataPath);

      // Check if we have local data already
      if (await localFile.exists()) {
        final jsonStr = await localFile.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        
        _surahAyahs[surahNumber] = (data['ayahs'] as List)
            .map((a) => Ayah(
              number: a['number'],
              numberInSurah: a['numberInSurah'],
              text: a['text'],
              timestampFrom: a['timestampFrom'],
              timestampTo: a['timestampTo'],
            )).toList();
        
        if (data['audioUrl'] != null) {
          _surahAudioUrls[surahNumber] = data['audioUrl'];
        }
      } else {
        // Fetch from API - but check connectivity first
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          if (connectivityResult.contains(ConnectivityResult.none)) {
            _showError("No internet to stream this surah"); // This is the key for localized error
            _isFetchingAyahs[surahNumber] = false;
            notifyListeners();
            return;
          }
        } catch (_) {}

        final textRes = await _dio.get("https://api.alquran.cloud/v1/surah/$surahNumber/quran-uthmani");
        final timeRes = await _dio.get("https://api.quran.com/api/v4/chapter_recitations/7/$surahNumber?segments=true");
        
        if (textRes.statusCode == 200 && timeRes.statusCode == 200) {
          final ayahList = textRes.data['data']['ayahs'] as List;
          final timestampList = timeRes.data['audio_file']['timestamps'] as List;
          final audioUrl = timeRes.data['audio_file']?['audio_url'];

          List<Ayah> ayahs = [];
          for (int i = 0; i < ayahList.length; i++) {
            ayahs.add(Ayah(
              number: ayahList[i]['number'],
              numberInSurah: ayahList[i]['numberInSurah'],
              text: ayahList[i]['text'],
              timestampFrom: timestampList[i]['timestamp_from'] as int,
              timestampTo: timestampList[i]['timestamp_to'] as int,
            ));
          }
          
          _surahAyahs[surahNumber] = ayahs;
          if (audioUrl != null) _surahAudioUrls[surahNumber] = audioUrl;

          // Save for offline use
          final Map<String, dynamic> cacheData = {
            'ayahs': ayahs.map((a) => {
              'number': a.number,
              'numberInSurah': a.numberInSurah,
              'text': a.text,
              'timestampFrom': a.timestampFrom,
              'timestampTo': a.timestampTo,
            }).toList(),
            'audioUrl': audioUrl,
          };
          await localFile.writeAsString(jsonEncode(cacheData));
        }
      }
    } catch (e) {
      debugPrint("Error in offline-first fetchAyahs: $e");
    } finally {
      _isFetchingAyahs[surahNumber] = false;
      notifyListeners();
    }
  }

  void _showError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
