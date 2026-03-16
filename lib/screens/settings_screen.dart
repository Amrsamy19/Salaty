import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/prayer_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingSound;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _previewSound(String soundFile) async {
    if (_playingSound == soundFile) {
      await _audioPlayer.stop();
      setState(() => _playingSound = null);
    } else {
      setState(() => _playingSound = soundFile);
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/$soundFile'));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingSound = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PrayerProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('تخصيص العرض'),
            _buildFontSizeSlider(provider),
            const SizedBox(height: 20),
            _buildSectionHeader('صوت الأذان'),
            _buildAzanSoundSelector(provider),
            const SizedBox(height: 20),
            _buildSectionHeader('تنبيهات الصلوات'),
            _buildPrayerNotifSettings(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, color: Colors.amber, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFontSizeSlider(PrayerProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('حجم الخط', style: TextStyle(color: Colors.white, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(provider.fontSizeMultiplier * 100).toInt()}%',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Slider(
            value: provider.fontSizeMultiplier,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            activeColor: Colors.amber,
            inactiveColor: Colors.white24,
            onChanged: (val) => provider.setFontSize(val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('صغير', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text('كبير', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAzanSoundSelector(PrayerProvider provider) {
    final sounds = [
      {'id': 'makah.mp3', 'name': 'أذان مكة'},
      {'id': 'egypt.mp3', 'name': 'أذان مصري'},
      {'id': 'abdelbaset.mp3', 'name': 'عبد الباسط'},
      {'id': 'mohamedrefaat.mp3', 'name': 'محمد رفعت'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: List.generate(sounds.length, (index) {
          final s = sounds[index];
          final isSelected = provider.selectedAzanSound == s['id'];
          final isPlaying = _playingSound == s['id'];
          final isLast = index == sounds.length - 1;

          return Column(
            children: [
              Container(
                color: isSelected ? Colors.amber.withOpacity(0.08) : Colors.transparent,
                child: Row(
                  children: [
                    // Radio + Label
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(
                          s['name']!,
                          style: TextStyle(
                            color: isSelected ? Colors.amber : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        value: s['id']!,
                        groupValue: provider.selectedAzanSound,
                        activeColor: Colors.amber,
                        onChanged: (val) => provider.setAzanSound(val!),
                      ),
                    ),
                    // Preview play button
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => _previewSound(s['id']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPlaying
                                ? Colors.amber.withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: isPlaying ? Colors.amber : Colors.white24,
                            ),
                          ),
                          child: Icon(
                            isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: isPlaying ? Colors.amber : Colors.white70,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: Colors.white.withOpacity(0.07)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPrayerNotifSettings(PrayerProvider provider) {
    final prayers = provider.notifMap.keys.toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: List.generate(prayers.length, (index) {
          final p = prayers[index];
          final isEnabled = provider.notifMap[p] ?? true;
          final isLast = index == prayers.length - 1;
          return Column(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  p,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.white38,
                    fontSize: 16,
                  ),
                ),
                secondary: Icon(
                  Icons.notifications_active_rounded,
                  color: isEnabled ? Colors.amber : Colors.white24,
                ),
                value: isEnabled,
                activeColor: Colors.amber,
                inactiveTrackColor: Colors.white12,
                onChanged: (_) => provider.togglePrayerNotif(p),
              ),
              if (!isLast)
                Divider(height: 1, color: Colors.white.withOpacity(0.07)),
            ],
          );
        }),
      ),
    );
  }
}
