import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volume_controller/volume_controller.dart';
import '../providers/prayer_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'home_screen.dart';
import '../features/quran/screens/quran_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import 'azan_full_screen.dart';
import 'package:flutter/services.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  static const _nativeChannel = MethodChannel('azan_channel');
  int _selectedIndex = 0;
  StreamSubscription? _notifSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isModalShowing = false;
  DateTime? _lastPrayerTime;
  String? _lastPrayerPayload;

  final List<Widget> _screens = [
    const HomeScreen(),
    const QuranScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Configure audio context to use alarm stream (bypasses silent/DND if alarms are allowed)
    _audioPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
          contentType: AndroidContentType.music,
        ),
      ),
    );

    _notifSubscription = NotificationService.onNotificationReceived.stream.listen((payload) {
      if (payload != null) {
        final now = DateTime.now();
        // Debounce: ignore same payload if received within 10 seconds of each other
        if (payload == _lastPrayerPayload && _lastPrayerTime != null && now.difference(_lastPrayerTime!).inSeconds < 10) {
          debugPrint('Duplicate trigger ignored: $payload');
          return;
        }
        
        _lastPrayerPayload = payload;
        _lastPrayerTime = now;
        _showPrayerModal(payload);
      }
    });

    WidgetsBinding.instance.addObserver(this);
    // Initial check for native trigger (if launched via full-screen intent)
    _checkNativeAzanTrigger();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNativeAzanTrigger();
    }
  }

  Future<void> _checkNativeAzanTrigger() async {
    try {
      final bool triggered = await _nativeChannel.invokeMethod('checkAzanTrigger');
      if (triggered && mounted) {
        _showFullScreenAzan();
      }
    } catch (e) {
      debugPrint('Error checking native trigger: $e');
    }
  }

  void _showFullScreenAzan() {
    if (_isModalShowing) return;
    
    // Determine prayer name from context if possible, or just default
    String prayerName = "الصلاة";
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AzanFullScreen(
          prayerName: prayerName,
          onDismiss: () async {
            final navigator = Navigator.of(context);
            await _nativeChannel.invokeMethod('stopAzan');
            navigator.pop();
            if (mounted) setState(() => _isModalShowing = false);
          },
        ),
        fullscreenDialog: true,
      ),
    ).then((_) => _isModalShowing = false);
    
    _isModalShowing = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showPrayerModal(String payload) async {
    if (_isModalShowing) return;
    _isModalShowing = true;
    // Handle modal display
    bool isAzkar = payload == 'Azkar';
    String prayerName = payload.replaceFirst(' High', '');
    
    // Play Azan sound if not Azkar
    if (!isAzkar) {
      try {
        final provider = context.read<PrayerProvider>();
        final sound = provider.selectedAzanSound;
        debugPrint('MainNavigation: Playing Azan modal sound: $sound at volume ${provider.azanVolume}');
        
        // Use Media stream (music) which follows VolumeController's standard setVolume()
        await VolumeController.instance.setVolume(provider.azanVolume);
        
        await _audioPlayer.stop();
        // Set player volume to full, system volume is handled above
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(AssetSource('audio/$sound'));
      } catch (e) {
        debugPrint('MainNavigation: Error playing sound: $e');
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0D1B3E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isAzkar ? 'وقت الأذكار' : 'حان وقت الصلاة',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFC5A35E), fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mosque_rounded, size: 64, color: Color(0xFFC5A35E)),
              const SizedBox(height: 16),
              Text(
                isAzkar 
                    ? 'حان الآن موعد أذكاركم'
                    : 'أقم صلاتك يا عبد الله\nموعد صلاة $prayerName',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                if (!isAzkar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          _audioPlayer.stop();
                          await _nativeChannel.invokeMethod('stopAzan');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text('إيقاف الأذان', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      _audioPlayer.stop();
                      await _nativeChannel.invokeMethod('stopAzan');
                      setState(() => _isModalShowing = false);
                      if (mounted) Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFC5A35E),
                      foregroundColor: const Color(0xFF061026),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: gold.withValues(alpha: 0.1), width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          backgroundColor: theme.scaffoldBackgroundColor,
          indicatorColor: gold.withValues(alpha: 0.15),
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              selectedIcon: Icon(Icons.home_rounded, color: gold),
              label: l.isAr ? "الرئيسية" : "Home",
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              selectedIcon: Icon(Icons.menu_book_rounded, color: gold),
              label: l.isAr ? "القرآن" : "Quran",
            ),
          ],
        ),
      ),
    );
  }
}
