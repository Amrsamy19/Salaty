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
        // Force system volume up for the Azan
        VolumeController.instance.showSystemUI = false;
        await VolumeController.instance.setVolume(0.85); // 85% volume
        
        final sound = provider.selectedAzanSound;
        await _audioPlayer.play(AssetSource('audio/$sound'));
      } catch (e) {
        debugPrint('Error playing sound: $e');
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
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF061026),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: const Color(0xFF061026),
          selectedItemColor: const Color(0xFFC5A35E),
          unselectedItemColor: Colors.white30,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l.isAr ? "الرئيسية" : "Home",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book_rounded),
              label: l.isAr ? "القرآن" : "Quran",
            ),
          ],
        ),
      ),
    );
  }
}
