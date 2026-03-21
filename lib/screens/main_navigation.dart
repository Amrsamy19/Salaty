import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:volume_controller/volume_controller.dart';
import 'home_screen.dart';
import '../features/quran/screens/quran_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../providers/prayer_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  StreamSubscription? _notifSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

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
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          contentType: AndroidContentType.sonification,
        ),
      ),
    );

    _notifSubscription = NotificationService.onNotificationReceived.stream.listen((payload) {
      if (payload != null) {
        _showPrayerModal(payload);
      }
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showPrayerModal(String payload) async {
    final provider = context.read<PrayerProvider>();
    bool isAzkar = payload == 'Azkar';
    String prayerName = payload.replaceFirst(' High', '');
    
    // Play Azan sound if not Azkar
    if (!isAzkar) {
      try {
        // Force system volume to MAX for the Azan
        VolumeController.instance.showSystemUI = false;
        
        // Multi-step volume override to ensure it kicks in
        await VolumeController.instance.setVolume(1.0); 
        await Future.delayed(const Duration(milliseconds: 200));
        await VolumeController.instance.setVolume(1.0);
        
        // Short delay to ensure volume is applied before playback starts
        await Future.delayed(const Duration(milliseconds: 500));
        
        final sound = provider.selectedAzanSound;
        debugPrint('Bypassing silent mode: Playing Azan: $sound at max volume');
        
        // Configure for maximum priority - Alarm usage bypasses most silent states
        await _audioPlayer.setAudioContext(
          AudioContext(
            android: AudioContextAndroid(
              usageType: AndroidUsageType.alarm,
              audioFocus: AndroidAudioFocus.gain,
              contentType: AndroidContentType.music,
            ),
          ),
        );

        await _audioPlayer.stop(); 
        await _audioPlayer.play(AssetSource('audio/$sound'));
      } catch (e, st) {
        debugPrint('Error playing sound in silent mode: $e\n$st');
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
                        onPressed: () {
                          _audioPlayer.stop();
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
                    onPressed: () {
                      _audioPlayer.stop();
                      Navigator.pop(context);
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
