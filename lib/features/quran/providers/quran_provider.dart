import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  
  int? _currentSurahNumber;
  int _activeAyahIndex = -1;
  PlayerState? _playerState;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _errorMessage;

  List<Surah> get allSurahs => _allSurahs;
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
    } catch (e) {
      _downloadStates[surahNumber] = DownloadState.error;
      print("Download error: $e");
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
      print("Playback error: $e");
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

  Future<void> fetchAyahs(int surahNumber) async {
    if (_surahAyahs.containsKey(surahNumber)) return;
    
    _isFetchingAyahs[surahNumber] = true;
    notifyListeners();
    
    try {
      // 1. Fetch Uthmani Text from AlQuran Cloud
      final textRes = await _dio.get("https://api.alquran.cloud/v1/surah/$surahNumber/quran-uthmani");
      
      // 2. Fetch Timestamps from Quran.com (Reciter 7 = Alafasy) - Use chapter_recitations endpoint
      final timeRes = await _dio.get("https://api.quran.com/api/v4/chapter_recitations/7/$surahNumber?segments=true");
      
      if (textRes.statusCode == 200 && timeRes.statusCode == 200) {
        final ayahList = textRes.data['data']['ayahs'] as List;
        final timestampList = timeRes.data['audio_file']['timestamps'] as List;

        List<Ayah> ayahs = [];
        for (int i = 0; i < ayahList.length; i++) {
          final textData = ayahList[i];
          final timeData = timestampList[i];
          
          ayahs.add(Ayah(
            number: textData['number'],
            numberInSurah: textData['numberInSurah'],
            text: textData['text'],
            timestampFrom: timeData['timestamp_from'] as int,
            timestampTo: timeData['timestamp_to'] as int,
          ));
        }
        
        _surahAyahs[surahNumber] = ayahs;
        
        // Also capture the correct audio URL from the API to stay in sync
        if (timeRes.data['audio_file']?['audio_url'] != null) {
          _surahAudioUrls[surahNumber] = timeRes.data['audio_file']['audio_url'];
        }
      }
    } catch (e) {
      print("Error fetching detailed ayahs: $e");
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
