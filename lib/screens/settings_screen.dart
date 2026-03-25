import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/prayer_provider.dart';
import '../l10n/app_localizations.dart';

const _bg     = Color(0xFF061026);
const _bg2    = Color(0xFF0D1B3E);
const _gold   = Color(0xFFC5A35E);
const _faint  = Color(0x33C5A35E);
const _cream  = Color(0xFFE2D1A8);
const _slate  = Color(0xFF64748B);

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
    final provider = Provider.of<PrayerProvider>(context, listen: false);
    if (_playingSound == soundFile) {
      await _audioPlayer.stop();
      setState(() => _playingSound = null);
    } else {
      setState(() => _playingSound = soundFile);
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(provider.azanVolume);
      await _audioPlayer.play(AssetSource('audio/$soundFile'));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingSound = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PrayerProvider>(context);
    final l = AppLocalizations.of(context);
    final isAr = l.isAr;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(l.settings, style: const TextStyle(fontWeight: FontWeight.bold, color: _cream)),
        centerTitle: true,
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg, _bg2, _bg],
          ),
        ),
        child: Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _sectionHeader(l.language),
              _buildLanguageSelector(provider, l),
              const SizedBox(height: 20),
              _sectionHeader(l.displaySettings),
              _buildFontSizeCard(provider, l),
              const SizedBox(height: 20),
              _sectionHeader(l.azanSound),
              _buildAzanSoundCard(provider, l),
              const SizedBox(height: 20),
              _sectionHeader(l.isAr ? 'مستوى صوت الأذان' : 'Azan Volume'),
              _buildAzanVolumeCard(provider, l),
              const SizedBox(height: 20),
              _sectionHeader(l.isAr ? 'إشعار دائم' : 'Persistent notification'),
              _buildCountdownServiceCard(provider, l),
              const SizedBox(height: 20),
              _sectionHeader(l.notifications),
              _buildNotifCard(provider, l),
              const SizedBox(height: 20),
              _sectionHeader(l.isAr ? 'توافق النظام (تجاوز الصامت)' : 'System Check (Silent Bypass)'),
              _buildDiagnosisCard(provider, l),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _gold,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }

  Widget _buildLanguageSelector(PrayerProvider provider, AppLocalizations l) {
    final options = [
      {'locale': const Locale('ar'), 'label': l.arabic, 'sub': 'Arabic'},
      {'locale': const Locale('en'), 'label': l.english, 'sub': 'Arabic'},
    ];
    return _card(
      child: Column(
        children: List.generate(options.length, (i) {
          final opt = options[i];
          final locale = opt['locale'] as Locale;
          final isSelected = provider.locale.languageCode == locale.languageCode;
          final isLast = i == options.length - 1;
          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => provider.setLocale(locale),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? _gold : _slate, width: 2),
                          color: isSelected ? _gold : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: _bg, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        opt['label'] as String,
                        style: TextStyle(
                          color: isSelected ? _gold : _cream,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: _gold.withValues(alpha: 0.1)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFontSizeCard(PrayerProvider provider, AppLocalizations l) {
    return _card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.fontSize, style: const TextStyle(color: _cream, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _faint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${(provider.fontSizeMultiplier * 100).toInt()}%',
                    style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _gold,
                inactiveTrackColor: _slate.withValues(alpha: 0.3),
                thumbColor: _gold,
                overlayColor: _faint,
              ),
              child: Slider(
                value: provider.fontSizeMultiplier,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                onChanged: (val) => provider.setFontSize(val),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.small, style: const TextStyle(color: _slate, fontSize: 12)),
                  Text(l.large, style: const TextStyle(color: _slate, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAzanSoundCard(PrayerProvider provider, AppLocalizations l) {
    final sounds = [
      {'id': 'makah.mp3',        'name': l.makahAzan},
      {'id': 'egypt.mp3',        'name': l.egyptAzan},
      {'id': 'abdelbaset.mp3',   'name': l.abdelbaset},
      {'id': 'mohamedrefaat.mp3','name': l.mohamedrefaat},
    ];

    return _card(
      child: Column(
        children: List.generate(sounds.length, (index) {
          final s     = sounds[index];
          final isSelected = provider.selectedAzanSound == s['id'];
          final isPlaying  = _playingSound == s['id'];
          final isLast     = index == sounds.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => provider.setAzanSound(s['id']!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Custom radio
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? _gold : _slate, width: 2),
                          color: isSelected ? _gold : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: _bg, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          s['name']!,
                          style: TextStyle(
                            color: isSelected ? _gold : _cream,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      // Preview button
                      GestureDetector(
                        onTap: () => _previewSound(s['id']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPlaying ? _faint : _bg,
                            border: Border.all(
                              color: isPlaying ? _gold : _gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: isPlaying ? _gold : _cream.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, color: _gold.withValues(alpha: 0.1)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAzanVolumeCard(PrayerProvider provider, AppLocalizations l) {
    return _card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.isAr ? 'قوة الصوت' : 'Volume Level', style: const TextStyle(color: _cream, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _faint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${(provider.azanVolume * 100).toInt()}%',
                    style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _gold,
                inactiveTrackColor: _slate.withValues(alpha: 0.3),
                thumbColor: _gold,
                overlayColor: _faint,
              ),
              child: Slider(
                value: provider.azanVolume,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (val) {
                  // Immediate UI update without heavy persistent logic
                  provider.updateAzanVolumeUI(val);
                },
                onChangeEnd: (val) {
                  // Persist only when dragging stops
                  provider.setAzanVolume(val);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.isAr ? 'منخفض' : 'Low', style: const TextStyle(color: _slate, fontSize: 12)),
                  Text(l.isAr ? 'مرتفع' : 'High', style: const TextStyle(color: _slate, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownServiceCard(PrayerProvider provider, AppLocalizations l) {
    return _card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: provider.keepCountdownNotification ? _gold : _slate, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.isAr ? 'تشغيل إشعار دائم بعداد الصلاة القادمة' : 'Keep a persistent next-prayer countdown',
                    style: const TextStyle(color: _cream, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.isAr
                        ? 'سيبقى إشعار في شريط الحالة ويُحدّث العداد كل دقيقة حتى لو أغلقت التطبيق.'
                        : 'Shows an ongoing notification and updates every minute, even when the app is closed.',
                    style: TextStyle(color: _slate.withValues(alpha: 0.9), fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            Switch(
              value: provider.keepCountdownNotification,
              activeThumbColor: _gold,
              onChanged: (v) => provider.setKeepCountdownNotification(v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCard(PrayerProvider provider, AppLocalizations l) {
    final prayers = provider.notifMap.keys.toList();
    return _card(
      child: Column(
        children: List.generate(prayers.length, (i) {
          final arName    = prayers[i];
          final isEnabled = provider.notifMap[arName] ?? true;
          final isLast    = i == prayers.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: isEnabled ? _gold : _slate,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l.prayerName(arName),
                        style: TextStyle(
                          color: isEnabled ? _cream : _slate,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => provider.togglePrayerNotif(arName),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: isEnabled ? _gold : _slate.withValues(alpha: 0.3),
                          border: Border.all(color: isEnabled ? _gold : _slate.withValues(alpha: 0.4)),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isEnabled ? _bg : _slate,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: _gold.withValues(alpha: 0.1)),
            ],
          );
        }),
      ),
    );
  }
  Widget _buildDiagnosisCard(PrayerProvider provider, AppLocalizations l) {
    return _card(
      child: FutureBuilder<Map<String, bool>>(
        future: provider.checkAzanCompatibility(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: _gold)),
            );
          }

          final data = snapshot.data!;
          final isReady = data['is_fully_compatible'] ?? false;

          return Column(
            children: [
              _checkItem(
                l.isAr ? 'إذن التنبيهات' : 'Notifications Permission',
                data['notification_permission'] ?? false,
              ),
              Divider(height: 1, color: _gold.withValues(alpha: 0.1)),
              _checkItem(
                l.isAr ? 'إذن المنبهات الدقيقة' : 'Exact Alarm Permission',
                data['exact_alarm_permission'] ?? false,
              ),
              Divider(height: 1, color: _gold.withValues(alpha: 0.1)),
              _checkItem(
                l.isAr ? 'تجاهل تحسين البطارية' : 'Battery Optimization Ignored',
                data['battery_optimization_ignored'] ?? false,
              ),
              Divider(height: 1, color: _gold.withValues(alpha: 0.1)),
              _checkItem(
                l.isAr ? 'الوصول إلى وضع الصامت' : 'DND / Silent Access',
                data['dnd_access'] ?? false,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (!isReady)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l.isAr ? 'يرجى تفعيل الأذونات لضمان الأذان في الوضع الصامت' : 'Grant permissions to enable Silent Bypass',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (!(data['battery_optimization_ignored'] ?? true))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => provider.requestBatteryOptimization(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.lightBlueAccent),
                              foregroundColor: Colors.lightBlueAccent,
                            ),
                            child: Text(l.isAr ? 'تجاهل تحسين البطارية' : 'Disable Battery Optimization'),
                          ),
                        ),
                      ),
                    if (!(data['dnd_access'] ?? true))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => provider.requestDNDAccess(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orangeAccent),
                              foregroundColor: Colors.orangeAccent,
                            ),
                            child: Text(l.isAr ? 'تفعيل الوصول لوضع الصامت' : 'Grant DND Access'),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => provider.testPrayerNotification(),
                        icon: const Icon(Icons.play_circle_filled_rounded),
                        label: Text(l.isAr ? 'اختبار الأذان (بعد 10 ثوان)' : 'Test Azan (In 10s)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReady ? _gold : _slate,
                          foregroundColor: _bg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _checkItem(String title, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: ok ? Colors.greenAccent : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: ok ? _cream : _slate, fontSize: 14),
            ),
          ),
          if (!ok)
            const Text(
              '!',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
